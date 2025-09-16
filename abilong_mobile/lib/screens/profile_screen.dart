// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_model.dart'; // your User model

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;
  LoginType? _loginType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    // Try to get loginType from prefs first
    final lt = await _userService.getLoginType();
    LoginType loginType = lt ??
        (_userService.currentUser != null ? LoginType.firebase : LoginType.mongodb);
    _loginType = loginType;

    // If MongoDB, use stored prefs
    if (loginType == LoginType.mongodb) {
      final userData = await _userService.getUserData();
      // Build User from prefs values
      setState(() {
        _user = User(
          uid: userData['uid'] ?? '',
          firstName: userData['firstName'] ?? '',
          lastName: userData['lastName'] ?? '',
          age: userData['age'] ?? '',
          gender: userData['gender'] ?? '',
          contactNumber: userData['contactNumber'] ?? '',
          email: userData['email'] ?? '',
          username: userData['username'] ?? '',
          address: userData['address'] ?? '',
          isActive: userData['isActive'] ?? false,
          type: userData['type'] ?? '',
        );
        _isLoading = false;
      });
    } else {
      // Firebase: build a lightweight User object from Firebase.User and prefs
      final fu = _userService.currentUser;
      final prefsUser = await _userService.getUserData();
      setState(() {
        _user = User(
          uid: fu?.uid ?? prefsUser['uid'] ?? '',
          firstName: fu?.displayName ?? prefsUser['firstName'] ?? '',
          lastName: '',
          age: '',
          gender: '',
          contactNumber: '',
          email: fu?.email ?? prefsUser['email'] ?? '',
          username: fu?.displayName ?? prefsUser['username'] ?? '',
          address: prefsUser['address'] ?? '',
          isActive: true,
          type: 'firebase',
        );
        _isLoading = false;
      });
    }
  }

  // --- UI helpers ---
  Widget _buildInfoTile(String label, String value, IconData icon,
      {bool isStatus = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isStatus
                ? (value == "Active" ? Colors.green[100] : Colors.red[100])
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isStatus
                ? (value == "Active" ? Colors.green[700] : Colors.red[700])
                : const Color(0xFFFBD320),
            size: 24,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF35418d),
          ),
        ),
        subtitle: Text(
          value.isNotEmpty ? value : "-",
          style: TextStyle(
            fontSize: 15,
            color: isStatus
                ? (value == "Active" ? Colors.green[700] : Colors.red[700])
                : const Color(0xFF35418d),
            fontWeight: isStatus ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  // --- Action dialogs and calls ---

  Future<void> _showUpdateUsernameDialog() async {
    final controller = TextEditingController(text: _user?.username ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New username'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _userService.updateUsernameByType(username: result);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username updated')));
        await _loadUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              decoration: const InputDecoration(hintText: 'Current password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newCtrl,
              decoration: const InputDecoration(hintText: 'New password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Change')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.changePasswordByType(
          currentPassword: currentCtrl.text.trim(),
          newPassword: newCtrl.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loginType == LoginType.firebase)
              const Text('This will permanently delete your Firebase account.'),
            if (_loginType == LoginType.mongodb)
              const Text('This will permanently delete your account from the server.'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(hintText: 'Enter password to confirm'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.deleteAccountByType(
          email: _user?.email,
          password: passwordCtrl.text.trim(),
        );
        // Navigate to Login screen after delete
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No user data found', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ]))
              : SafeArea(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFBD320), width: 3),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFF35418d),
                              child: Text(
                                _user!.firstName.isNotEmpty ? _user!.firstName[0].toUpperCase() : "?",
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text("${_user!.firstName} ${_user!.lastName}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF35418d))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                            child: Text(_user!.type.toUpperCase(), style: const TextStyle(color: Color(0xFF35418d), fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ]),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ListView(
                              children: [
                                _buildInfoTile("Email", _user!.email, Icons.email),
                                _buildInfoTile("Username", _user!.username, Icons.person),
                                _buildInfoTile("Contact Number", _user!.contactNumber, Icons.phone),
                                _buildInfoTile("Age", _user!.age, Icons.cake),
                                _buildInfoTile("Gender", _user!.gender, Icons.people),
                                _buildInfoTile("Address", _user!.address, Icons.location_on),
                                _buildInfoTile("Status", _user!.isActive ? "Active" : "Inactive", _user!.isActive ? Icons.check_circle : Icons.cancel, isStatus: true),
                                const SizedBox(height: 20),
                                // ACTIONS
                                const Text("Actions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _showUpdateUsernameDialog,
                                  icon: const Icon(Icons.edit),
                                  label: const Text("Update Username"),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 86, 224, 153)),
                                  
                                ),
                                
                                const SizedBox(height: 12),
                                
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
