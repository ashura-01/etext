import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';
import '../utils/constants.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _auth = AuthController.instance;

  // Reactive lists
  final RxList<AppUser> users = <AppUser>[].obs;
  final RxList<AppUser> friendRequests = <AppUser>[].obs;
  final RxList<AppUser> friends = <AppUser>[].obs;
  final RxList<AppUser> searchResults = <AppUser>[].obs;

  /// Update all data when auth changes
  void updateAuth() {
    if (_auth.isLoggedIn) {
      fetchUsers();
      fetchFriendRequests();
      fetchFriends();
    } else {
      users.clear();
      friendRequests.clear();
      friends.clear();
      searchResults.clear();
    }
  }

  /// Fetch all users except current
  Future<void> fetchUsers() async {
    if (_auth.appUser.value == null) return;

    final snap = await _firestore.collection(Collections.users).get();
    users.value = snap.docs
        .map((d) => AppUser.fromMap(d.data()))
        .where((u) => u.uid != _auth.appUser.value!.uid)
        .toList();
  }

  /// Fetch friend requests
  Future<void> fetchFriendRequests() async {
    if (_auth.appUser.value == null) return;

    final doc = await _firestore
        .collection(Collections.users)
        .doc(_auth.appUser.value!.uid)
        .get();

    final data = AppUser.fromMap(doc.data()!);
    final List<AppUser> requests = [];

    for (String uid in data.requests) {
      final reqDoc = await _firestore.collection(Collections.users).doc(uid).get();
      if (reqDoc.exists) requests.add(AppUser.fromMap(reqDoc.data()!));
    }

    friendRequests.value = requests;
  }

  /// Fetch accepted friends
  Future<void> fetchFriends() async {
    if (_auth.appUser.value == null) return;

    final doc = await _firestore
        .collection(Collections.users)
        .doc(_auth.appUser.value!.uid)
        .get();

    final data = AppUser.fromMap(doc.data()!);
    final List<AppUser> friendsList = [];

    for (String uid in data.friends) {
      final friendDoc = await _firestore.collection(Collections.users).doc(uid).get();
      if (friendDoc.exists) friendsList.add(AppUser.fromMap(friendDoc.data()!));
    }

    friends.value = friendsList;
  }

  /// Send a friend request
  Future<void> sendFriendRequest(String targetUid) async {
    await _firestore.collection(Collections.users).doc(targetUid).update({
      'requests': FieldValue.arrayUnion([_auth.appUser.value!.uid])
    });
  }

  /// Accept a friend request
  Future<void> acceptRequest(String fromUid) async {
    final currentUid = _auth.appUser.value!.uid;

    final batch = _firestore.batch();
    final currentRef = _firestore.collection(Collections.users).doc(currentUid);
    final fromRef = _firestore.collection(Collections.users).doc(fromUid);

    batch.update(currentRef, {
      'requests': FieldValue.arrayRemove([fromUid]),
      'friends': FieldValue.arrayUnion([fromUid]),
    });
    batch.update(fromRef, {
      'friends': FieldValue.arrayUnion([currentUid]),
    });

    await batch.commit();

    await fetchFriendRequests();
    await fetchFriends();
  }

  /// Decline a friend request
  Future<void> declineRequest(String fromUid) async {
    final currentUid = _auth.appUser.value!.uid;

    await _firestore.collection(Collections.users).doc(currentUid).update({
      'requests': FieldValue.arrayRemove([fromUid])
    });

    await fetchFriendRequests();
  }

  /// Search users by email
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    final snap = await _firestore
        .collection(Collections.users)
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    searchResults.value = snap.docs
        .map((d) => AppUser.fromMap(d.data()))
        .where((u) => u.uid != _auth.appUser.value!.uid)
        .toList();
  }
}
