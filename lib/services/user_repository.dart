import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Firestore の `users/{uid}` ドキュメントを読み書きするリポジトリ。
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users');

  /// プロフィールを取得する。未登録なら null。
  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await _col.doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return UserProfile.fromMap(uid, data);
  }

  /// プロフィールを保存する（既存があればマージ更新）。
  Future<void> saveProfile(UserProfile profile) async {
    await _col.doc(profile.userId).set(
      {
        ...profile.toMap(),
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
}
