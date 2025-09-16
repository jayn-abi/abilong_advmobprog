// lib/services/user_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

enum LoginType { firebase, mongodb }

class UserService {
  Map<String, dynamic> data = {};
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // -----------------------
  // Helpers for LoginType
  // -----------------------
  String _loginTypeToString(LoginType t) =>
      t == LoginType.firebase ? 'firebase' : 'mongodb';

  LoginType? _loginTypeFromString(String? s) {
    if (s == null) return null;
    if (s == 'firebase') return LoginType.firebase;
    if (s == 'mongodb') return LoginType.mongodb;
    return null;
  }

  Future<void> setLoginType(LoginType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', _loginTypeToString(type));
  }

  Future<LoginType?> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return _loginTypeFromString(prefs.getString('loginType'));
  }

  Future<String> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<String> _getStoredUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid') ?? '';
  }

  // -----------------------
  // MONGODB (API) Methods
  // -----------------------

  /// Login (MongoDB)
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await post(
      Uri.parse('$host/api/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      // Save login type as mongodb
      await saveUserData(data, loginType: LoginType.mongodb);
      await setLoginType(LoginType.mongodb);
      return data;
    } else {
      throw Exception(
          'Failed to login: ${response.statusCode} - ${response.body}');
    }
  }

  /// Register (MongoDB)
  Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String age,
    required String gender,
    required String contactNumber,
    required String email,
    required String username,
    required String password,
    required String address,
    String type = 'editor',
  }) async {
    final response = await post(
      Uri.parse('$host/api/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'gender': gender,
        'contactNumber': contactNumber,
        'email': email,
        'username': username,
        'password': password,
        'address': address,
        'type': type,
      }),
    );

    if (response.statusCode == 201) {
      data = jsonDecode(response.body);
      // Save login type as mongodb
      await saveUserData(data, loginType: LoginType.mongodb);
      await setLoginType(LoginType.mongodb);
      return data;
    } else {
      throw Exception('Failed to register user: ${response.statusCode}');
    }
  }

  /// Update user (existing)
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final response = await put(
      Uri.parse('$host/api/users/${userData['id']}'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        "firstName": userData['firstName'],
        "lastName": userData['lastName'],
        "age": userData['age'],
        "gender": userData['gender'],
        "contactNumber": userData['contactNumber'],
        "email": userData['email'],
        "username": userData['username'],
        "password": userData['password'],
        "address": userData['address'],
        "isActive": userData['isActive'] ?? true,
        "type": userData['type'] ?? 'viewer',
      }),
    );

    if (response.statusCode == 200) {
      final resp = jsonDecode(response.body);
      // Standardize saving (backend should return { message, user, token })
      await saveUserData(resp, loginType: LoginType.mongodb);
      return resp;
    } else {
      throw Exception(
        'Failed to update user: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Update username (MongoDB-specific)
  Future<Map<String, dynamic>> updateUsernameMongo(
      {required String id, required String username}) async {
    final response = await put(
      Uri.parse('$host/api/users/$id/username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200) {
      final resp = jsonDecode(response.body); // { message, user }
      // keep token
      final token = await _getStoredToken();
      await saveUserData({'user': resp['user'], 'token': token},
          loginType: LoginType.mongodb);
      return resp;
    } else {
      throw Exception(
          'Failed to update username: ${response.statusCode} ${response.body}');
    }
  }

  /// Change password (MongoDB-specific)
    Future<void> changePasswordMongo({
  required String id,
  required String currentPassword,
  required String newPassword,
  String? token,
}) async {
  final uri = Uri.parse('$host/api/users/$id/password');
  final headers = {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  debugPrint('PUT $uri');
  debugPrint('Headers: $headers');
  debugPrint('Payload lengths -> current: ${currentPassword.length}, new: ${newPassword.length}');

  final response = await put(
    uri,
    headers: headers,
    body: jsonEncode({
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    }),
  );

  debugPrint('Response status: ${response.statusCode}');
  debugPrint('Response body: ${response.body}');

  // Try to pull backend's message (if JSON)
  try {
    final body = jsonDecode(response.body);
    final msg = (body is Map && body['message'] != null) ? body['message'] : response.body;
    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to change password (${response.statusCode}): $msg');
    }
  } catch (_) {
    // not JSON — fallback
    if (response.statusCode == 200) return;
    throw Exception('Failed to change password (${response.statusCode}): ${response.body}');
  }
}


  /// Delete user (MongoDB-specific)
  Future<void> deleteUserMongo({required String id}) async {
    final response = await delete(Uri.parse('$host/api/users/$id'));

    if (response.statusCode == 200) {
      // clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return;
    } else {
      throw Exception(
          'Failed to delete user: ${response.statusCode} ${response.body}');
    }
  }


  Future<void> saveUserData(Map<String, dynamic> response,
      {LoginType? loginType}) async {
    final prefs = await SharedPreferences.getInstance();

    final user = response['user'] ?? response;
    final token = response['token'] ?? '';

    // backend returns _id, map to uid in prefs
    await prefs.setString('uid', user['_id']?.toString() ?? user['uid']?.toString() ?? '');
    await prefs.setString('firstName', user['firstName'] ?? '');
    await prefs.setString('lastName', user['lastName'] ?? '');
    await prefs.setString('age', user['age']?.toString() ?? '');
    await prefs.setString('gender', user['gender'] ?? '');
    await prefs.setString('contactNumber', user['contactNumber'] ?? '');
    await prefs.setString('email', user['email'] ?? '');
    await prefs.setString('username', user['username'] ?? '');
    await prefs.setString('address', user['address'] ?? '');
    await prefs.setBool('isActive', user['isActive'] == true);
    await prefs.setString('type', user['type'] ?? '');
    await prefs.setString('token', token);

    if (loginType != null) {
      await prefs.setString('loginType', _loginTypeToString(loginType));
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString('uid') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getString('age') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'contactNumber': prefs.getString('contactNumber') ?? '',
      'email': prefs.getString('email') ?? '',
      'username': prefs.getString('username') ?? '',
      'address': prefs.getString('address') ?? '',
      'isActive': prefs.getBool('isActive') ?? false,
      'type': prefs.getString('type') ?? '',
      'token': prefs.getString('token') ?? '',
      'loginType': prefs.getString('loginType') ?? '',
    };
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token')?.isNotEmpty ?? false;
  }

  /// Unified logout: signs out Firebase (if any) and clears prefs
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // -----------------------
  // FIREBASE AUTH Methods
  // -----------------------
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);

    // Save minimal user info to prefs so profile screen can still read it
    final token = await cred.user!.getIdToken();
    await saveUserData({
      'user': {
        '_id': cred.user!.uid,
        'firstName': cred.user!.displayName ?? '',
        'lastName': '',
        'age': '',
        'gender': '',
        'contactNumber': '',
        'email': cred.user!.email ?? '',
        'username': cred.user!.displayName ?? '',
        'address': '',
        'isActive': true,
        'type': 'firebase',
      },
      'token': token,
    }, loginType: LoginType.firebase);

    await setLoginType(LoginType.firebase);

    return cred;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final cred = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    final token = await cred.user!.getIdToken();
    await saveUserData({
      'user': {
        '_id': cred.user!.uid,
        'firstName': cred.user!.displayName ?? '',
        'lastName': '',
        'age': '',
        'gender': '',
        'contactNumber': '',
        'email': cred.user!.email ?? '',
        'username': cred.user!.displayName ?? '',
        'address': '',
        'isActive': true,
        'type': 'firebase',
      },
      'token': token,
    }, loginType: LoginType.firebase);

    await setLoginType(LoginType.firebase);

    return cred;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Firebase username update
  Future<void> updateUsernameFirebase({required String username}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(username);
      // update prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('firstName', username); // optional mapping
    } else {
      throw Exception('No Firebase current user');
    }
  }

  /// Firebase delete
  Future<void> deleteAccountFirebase({
    required String email,
    required String password,
  }) async {
    if (currentUser == null) throw Exception('No Firebase current user');
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Firebase change password (requires current password reauth)
  Future<void> resetPasswordFromCurrentUser({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (currentUser == null) throw Exception('No Firebase current user');
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }


  Future<void> updateUsernameByType({required String username}) async {
    final loginType = await getLoginType() ??
        (firebaseAuth.currentUser != null ? LoginType.firebase : LoginType.mongodb);

    if (loginType == LoginType.firebase) {
      await updateUsernameFirebase(username: username);
    } else {
      final id = await _getStoredUid();
      await updateUsernameMongo(id: id, username: username);
    }
  }

    Future<void> changePasswordByType({
  required String currentPassword,
  required String newPassword,
}) async {
  final loginType = await getLoginType() ??
      (firebaseAuth.currentUser != null ? LoginType.firebase : LoginType.mongodb);

  if (loginType == LoginType.firebase) {
    final email = firebaseAuth.currentUser?.email;
    if (email == null) throw Exception('No email for Firebase user');
    await resetPasswordFromCurrentUser(
        currentPassword: currentPassword, newPassword: newPassword, email: email);
  } else {
    final id = await _getStoredUid();
    final token = await _getStoredToken();

    if (id.isEmpty) {
      throw Exception('No stored UID found. Are you logged in with MongoDB?');
    }

    // Quick sanity check: Mongo ObjectIds are 24 hex chars
    final isObjectId = RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id);
    if (!isObjectId) {
      throw Exception('Stored UID does not look like a MongoDB ObjectId: $id. '
          'This suggests you are not using the Mongo login session.');
    }

    // Debugging info (no sensitive full-password dump). Show length only.
    debugPrint('Attempting Mongo password change for id=$id currentPasswordLength=${currentPassword.length}');

    await changePasswordMongo(
      id: id,
      currentPassword: currentPassword,
      newPassword: newPassword,
      token: token,
    );
  }
}



  Future<void> deleteAccountByType({
    String? email,
    String? password,
  }) async {
    final loginType = await getLoginType() ??
        (firebaseAuth.currentUser != null ? LoginType.firebase : LoginType.mongodb);

    if (loginType == LoginType.firebase) {
      if (email == null || password == null) {
        throw Exception('Email and password required for Firebase delete');
      }
      await deleteAccountFirebase(email: email, password: password);
    } else {
      final id = await _getStoredUid();
      await deleteUserMongo(id: id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
  try {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  } catch (e) {
    throw Exception('Failed to send reset email: ${e.toString()}');
  }
}

}
