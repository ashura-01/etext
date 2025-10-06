import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/message_model.dart';
import '../controllers/auth_controller.dart';
import '../services/encryption_service.dart';
import '../services/local_db.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authCtrl = Get.find<AuthController>();
  final EncryptionService enc = Get.put(EncryptionService());

  final RxMap<String, RxList<MessageModel>> messages = <String, RxList<MessageModel>>{}.obs;
  final RxMap<String, RxString> lastMessages = <String, RxString>{}.obs;
  final Map<String, StreamSubscription<QuerySnapshot>> _chatSubscriptions = {};

  /// Generate unique chat ID for two users
  String chatId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Load messages from local SQLite
  Future<void> loadLocalMessages(String otherUid) async {
    final me = authCtrl.appUser.value;
    if (me == null) return;

    final chatIdStr = chatId(me.uid, otherUid);
    messages.putIfAbsent(chatIdStr, () => <MessageModel>[].obs);
    lastMessages.putIfAbsent(chatIdStr, () => ''.obs);

    final localList = await LocalDb.getMessages(me.uid, otherUid);
    messages[chatIdStr]!.assignAll(localList);
    if (localList.isNotEmpty) {
      lastMessages[chatIdStr]!.value = localList.last.text;
    }
  }

  /// Listen to Firestore for new updates (only received messages)
  void listenToChat(String otherUid, {int limit = 50}) async {
    final me = authCtrl.appUser.value;
    if (me == null) return;

    final id = chatId(me.uid, otherUid);

    // Cancel previous subscription
    _chatSubscriptions[id]?.cancel();

    // Initialize message list and last message
    messages.putIfAbsent(id, () => <MessageModel>[].obs);
    lastMessages.putIfAbsent(id, () => ''.obs);

    final chatMessages = messages[id]!;
    final lastMsg = lastMessages[id]!;

    // Load local messages first
    final localList = await LocalDb.getMessages(me.uid, otherUid);
    chatMessages.assignAll(localList);
    if (localList.isNotEmpty) {
      lastMsg.value = localList.last.text;
    }

    // Listen to Firestore updates
    final sub = _firestore
        .collection('chats')
        .doc(id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final docId = doc.id;
        final senderId = data['senderId'] ?? '';
        final receiverId = data['receiverId'] ?? '';
        final cipherText = data['text'] ?? '';
        final timestamp = data['timestamp'] ?? Timestamp.now();

        // Skip if message already exists in memory (avoids duplicates)
        final existsInMemory = chatMessages.any((m) => m.docId == docId);
        if (existsInMemory) continue;

        // Only decrypt & insert if it's **received message**
        if (senderId != me.uid) {
          String displayText;
          try {
            displayText = await enc.decrypt(cipherText, senderId);
          } catch (_) {
            displayText = '[Decryption failed]';
          }

          final msg = MessageModel(
            docId: docId,
            senderId: senderId,
            receiverId: receiverId,
            text: displayText,
            timestamp: timestamp,
          );

          chatMessages.add(msg);
          await LocalDb.insertMessage(msg);
        }
      }

      // Sort messages by timestamp
      chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update last message
      if (chatMessages.isNotEmpty) {
        lastMsg.value = chatMessages.last.text;
      }
    });

    _chatSubscriptions[id] = sub;
  }

  RxList<MessageModel> getChatMessages(String otherUid) {
    final id = chatId(authCtrl.appUser.value!.uid, otherUid);
    return messages.putIfAbsent(id, () => <MessageModel>[].obs);
  }

  RxString getLastMessage(String otherUid) {
    final id = chatId(authCtrl.appUser.value!.uid, otherUid);
    return lastMessages.putIfAbsent(id, () => ''.obs);
  }

  /// Send new message
  Future<void> sendMessage({
    required String toUid,
    required String text,
  }) async {
    final me = authCtrl.appUser.value;
    if (me == null) return;

    final id = chatId(me.uid, toUid);
    final ref = _firestore.collection('chats').doc(id).collection('messages');
    final encryptedText = await enc.encrypt(text, toUid);
    final docRef = ref.doc();

    // Store only encrypted text in Firestore
    final msgData = {
      'senderId': me.uid,
      'receiverId': toUid,
      'text': encryptedText,
      'timestamp': Timestamp.now(),
    };

    await docRef.set(msgData);

    // Add plaintext message to memory & local DB immediately
    final msg = MessageModel(
      docId: docRef.id,
      senderId: me.uid,
      receiverId: toUid,
      text: text,
      timestamp: Timestamp.now(),
    );

    messages[id]?.add(msg);
    await LocalDb.insertMessage(msg);

    // Update last message in Firestore
    await _firestore.collection('chats').doc(id).set({
      'lastMessage': encryptedText,
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Delete message
  Future<void> deleteMessage(MessageModel msg) async {
    final me = authCtrl.appUser.value;
    if (me == null || msg.senderId != me.uid) {
      Get.snackbar('Error', 'You can only delete your own messages');
      return;
    }

    try {
      final id = chatId(msg.senderId, msg.receiverId);
      if (msg.docId == null) return;

      await _firestore
          .collection('chats')
          .doc(id)
          .collection('messages')
          .doc(msg.docId)
          .delete();

      await LocalDb.deleteMessage(msg.docId!);

      final chatMessages = messages[id];
      final lastMsg = lastMessages[id];

      if (chatMessages != null && lastMsg != null) {
        chatMessages.removeWhere((m) => m.docId == msg.docId);
        lastMsg.value = chatMessages.isNotEmpty ? chatMessages.last.text : '';
      }

      Get.snackbar('Deleted', 'Message deleted successfully');
    } catch (e) {
      debugPrint('Error deleting message: $e');
      Get.snackbar('Error', 'Could not delete message');
    }
  }

  /// Clear all messages from local DB
Future<void> clearAllLocalMessages() async {
  await LocalDb.clearAllMessages();
  for (final list in messages.values) {
    list.clear();
  }
  for (final last in lastMessages.values) {
    last.value = '';
  }
}

/// Clear all messages from Firebase
Future<void> clearAllFirebaseMessages() async {
  final userId = authCtrl.appUser.value!.uid;
  final chatsSnapshot = await _firestore.collection('chats').get();
  for (final chatDoc in chatsSnapshot.docs) {
    final chatIdStr = chatDoc.id;
    final msgCol = _firestore.collection('chats').doc(chatIdStr).collection('messages');
    final msgs = await msgCol.get();
    for (final msg in msgs.docs) {
      await msg.reference.delete();
    }
    // Reset lastMessage field
    await _firestore.collection('chats').doc(chatIdStr).set({
      'lastMessage': '',
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}


  @override
  void onClose() {
    for (final sub in _chatSubscriptions.values) {
      sub.cancel();
    }
    _chatSubscriptions.clear();
    super.onClose();
  }
}
