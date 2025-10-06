import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/key_service.dart';
import '../utils/constants.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive user
  Rxn<User> firebaseUser = Rxn<User>();
  Rxn<AppUser> appUser = Rxn<AppUser>();

  // Loading indicator for async actions
  RxBool isLoading = false.obs;

  final KeyService keyService = Get.put(KeyService());

  @override
  void onInit() {
    super.onInit();
    firebaseUser.value = _auth.currentUser;

    // Listen to auth state changes
    _auth.authStateChanges().listen((user) async {
      firebaseUser.value = user;
      if (user != null) {
        await _loadAppUser(user.uid);
        await keyService.ensureKeypairExists(user.uid); // ✅ Ensure keys exist
      } else {
        appUser.value = null;
      }
    });
  }

  bool get isLoggedIn => firebaseUser.value != null;

  // Load user data from Firestore
  Future<void> _loadAppUser(String uid) async {
    final doc = await _firestore.collection(Collections.users).doc(uid).get();
    if (doc.exists) {
      appUser.value = AppUser.fromMap(doc.data()!);
    } else {
      final user = _auth.currentUser!;
      appUser.value = AppUser(
        uid: user.uid,
        name: user.displayName ?? user.email!.split('@')[0],
        email: user.email ?? '',
        createdAt: Timestamp.now(),
      );
      await _firestore.collection(Collections.users).doc(user.uid).set(appUser.value!.toMap());
    }
  }

  /// Refresh user data manually
  Future<void> refreshUserData() async {
    if (firebaseUser.value != null) {
      await _loadAppUser(firebaseUser.value!.uid);
    }
  }

  /// Signup with email & password + send email verification
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await cred.user!.updateDisplayName(name);

      // Send email verification
      await cred.user!.sendEmailVerification();

      // Save user in Firestore
      final newUser = AppUser(
        uid: cred.user!.uid,
        name: name,
        email: email,
        createdAt: Timestamp.now(),
      );
      await _firestore.collection(Collections.users).doc(newUser.uid).set(newUser.toMap());

      appUser.value = newUser;
      firebaseUser.value = cred.user;

      // ✅ Generate & upload keypair for E2EE
      await keyService.ensureKeypairExists(cred.user!.uid);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with email & password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Check if email verified
      if (!cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
        return "Email not verified. Verification link sent!";
      }

      firebaseUser.value = cred.user;
      await _loadAppUser(cred.user!.uid);

      // ✅ Ensure keypair exists
      await keyService.ensureKeypairExists(cred.user!.uid);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Send password reset email
  Future<String?> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Change password (requires re-login)
  Future<String?> changePassword(String newPassword) async {
    try {
      if (firebaseUser.value == null) return "User not logged in";
      isLoading.value = true;
      await firebaseUser.value!.updatePassword(newPassword);
      await firebaseUser.value!.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    firebaseUser.value = null;
    appUser.value = null;
  }
}
