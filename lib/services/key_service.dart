import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KeyService extends GetxService {
  final _firestore = FirebaseFirestore.instance;
  final algorithm = X25519(); // key exchange
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SimpleKeyPair? _keyPair;
  SimplePublicKey? _publicKey;

  static const String _privateKeyStorageKey = 'private_key_bytes';

  /// Ensure user has a key pair & upload public key
  Future<void> ensureKeypairExists(String uid) async {
    if (_keyPair == null) {
      // Try loading saved key
      final stored = await _storage.read(key: _privateKeyStorageKey);
      if (stored != null) {
        final bytes = Uint8List.fromList(stored.codeUnits);
        _keyPair = await algorithm.newKeyPairFromSeed(bytes);
        _publicKey = await _keyPair!.extractPublicKey();
      } else {
        // Generate new key if none stored
        _keyPair = await algorithm.newKeyPair();
        _publicKey = await _keyPair!.extractPublicKey();

        // Save seed for later use
        final seed = await _keyPair!.extractPrivateKeyBytes();
        await _storage.write(
          key: _privateKeyStorageKey,
          value: String.fromCharCodes(seed),
        );
      }
    }

    // Upload only public key to Firestore
    await _firestore.collection('users').doc(uid).set({
      'publicKey': _publicKey!.bytes,
    }, SetOptions(merge: true));
  }

  /// Delete local private key and remove public key from Firestore
  Future<void> deleteKeys(String uid) async {
    // Remove local private key
    await _storage.delete(key: _privateKeyStorageKey);
    _keyPair = null;
    _publicKey = null;

    // Remove public key from Firestore
    await _firestore.collection('users').doc(uid).update({
      'publicKey': FieldValue.delete(),
    });
  }

  SimpleKeyPair get keyPair => _keyPair!;
  SimplePublicKey get publicKey => _publicKey!;
}
