import 'package:etext/controllers/auth_controller.dart';
import 'package:etext/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  void _navigateTo(String routeName) {
    // Close the drawer first
    Get.back();
    // Navigate to the route
    Get.toNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 12, 53),
            ),
            child: Container(
              width: double.infinity,
              alignment: Alignment.bottomLeft,
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),

          // Main Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('My Account'),
                  onTap: () => _navigateTo('/account'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () => _navigateTo('/settings'),
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Chat requests'),
                  onTap: () => _navigateTo('/requests'),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About Us'),
                  onTap: () {
                    Get.back(); // Close drawer
                    Get.snackbar('Info', 'About Us clicked');
                  },
                ),
              ],
            ),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Get.back(); // Close drawer first
              await AuthController.instance.logout();
              Get.offAll(() => LoginScreen());
            },
          ),
        ],
      ),
    );
  }
}
