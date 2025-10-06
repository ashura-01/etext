import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController authCtrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final isLoading = authCtrl.isLoading.value;
          return Column(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final res = await authCtrl.signup(
                          name: _name.text.trim(),
                          email: _email.text.trim(),
                          password: _password.text.trim(),
                        );
                        if (res != null) {
                          Get.snackbar('Error', res,
                              backgroundColor: Colors.red,
                              colorText: Colors.white);
                        } else {
                          Get.offAllNamed('/'); // go to AuthWrapper
                        }
                      },
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up'),
              ),
              TextButton(
                onPressed: () => Get.offNamed('/login'),
                child: const Text('Already have an account? Login'),
              )
            ],
          );
        }),
      ),
    );
  }
}
