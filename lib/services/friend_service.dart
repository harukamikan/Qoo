import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friend_request.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'user_repository.dart';

class FriendService {
  FriendService._();

  static final FriendService instance = FriendService._();

  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference<Map<String, dynamic>> _requests =
      FirebaseFirestore.instance.collection('friend_requests');

  String normalizeFriendCode(String value) =>
      UserRepository.normalizeFriendCode(value);

  Future<UserProfile?> findByFriendCode(String friendCode) {
    return UserRepository.instance.fetchByFriendCode(friendCode);
  }

  Future<List<UserProfile>> fetchFriendProfiles(String uid) async {
    final profile = await UserRepository.instance.fetchProfile(uid);
    if (profile == null || profile.friends.isEmpty) return [];
    return UserRepository.instance.fetchProfilesByUids(profile.friends);
  }

  Future<List<FriendRequest>> fetchIncomingRequests(String uid) async {
    final snap = await _requests
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequest.pending)
        .get();
    return snap.docs
        .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateFriendCode(String uid, String friendCode) async {
    await UserRepository.instance.updateFriendCode(uid, friendCode);
  }

  Future<void> sendFriendRequest({
    required String fromUid,
    required String friendCode,
  }) async {
    final sender = await UserRepository.instance.fetchProfile(fromUid);
    if (sender == null) {
      throw StateError('プロフィールが見つかりません');
    }

    final target = await findByFriendCode(friendCode);
    if (target == null) {
      throw StateError('そのIDのユーザーが見つかりません');
    }
    if (target.userId == fromUid) {
      throw StateError('自分自身には申請できません');
    }
    if (sender.friends.contains(target.userId)) {
      throw StateError('すでに友達です');
    }

    final requestId = _requestId(fromUid, target.userId);
    await _requests.doc(requestId).set(
      FriendRequest(
        id: requestId,
        fromUid: fromUid,
        fromFriendCode: sender.friendCode,
        fromName: sender.name,
        toUid: target.userId,
        toFriendCode: target.friendCode,
        status: FriendRequest.pending,
        createdAt: DateTime.now(),
      ).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> acceptFriendRequest(FriendRequest request) async {
    final batch = FirebaseFirestore.instance.batch();
    final currentUser = _users.doc(request.toUid);
    final otherUser = _users.doc(request.fromUid);
    batch.set(
      currentUser,
      {
        'friends': FieldValue.arrayUnion([request.fromUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      otherUser,
      {
        'friends': FieldValue.arrayUnion([request.toUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _requests.doc(request.id),
      {
        'status': FriendRequest.accepted,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> declineFriendRequest(FriendRequest request) async {
    await _requests.doc(request.id).delete();
  }

  Future<void> deleteFriend({
    required String uid,
    required String friendUid,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      _users.doc(uid),
      {
        'friends': FieldValue.arrayRemove([friendUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _users.doc(friendUid),
      {
        'friends': FieldValue.arrayRemove([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    await _requests.doc(_requestId(uid, friendUid)).delete().catchError((_) {});
    await _requests.doc(_requestId(friendUid, uid)).delete().catchError((_) {});
  }

  String _requestId(String fromUid, String toUid) => '${fromUid}__${toUid}';

  String currentUserId() => AuthService.instance.uid ?? '';
}