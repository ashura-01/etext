import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';

class SearchUserScreen extends StatelessWidget {
  SearchUserScreen({super.key});

  final TextEditingController _searchController = TextEditingController();
  final UserController uc = Get.find<UserController>();
  final AuthController auth = Get.find<AuthController>();

  void _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    uc.searchUsers(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _searchUsers,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (uc.searchResults.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  itemCount: uc.searchResults.length,
                  itemBuilder: (_, i) {
                    final user = uc.searchResults[i];
                    final isFriend = auth.appUser.value!.friends.contains(user.uid);

                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: isFriend
                          ? const Text('Connected',
                              style: TextStyle(color: Colors.green))
                          : TextButton(
                              onPressed: () async {
                                await uc.sendFriendRequest(user.uid);
                                Get.snackbar(
                                  'Success',
                                  'Friend request sent',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: const Text('Add Friend'),
                            ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
