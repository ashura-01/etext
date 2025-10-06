import 'package:etext/widgets/drawyer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final UserController uc = Get.find<UserController>();
  final AuthController auth = Get.find<AuthController>();

  // Controller for search text
  final RxString searchQuery = ''.obs;

  @override
  Widget build(BuildContext context) {
    // Load friend requests and friends when screen opens
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
                  icon: const Icon(Icons.people),
                  onPressed: () => _navigateTo('/requests'),
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
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () async {
          //     await auth.logout();
          //     Get.offAllNamed('/login');
          //   },
          // )
        ],
      ),

      drawer: const CustomDrawer(),

      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Friend List
          Expanded(
            child: Obx(() {
              final friends = uc.friends
                  .where((f) =>
                      f.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                      f.email.toLowerCase().contains(searchQuery.value.toLowerCase()))
                  .toList();

              if (friends.isEmpty) {
                return const Center(child: Text('No friends found'));
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
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/search'),
        label: const Text('Search Users'),
        icon: const Icon(Icons.search),
      ),
    );
  }


    void _navigateTo(String routeName) {
    Get.back();
    Get.toNamed(routeName);
  }
}
