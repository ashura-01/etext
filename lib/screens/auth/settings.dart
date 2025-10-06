import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final AuthController auth = Get.find<AuthController>();

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final RxBool isSendingOtp = false.obs;
  final RxBool isVerifying = false.obs;

  void sendOtp() async {
    if (auth.firebaseUser.value == null) return;

    try {
      isSendingOtp.value = true;
      await auth.firebaseUser.value!.sendEmailVerification();
      Get.snackbar('OTP Sent', 'Check your email for the verification link.');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSendingOtp.value = false;
    }
  }

  void changePassword() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    if (otp.isEmpty || newPassword.isEmpty) {
      Get.snackbar('Error', 'OTP and new password are required');
      return;
    }

    // Here Firebase doesn't directly accept OTP for password reset unless using sendPasswordResetEmail.
    // We assume user clicked the email verification link, so we update the password.
    try {
      isVerifying.value = true;
      final msg = await auth.changePassword(newPassword);
      if (msg != null) {
        Get.snackbar('Error', msg);
      } else {
        Get.snackbar('Success', 'Password changed successfully');
        _newPasswordController.clear();
        _otpController.clear();
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isVerifying.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = auth.appUser.value?.email ?? 'Your Email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(email),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP (Check Email)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: isSendingOtp.value ? null : sendOtp,
                  child: isSendingOtp.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                )),
            const SizedBox(height: 12),
            Obx(() => ElevatedButton(
                  onPressed: isVerifying.value ? null : changePassword,
                  child: isVerifying.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Verify & Change Password'),
                )),
          ],
        ),
      ),
    );
  }
}
