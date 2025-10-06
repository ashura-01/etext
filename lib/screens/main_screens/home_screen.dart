import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etext/screens/auth/settings.dart';
import 'package:etext/screens/main_screens/blu_chat_screen.dart';
import 'package:etext/screens/sub_screens/requests_screen.dart';
import 'package:etext/services/local_db.dart';
import 'package:etext/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserController uc = Get.find<UserController>();
  final AuthController auth = Get.find<AuthController>();
  final ChatController chatCtrl = Get.find<ChatController>();

  final RxInt selectedIndex = 0.obs;
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    uc.fetchFriendRequests();
    uc.fetchFriends();
  }

  Future<void> _clearAllChats() async {
    final me = auth.appUser.value;

    if (me == null) return;

    // Clear local DB
    await LocalDb.clearAllMessages();

    // Clear all Firestore messages
    final chatsSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .get();

    for (final chatDoc in chatsSnapshot.docs) {
      final messagesCollection = chatDoc.reference.collection('messages');
      final batch = FirebaseFirestore.instance.batch();

      final messagesSnapshot = await messagesCollection.get();
      for (final msg in messagesSnapshot.docs) {
        batch.delete(msg.reference);
      }

      await batch.commit();
    }

    // Clear in-memory chat lists
    final chatCtrl = Get.find<ChatController>();
    chatCtrl.messages.clear();
    chatCtrl.lastMessages.clear();

    Get.snackbar('Success', 'All chat history cleared');
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: () async {
        await uc.fetchFriends(); // Refetch friends from server
        await uc.fetchFriendRequests(); // Optional: refresh requests too
      },
      child: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),

                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 142, 184, 255),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 20),
          Text("Chats: ", style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(height: 30),
          
          // 🧑‍🤝‍🧑 Friends List
          Expanded(
            child: Obx(() {
              final friends = uc.friends
                  .where(
                    (f) =>
                        f.name.toLowerCase().contains(
                          searchQuery.value.toLowerCase(),
                        ) ||
                        f.email.toLowerCase().contains(
                          searchQuery.value.toLowerCase(),
                        ),
                  )
                  .toList();

              if (friends.isEmpty) {
                return const Center(child: Text('No friends found'));
              }

              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (_, i) {
                  final friend = friends[i];
                  final lastMsg = chatCtrl.getLastMessage(friend.uid);

                  // Start listening to chat for live updates
                  chatCtrl.listenToChat(friend.uid);

                  return Card(
                    color: const Color.fromARGB(255, 20, 24, 32),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                    child: ListTile(
                      
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.getAvatarColor(friend.uid),
                        child: Text(
                          friend.name.isNotEmpty
                              ? friend.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        friend.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Obx(
                        () => Text(
                          lastMsg.value.isEmpty
                              ? 'No messages yet'
                              : lastMsg.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () => Get.toNamed('/chat', arguments: friend),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildChatList();
      case 1:
        return const RequestsScreen();
      case 2:
        return const BluMessenger();
      case 3:
        return SettingsScreen();
      default:
        return _buildChatList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: selectedIndex.value != 2
            ? AppBar(
                title: Text(
                  [
                    'eText',
                    'Requests',
                    'Offline Chat',
                    'Settings',
                  ][selectedIndex.value],
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'My Account':
                          Get.toNamed(
                            '/my-account',
                          ); // replace with your account screen
                          break;
                        case 'Settings':
                          Get.to(() => SettingsScreen());
                          break;
                        case 'Clear History':
                          await _clearAllChats();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'My Account',
                        child: Text('My Account'),
                      ),
                      const PopupMenuItem(
                        value: 'Settings',
                        child: Text('Settings'),
                      ),
                      const PopupMenuItem(
                        value: 'Clear History',
                        child: Text('Clear History'),
                      ),
                    ],
                  ),
                ],
              )
            : null,

        // No AppBar
        body: _buildPage(selectedIndex.value),

        floatingActionButton: selectedIndex.value == 0
            ? FloatingActionButton.extended(
                onPressed: () => Get.toNamed('/search'),
                label: const Text('Search Users'),
                icon: const Icon(Icons.search),
              )
            : null,

        // 🔽 Bottom Navigation Bar
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex.value,
          onTap: (i) => selectedIndex.value = i,
          selectedItemColor: const Color.fromARGB(255, 142, 184, 255),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_red_eye),
              label: 'War Mode',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
