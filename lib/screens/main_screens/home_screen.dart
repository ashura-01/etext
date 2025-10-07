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

  // Keep track of which friends already have listeners
  final RxSet<String> _listenedFriends = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    fetchDataAndListen();
  }

  Future<void> fetchDataAndListen() async {
    await uc.fetchFriendRequests();
    await uc.fetchFriends();

    // Start chat listeners only once
    for (final friend in uc.friends) {
      if (!_listenedFriends.contains(friend.uid)) {
        chatCtrl.listenToChat(friend.uid);
        _listenedFriends.add(friend.uid);
      }
    }
  }

  Future<void> _clearAllChats() async {
    final me = auth.appUser.value;
    if (me == null) return;

    // Clear local DB
    await LocalDb.clearAllMessages();

    // Clear Firestore messages
    final chatsSnapshot = await FirebaseFirestore.instance.collection('chats').get();
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
    chatCtrl.messages.clear();
    chatCtrl.lastMessages.clear();

    Get.snackbar('Success', 'All chat history cleared');
  }

  Future<void> _deleteFriend(String friendUid) async {
    final me = auth.appUser.value;
    if (me == null) return;

    final batch = FirebaseFirestore.instance.batch();

    final myRef = FirebaseFirestore.instance.collection('users').doc(me.uid);
    final friendRef = FirebaseFirestore.instance.collection('users').doc(friendUid);

    batch.update(myRef, {
      'friends': FieldValue.arrayRemove([friendUid]),
    });
    batch.update(friendRef, {
      'friends': FieldValue.arrayRemove([me.uid]),
    });

    await batch.commit();

    await uc.fetchFriends();
    Get.snackbar('Removed', 'Friend deleted successfully');
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: () async {
        await uc.fetchFriends();
        await uc.fetchFriendRequests();

        // Start listeners for any new friends
        for (final friend in uc.friends) {
          if (!_listenedFriends.contains(friend.uid)) {
            chatCtrl.listenToChat(friend.uid);
            _listenedFriends.add(friend.uid);
          }
        }
      },
      child: Obx(() {
        // Sort friends by last message timestamp
        final sortedFriends = [...uc.friends];
        sortedFriends.sort((a, b) {
          final aLast = chatCtrl.getLastMessage(a.uid).value;
          final bLast = chatCtrl.getLastMessage(b.uid).value;
          // Put non-empty last message first
          if (aLast.isEmpty && bLast.isNotEmpty) return 1;
          if (bLast.isEmpty && aLast.isNotEmpty) return -1;
          return 0;
        });

        final filteredFriends = sortedFriends
            .where((f) =>
                f.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                f.email.toLowerCase().contains(searchQuery.value.toLowerCase()))
            .toList();

        return ListView(
          padding: const EdgeInsets.only(top: 10),
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
                    borderRadius: BorderRadius.circular(30),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 142, 184, 255),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (filteredFriends.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Text(
                    'No friends yet.\nPull down to refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ...filteredFriends.map((friend) {
                final lastMsg = chatCtrl.getLastMessage(friend.uid);

                return GestureDetector(
                  onLongPress: () async {
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Delete Friend'),
                        content: Text('Are you sure you want to remove ${friend.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _deleteFriend(friend.uid);
                    }
                  },
                  child: Card(
                    color: const Color.fromARGB(255, 20, 24, 32),
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.getAvatarColor(friend.uid),
                        child: Text(
                          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        friend.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Obx(() => Text(
                            lastMsg.value.isEmpty ? 'No messages yet' : lastMsg.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                      onTap: () => Get.toNamed('/chat', arguments: friend),
                    ),
                  ),
                );
              }),
          ],
        );
      }),
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
    return Obx(() => Scaffold(
          appBar: selectedIndex.value != 2
              ? AppBar(
                  title: Text(
                    ['CipherChat', 'Requests', 'Offline Chat', 'Settings']
                        [selectedIndex.value],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 212, 228, 255),
                    ),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'My Account':
                            Get.toNamed('/account');
                            break;
                          case 'Settings':
                            Get.to(() => SettingsScreen());
                            break;
                          case 'Clear History':
                            await _clearAllChats();
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'My Account',
                          child: Text('My Account'),
                        ),
                        PopupMenuItem(
                          value: 'Settings',
                          child: Text('Settings'),
                        ),
                        PopupMenuItem(
                          value: 'Clear History',
                          child: Text('Clear History'),
                        ),
                      ],
                    ),
                  ],
                )
              : null,
          body: _buildPage(selectedIndex.value),
          floatingActionButton: selectedIndex.value == 0
              ? FloatingActionButton(
                  onPressed: () => Get.toNamed('/search'),
                  child: const Icon(Icons.post_add_rounded, size: 30),
                )
              : null,
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
        ));
  }
}
