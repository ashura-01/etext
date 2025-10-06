import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/message_model.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authCtrl = Get.find<AuthController>();

  // Map of chatId -> RxList of messages
  var messages = <String, RxList<MessageModel>>{}.obs;

  /// Generate chat ID based on two uids
  String chatId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Listen to chat in real-time
  void listenToChat(String otherUid, {int limit = 50}) {
    final me = authCtrl.appUser.value;
    if (me == null) return;

    final id = chatId(me.uid, otherUid);

    // Initialize RxList if not exists
    messages.putIfAbsent(id, () => <MessageModel>[].obs);

    final ref = _firestore
        .collection('chats')
        .doc(id)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    ref.snapshots().listen((snapshot) {
      final list = snapshot.docs
          .map((doc) => MessageModel.fromDoc(doc))
          .toList()
          .reversed
          .toList();
      messages[id]!.value = list;
    });
  }

  /// Get messages RxList for a chat
  RxList<MessageModel> getChatMessages(String otherUid) {
    final id = chatId(authCtrl.appUser.value!.uid, otherUid);
    return messages.putIfAbsent(id, () => <MessageModel>[].obs);
  }

  /// Send a message
  Future<void> sendMessage({required String toUid, required String text}) async {
    final me = authCtrl.appUser.value;
    if (me == null) return;

    final id = chatId(me.uid, toUid);
    final ref = _firestore.collection('chats').doc(id).collection('messages');

    final msgData = {
      'senderId': me.uid,
      'receiverId': toUid,
      'text': text,
      'timestamp': Timestamp.now(),
    };

    await ref.add(msgData);

    // Optionally update last message in chat document
    await _firestore.collection('chats').doc(id).set({
      'lastMessage': text,
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
