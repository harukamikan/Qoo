import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Firestore の `users/{uid}` ドキュメントを読み書きするリポジトリ。
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  static String normalizeFriendCode(String value) => value.trim().toLowerCase();

  static String defaultFriendCode(String uid) {
    final suffix = uid.length <= 6 ? uid : uid.substring(uid.length - 6);
    return 'traveler-${suffix.toLowerCase()}';
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users');

  /// プロフィールを取得する。未登録なら null。
  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await _col.doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;

    final normalizedData = Map<String, dynamic>.from(data);

    final friendCode = (normalizedData['friendCode'] as String?)?.trim();
    if (friendCode == null || friendCode.isEmpty) {
      final generated = defaultFriendCode(uid);
      await _col.doc(uid).set(
        {
          'friendCode': generated,
          'friendCodeLower': normalizeFriendCode(generated),
          'friends': (normalizedData['friends'] as List<dynamic>?)?.cast<String>() ?? const [],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      normalizedData['friendCode'] = generated;
      normalizedData['friendCodeLower'] = normalizeFriendCode(generated);
    }

    return UserProfile.fromMap(uid, normalizedData);
  }

  /// プロフィールを保存する（既存があればマージ更新）。
  Future<void> saveProfile(UserProfile profile) async {
    final friendCode = profile.friendCode.trim().isEmpty
        ? defaultFriendCode(profile.userId)
        : profile.friendCode.trim();
    await _col.doc(profile.userId).set(
      {
        ...profile.toMap(),
        'friendCode': friendCode,
        'friendCodeLower': normalizeFriendCode(friendCode),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// プロフィールが登録済みかどうか。
  Future<bool> hasProfile(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.exists &&
        (snap.data()?['name'] as String?)?.isNotEmpty == true;
  }

  Future<UserProfile?> fetchByFriendCode(String friendCode) async {
    final normalized = normalizeFriendCode(friendCode);
    if (normalized.isEmpty) return null;

    final snap = await _col
        .where('friendCodeLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return UserProfile.fromMap(doc.id, doc.data());
  }

  Future<List<UserProfile>> fetchProfilesByUids(Iterable<String> uids) async {
    final uniqueUids = uids.where((uid) => uid.trim().isNotEmpty).toSet();
    if (uniqueUids.isEmpty) return [];

    final profiles = await Future.wait(uniqueUids.map(fetchProfile));
    return profiles.whereType<UserProfile>().toList();
  }

  Future<void> updateFriendCode(String uid, String friendCode) async {
    final trimmed = friendCode.trim();
    final normalized = normalizeFriendCode(trimmed);
    if (trimmed.isEmpty) {
      throw ArgumentError('friendCode must not be empty');
    }

    final existing = await _col
        .where('friendCodeLower', isEqualTo: normalized)
        .limit(2)
        .get();
    if (existing.docs.any((doc) => doc.id != uid)) {
      throw StateError('そのIDはすでに使われています');
    }

    await _col.doc(uid).set(
      {
        'friendCode': trimmed,
        'friendCodeLower': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
