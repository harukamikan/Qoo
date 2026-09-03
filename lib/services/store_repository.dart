import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/store.dart';

/// Firestore の `stores/{uid}` ドキュメントを読み書きするリポジトリ。
/// [UserRepository]（観光客プロフィール）と対になる、店舗アカウント用のリポジトリ。
class StoreRepository {
  StoreRepository._();
  static final StoreRepository instance = StoreRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('stores');

  /// 店舗プロフィールを取得する。未登録なら null。
  Future<Store?> fetchStore(String uid) async {
    final snap = await _col.doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return Store.fromMap(uid, data);
  }

  /// 店舗プロフィールを保存する（既存があればマージ更新）。
  /// 新規作成時のみ `createdAt` を設定する。
  Future<void> saveStore(Store store) async {
    final doc = _col.doc(store.id);
    final isNew = !(await doc.get()).exists;
    await doc.set(
      {
        ...store.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 店舗登録済みかどうか。
  Future<bool> hasStore(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.exists && (snap.data()?['name'] as String?)?.isNotEmpty == true;
  }
  /// 未承認の店舗一覧を取得する（Admin画面用）。
  Future<List<Store>> fetchPendingStores() async {
    final snap = await _col.where('isApproved', isEqualTo: false).get();
    return snap.docs.map((doc) => Store.fromMap(doc.id, doc.data())).toList();
  }

  /// 承認済みの店舗一覧を取得する（カテゴリ指定可）。
  Future<List<Store>> fetchApprovedStores({String? category}) async {
    Query<Map<String, dynamic>> query = _col.where('isApproved', isEqualTo: true);
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    final snap = await query.get();
    return snap.docs.map((doc) => Store.fromMap(doc.id, doc.data())).toList();
  }

  /// 店舗を承認する。
  Future<void> approveStore(String storeId) async {
    await _col.doc(storeId).update({'isApproved': true});
  }
}
