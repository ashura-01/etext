import 'dart:async';
import 'package:etext/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // since you’re using GetX

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final authController = Get.find<AuthController>();
  @override
  void initState() {
    super.initState();

    // Wait 2 seconds then go to login or home
    Timer(const Duration(seconds: 2), () {
      // Example: check login state using GetX or shared prefs
      bool loggedIn =
          authController.isLoggedIn; // replace with your actual logic
      if (loggedIn) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // or your theme color
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // smooth rounded corners
          child: Image.asset(
            'assets/logo.png',
            height: 300,
            width: 300,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high, // scale without stretching
          ),
        ),
      ),
    );
  }
}
