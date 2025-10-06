import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final AuthController auth = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();

  final RxBool isSending = false.obs;

  void sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Error', 'Please enter your email.');
      return;
    }

    try {
      isSending.value = true;
      await auth.sendPasswordReset(email);
      Get.snackbar(
        'Email Sent',
        'Check your inbox to reset your password.',
        snackPosition: SnackPosition.BOTTOM,
        
      );
      _emailController.clear();
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-fill email if user is logged in
    _emailController.text = auth.appUser.value?.email ?? '';

    return Scaffold(
      appBar: AppBar(foregroundColor: Colors.white,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(auth.appUser.value?.email ?? 'Your Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Enter email for password reset',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: isSending.value ? null : sendPasswordReset,
                  child: isSending.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Send Password Reset Email'),
                )),
          ],
        ),
      ),
    );
  }
}
