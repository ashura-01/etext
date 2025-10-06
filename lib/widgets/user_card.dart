import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;

  const UserCard({required this.user, this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(user.name.isNotEmpty ? user.name[0] : '?')),
      title: Text(user.name),
      subtitle: Text(user.email),
      trailing: Icon(Icons.chevron_right),
    );
  }
}
