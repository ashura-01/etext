import 'package:etext/models/message_model.dart';
import 'package:flutter/material.dart';
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
              child: Text(widget.otherUser.name.isNotEmpty
                  ? widget.otherUser.name[0]
                  : '?'),
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
              final messagesList = chatCtrl.messages[chatId] ?? <MessageModel>[].obs;

              if (messagesList.isEmpty) {
                return const Center(child: Text("No messages yet"));
              }

              // Auto scroll to bottom when new message arrives
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollController,
                reverse: false,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                itemCount: messagesList.length,
                itemBuilder: (context, index) {
                  final msg = messagesList[index];
                  final isMe = msg.senderId == me.uid;
                  return ChatBubble(
                    isMe: isMe,
                    text: msg.text,
                    time: DateFormat('hh:mm a').format(msg.timestamp.toDate()),
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
                  fillColor: Colors.grey[200],
                  filled: true,
                ),
                onSubmitted: (_) => _send(chatCtrl),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
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
}
