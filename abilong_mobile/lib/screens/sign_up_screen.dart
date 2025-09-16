import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();


  bool _isObscure = true;
  bool _isLoadingMongoDB = false;
  bool _isLoadingFirebase = false;
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Handles registration with the MongoDB backend.
  Future<void> _handleMongoDBSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingMongoDB = true);
      try {
        final response = await _userService.registerUser(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          age: _ageController.text,
          gender: _genderController.text,
          contactNumber: _contactController.text,
          email: _emailController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          address: _addressController.text,
        );

        // Your service saves the token from the MongoDB response
        if (response['token'] != null) {
          if (!mounted) return;
          _showSnackBar("Registration successful!", isError: false);
          
          Navigator.pushReplacementNamed(context, '/splash');
        }
      } catch (e) {
        if (!mounted) return;
        _showSnackBar("Sign up failed: ${e.toString()}", isError: true);
      } finally {
        if (mounted) {
          setState(() => _isLoadingMongoDB = false);
        }
      }
    }
  }

  /// Handles registration with the Firebase backend.
  Future<void> _handleFirebaseSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingFirebase = true);
      try {
        await _userService.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;
        _showSnackBar("Firebase registration successful!", isError: false);

        Navigator.pushReplacementNamed(context, '/splash');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        _showSnackBar("Firebase sign up failed: ${e.message}", isError: true);
      } catch (e) {
        if (!mounted) return;
        _showSnackBar("An unknown error occurred: ${e.toString()}", isError: true);
      } finally {
        if (mounted) {
          setState(() => _isLoadingFirebase = false);
        }
      }
    }
  }

  /// Reusable function to show a snackbar.
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Reusable text field builder with icons
  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool isPassword = false,
        TextInputType keyboard = TextInputType.text,
        IconData? icon,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        keyboardType: keyboard,
        validator: (value) =>
        value == null || value.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isObscure ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _isObscure = !_isObscure;
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: ScreenUtil().setHeight(120),
                    child: Image.asset(
                      'assets/images/NU_Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    "Registration",
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF35418d)
                    ),
                  ),
                  SizedBox(height: 30.h),
                  _buildTextField("First Name", _firstNameController,
                      icon: Icons.person),
                  _buildTextField("Last Name", _lastNameController,
                      icon: Icons.person_outline),
                  _buildTextField("Age", _ageController,
                      keyboard: TextInputType.number, icon: Icons.cake),
                  _buildTextField("Gender", _genderController, icon: Icons.wc),
                  _buildTextField("Contact Number", _contactController,
                      keyboard: TextInputType.phone, icon: Icons.phone),
                  _buildTextField("Email", _emailController,
                      keyboard: TextInputType.emailAddress, icon: Icons.email),
                  _buildTextField("Username", _usernameController,
                      icon: Icons.account_circle),
                  _buildTextField("Password", _passwordController,
                      isPassword: true, icon: Icons.lock),
                  _buildTextField("Address", _addressController,
                      icon: Icons.home),
                  SizedBox(height: 24.h),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Choose Sign Up Method "),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: _isLoadingMongoDB ? null : _handleMongoDBSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0db300),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 90),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingMongoDB
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : const Text(
                            "Sign Up With MongoDB",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _isLoadingFirebase ? null : _handleFirebaseSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfaae00),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingFirebase
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : const Text(
                            "Sign Up With Firebase",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text("Already have an account? Log in"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}