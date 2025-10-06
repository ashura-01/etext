import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;

  const ChatBubble({required this.isMe, required this.text, required this.time, super.key});

  @override
  Widget build(BuildContext context) {
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isMe ? const Color.fromARGB(255, 106, 200, 255) : const Color.fromARGB(255, 159, 205, 207),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(fontSize: 16, color: Colors.black)),
            SizedBox(height: 6),
            Text(time, style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [if (!isMe) SizedBox(width: 8), bubble, if (isMe) SizedBox(width: 8)],
    );
  }
}
