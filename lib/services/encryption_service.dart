import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:get/get.dart';
import 'key_service.dart';

class EncryptionService extends GetxService {
  final algorithm = X25519();
  final aes = AesGcm.with256bits();
  final KeyService keyService = Get.find<KeyService>();
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  /// Get user public key from Firestore
  Future<SimplePublicKey> getUserPublicKey(String uid) async {
    final doc = await _fire.collection('users').doc(uid).get();
    if (!doc.exists || doc.data()?['publicKey'] == null) {
      throw Exception('User public key not found.');
    }
    final bytes = Uint8List.fromList(List<int>.from(doc['publicKey']));
    return SimplePublicKey(bytes, type: KeyPairType.x25519);
  }

  /// Generate shared secret using local private key + remote public key
  Future<SecretKey> _sharedSecret(SimplePublicKey remotePublicKey) async {
    return algorithm.sharedSecretKey(
      keyPair: keyService.keyPair,       // local private key
      remotePublicKey: remotePublicKey,  // remote public key
    );
  }

  /// Encrypt plaintext to send to receiver
  Future<String> encrypt(String plainText, String receiverUid) async {
    final receiverPub = await getUserPublicKey(receiverUid);
    final secret = await _sharedSecret(receiverPub);

    final nonce = aes.newNonce();
    final box = await aes.encrypt(
      utf8.encode(plainText),
      secretKey: secret,
      nonce: nonce,
    );

    return jsonEncode({
      'nonce': base64Encode(box.nonce),
      'cipher': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  /// Decrypt ciphertext received from sender
  Future<String> decrypt(String cipherJson, String senderUid) async {
    final data = jsonDecode(cipherJson);

    final nonce = base64Decode(data['nonce']);
    final cipher = base64Decode(data['cipher']);
    final mac = Mac(base64Decode(data['mac']));
    final box = SecretBox(cipher, nonce: nonce, mac: mac);

    // Get sender's public key
    final senderPub = await getUserPublicKey(senderUid);
    final secret = await _sharedSecret(senderPub);

    try {
      final clear = await aes.decrypt(box, secretKey: secret);
      return utf8.decode(clear);
    } catch (e) {
      print('Decryption failed: $e');
      return '[Decryption failed]';
    }
  }
}
