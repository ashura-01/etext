import 'package:etext/widgets/drawyer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final UserController uc = Get.find<UserController>();
  final AuthController auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    
    uc.fetchFriendRequests();
    uc.fetchFriends();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          Obx(() {
            final requestCount = uc.friendRequests.length;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                if (requestCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$requestCount',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Get.offAllNamed('/login');
            },
          )
        ],
      ),

      drawer: CustomDrawer(),

      body: Obx(() {
        final friends = uc.friends;
        if (friends.isEmpty) {
          return const Center(child: Text('No friends connected yet'));
        }
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (_, i) {
            final friend = friends[i];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(friend.name),
              subtitle: Text(friend.email),
              onTap: () => Get.toNamed('/chat', arguments: friend),
            );
          },
        );
      }),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/search'),
        label: const Text('Search Users'),
        icon: const Icon(Icons.search),
      ),
    );
  }
}
