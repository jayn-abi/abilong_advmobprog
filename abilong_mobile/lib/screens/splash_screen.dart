import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

   
    Timer(
      const Duration(seconds: 3),
      () => Navigator.popAndPushNamed(context, '/home'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SizedBox(
              height: ScreenUtil().setHeight(120),
              child: Image.asset(
                'assets/images/NU_Logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // Loader
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
