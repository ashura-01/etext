import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final Timestamp createdAt;
  final List<String> friends;
  final List<String> requests;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.friends = const [],
    this.requests = const [],
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      friends: List<String>.from(map['friends'] ?? []),
      requests: List<String>.from(map['requests'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'friends': friends,
      'requests': requests,
    };
  }
}