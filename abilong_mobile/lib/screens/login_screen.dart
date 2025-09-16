import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isObscure = true;

  bool _isLoadingMongoDB = false;
  bool _isLoadingFirebase = false;
// Combined loading state


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // New function to handle MongoDB login
  Future<void> _handleMongoDBLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingMongoDB = true);
      try {
        final response = await _userService.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // MongoDB backend returns a token, which your service saves.
        if (response['token'] != null) {
          if (!mounted) return;
          _showSnackBar('Login successful! Redirecting...', isError: false);
          
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacementNamed(context, '/splash');
          });
        }
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Login failed: ${e.toString()}', isError: true);
      } finally {
        if (mounted) setState(() => _isLoadingMongoDB = false);
      }
    }
  }

  // New function to handle Firebase login
  Future<void> _handleFirebaseLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingFirebase = true);
      try {
        await _userService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        _showSnackBar('Firebase login successful! Redirecting...', isError: false);

        Future.delayed(const Duration(seconds: 1), () {
          // Firebase auth state changes will handle the navigation, but this
          // ensures a clean visual transition.
          Navigator.pushReplacementNamed(context, '/splash');
        });
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        _showSnackBar('Firebase login failed: ${e.message}', isError: true);
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('An unknown error occurred: ${e.toString()}', isError: true);
      } finally {
        if (mounted) setState(() => _isLoadingFirebase = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 120.h,
                    child: Image.asset(
                      'assets/images/NU_Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 0),
                  // const Text(
                  //   'Login to your account',
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(color: Colors.grey),
                  // ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _isObscure = !_isObscure);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Choose Authentication Method',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black),
                    
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoadingMongoDB ? null : _handleMongoDBLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0db300),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingMongoDB
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text(
                            'Log In With MongoDB',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoadingFirebase ? null : _handleFirebaseLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfaae00),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingFirebase
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Text(
                            'Log In With Firebase',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // The `forgot password` feature is not implemented,
                          // but this navigates to the signup screen. You may
                          // want to change this later.
                          Navigator.pushReplacementNamed(context, '/resetPassword');
                        },
                        child: const Text(
                          "Forgot Password? Reset Here",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFfaae00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF35418d),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}