import 'package:etext/models/message_model.dart';
import 'package:etext/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final AppUser otherUser;
  const ChatScreen({required this.otherUser, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final chatCtrl = Get.find<ChatController>();
    chatCtrl.listenToChat(widget.otherUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final chatCtrl = Get.find<ChatController>();
    final me = authCtrl.appUser.value!;
    final chatId = chatCtrl.chatId(me.uid, widget.otherUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.getAvatarColor(widget.otherUser.uid),
              child: Text(
                widget.otherUser.name.isNotEmpty
                    ? widget.otherUser.name[0].toUpperCase()
                    : '?',

                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUser.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messagesList =
                  chatCtrl.messages[chatId] ?? <MessageModel>[].obs;

              if (messagesList.isEmpty) {
                return const Center(child: Text("No messages yet"));
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                reverse: false,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                itemCount: messagesList.length,
                itemBuilder: (context, index) {
                  final msg = messagesList[index];
                  final isMe = msg.senderId == me.uid;

                  return GestureDetector(
                    onLongPress: () => _showMessageOptions(msg, chatCtrl, isMe),
                    child: ChatBubble(
                      isMe: isMe,
                      text: msg.text,
                      time: DateFormat(
                        'hh:mm a',
                      ).format(msg.timestamp.toDate()),
                    ),
                  );
                },
              );
            }),
          ),
          _buildInputArea(chatCtrl, me.uid),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatController chatCtrl, String myUid) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Type a message",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    // borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 142, 184, 255),
                    ), // change this to any color
                  ),
                  fillColor: const Color.fromARGB(255, 55, 72, 78),
                  filled: true,
                ),

                onSubmitted: (_) => _send(chatCtrl),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 26,
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                onPressed: () => _send(chatCtrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send(ChatController chatCtrl) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    chatCtrl.sendMessage(toUid: widget.otherUser.uid, text: text);
    _textController.clear();
  }

  void _showMessageOptions(
    MessageModel msg,
    ChatController chatCtrl,
    bool isMe,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Options'),
          content: const Text('Choose an action'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.text));
                Get.snackbar('Copied', 'Message copied to clipboard');
              },
              child: const Text('Copy'),
            ),
            if (isMe)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await chatCtrl.deleteMessage(msg);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
