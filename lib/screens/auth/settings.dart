import 'package:etext/widgets/pregress_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final AuthController auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        // title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Email info
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(auth.appUser.value?.email ?? 'Your Email'),
            ),
            const SizedBox(height: 20),

            // Change Password Card/Button
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Get.to(() => ChangePasswordScreen());
                },
              ),
            ),
            const SizedBox(height: 10),

            // Delete Account Card/Button
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.red,
                ),
                onTap: () {
                  Get.to(() => DeleteAccountScreen());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ Change Password Screen ------------------
class ChangePasswordScreen extends StatelessWidget {
  ChangePasswordScreen({super.key});

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
    _emailController.text = auth.appUser.value?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Change Password'),
      foregroundColor: Color.fromARGB(255, 212, 228, 255),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Enter email for password reset',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ Delete Account Screen ------------------
class DeleteAccountScreen extends StatelessWidget {
  DeleteAccountScreen({super.key});

  final AuthController auth = Get.find<AuthController>();

  void deleteAccount() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete your account? This action is irreversible. A link will be sent to your email for verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      Get.snackbar(
        'Deleting',
        'Please wait...',
        snackPosition: SnackPosition.BOTTOM,
      );
      await auth.deleteAccount();
      Get.snackbar(
        'Deleted',
        'Account deletion initiated. Check your email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Long press the button until the progress is full',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ProgressButton(
              size: 120,
              strokeWidth: 6,
              color: Colors.red,
              onComplete: deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
