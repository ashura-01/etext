import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message_model.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'chat.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            docId TEXT PRIMARY KEY,
            senderId TEXT,
            receiverId TEXT,
            text TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<void> insertMessage(MessageModel msg) async {
    final db = await getDb();
    await db.insert(
      'messages',
      {
        'docId': msg.docId,
        'senderId': msg.senderId,
        'receiverId': msg.receiverId,
        'text': msg.text,
        'timestamp': msg.timestamp.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // ignore duplicates
    );
  }

  static Future<List<MessageModel>> getMessages(
      String myUid, String otherUid) async {
    final db = await getDb();
    final result = await db.query(
      'messages',
      where:
          '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [myUid, otherUid, otherUid, myUid],
      orderBy: 'timestamp ASC',
    );

    return result
        .map(
          (e) => MessageModel(
            docId: e['docId'] as String,
            senderId: e['senderId'] as String,
            receiverId: e['receiverId'] as String,
            text: e['text'] as String,
            timestamp:
                Timestamp.fromMillisecondsSinceEpoch(e['timestamp'] as int),
          ),
        )
        .toList();
  }

  static Future<void> deleteMessage(String docId) async {
    final db = await getDb();
    await db.delete('messages', where: 'docId = ?', whereArgs: [docId]);
  }

  static Future<void> clearChat(String myUid, String otherUid) async {
    final db = await getDb();
    await db.delete(
      'messages',
      where:
          '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)',
      whereArgs: [myUid, otherUid, otherUid, myUid],
    );
  }


 // LocalDb.dart
static Future<MessageModel?> getMessageByDocId(String docId) async {
  final db = await getDb();
  final result = await db.query(
    'messages',
    where: 'docId = ?',
    whereArgs: [docId],
  );
  if (result.isEmpty) return null;

  final e = result.first;
  return MessageModel(
    docId: e['docId'] as String?,
    senderId: e['senderId'] as String,
    receiverId: e['receiverId'] as String,
    text: e['text'] as String,
    timestamp: Timestamp.fromMillisecondsSinceEpoch(e['timestamp'] as int),
  );
}
// Delete all messages from local DB
static Future<void> clearAllMessages() async {
  final db = await getDb();
  await db.delete('messages'); // Deletes every row
}

}
