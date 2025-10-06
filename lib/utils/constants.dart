import 'package:flutter/material.dart';

class Collections {
  static const users = 'users';
  static const chats = 'chats';
  static const messages = 'messages';
}

class AppColors {
  static List<Color> avatarColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
    Colors.deepOrange,
  ];

 static Color getAvatarColor(String userId) {
    // Simple hash based on uid characters
    int hash = 0;
    for (int i = 0; i < userId.length; i++) {
      hash += userId.codeUnitAt(i);
    }

    return avatarColors[hash % avatarColors.length];
  }
}
