import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../auth/settings.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController authCtrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  20,
                ), // smooth rounded corners
                child: Image.asset(
                  'assets/logo.png',
                  height: 300,
                  width: 300,
                  fit: BoxFit.contain, 
                  filterQuality: FilterQuality.high// scale without stretching
                ),
                
              ),
              Text("CipherChat",style: TextStyle(fontSize: 30, color: const Color.fromARGB(255, 169, 238, 243)),),
              const SizedBox(height: 32),

              // Email Field
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(

                  onPressed: () => Get.to(() => SettingsScreen()),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(decoration: TextDecoration.underline, color: Color.fromARGB(255, 173, 138, 255)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button
              Obx(() {
                final isLoading = authCtrl.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final res = await authCtrl.login(
                              email: _email.text.trim(),
                              password: _password.text.trim(),
                            );
                            if (res != null) {
                              Get.snackbar(
                                'Error',
                                res,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            } else {
                              Get.offAllNamed('/'); // go to home/auth wrapper
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login', style: TextStyle(fontSize: 18)),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Sign Up Link
              RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign up',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 151, 208, 255),
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Get.toNamed('/signup');
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
