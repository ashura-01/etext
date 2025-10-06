import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController authCtrl = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final isLoading = authCtrl.isLoading.value;
          return Column(
            children: [
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
                        final res = await authCtrl.login(
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
                    : const Text('Login'),
              ),
              TextButton(
                onPressed: () => Get.offNamed('/signup'),
                child: const Text("Don't have an account? Sign up"),
              )
            ],
          );
        }),
      ),
    );
  }
}
