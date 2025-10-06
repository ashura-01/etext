import 'package:etext/models/user_model.dart';
import 'package:etext/screens/auth/my_account_screen.dart';
import 'package:etext/screens/auth/settings.dart';
import 'package:etext/screens/sub_screens/chat_screen.dart';
import 'package:etext/screens/sub_screens/requests_screen.dart';
import 'package:etext/screens/sub_screens/search_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'controllers/auth_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/chat_controller.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/main_screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize controllers
  Get.put(AuthController());
  Get.put(UserController());
  Get.put(ChatController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AuthWrapper()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(name: '/home', page: () => HomeScreen()),
        // ChatScreen requires `otherUser` parameter, use binding
        GetPage(
          name: '/chat',
          page: () {
            final args = Get.arguments;
            if (args is AppUser) {
              return ChatScreen(otherUser: args);
            } else {
              return const Scaffold(
                body: Center(
                  child: Text('No user provided for chat'),
                ),
              );
            }
          },
        ),
        GetPage(name: '/search', page: () =>  SearchUserScreen()),
        GetPage(name: '/account', page: () =>  MyAccountScreen()),
        GetPage(name: '/settings', page: () =>  SettingsScreen()),
        GetPage(name: '/requests', page: () =>  RequestsScreen()),
        
      ],
    );
  }
}

// ----------------------------------
// AuthWrapper decides which screen to show
// ----------------------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      // Loading spinner while appUser is being fetched
      if (authController.isLoggedIn && authController.appUser.value == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Show login if not logged in
      if (!authController.isLoggedIn) {
        return LoginScreen();
      }

      // Show home if logged in
      return HomeScreen();
    });
  }
}
