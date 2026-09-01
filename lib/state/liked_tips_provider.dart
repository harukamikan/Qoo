// liked_tips_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final likedTipsProvider = StreamProvider.autoDispose<List<Tip>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  // CollectionGroupを使用して、サブコレクション'likes'から自分がいいねしたドキュメントを取得
  return FirebaseFirestore.instance
      .collectionGroup('likes')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .asyncMap((snapshot) async {
        final tipIds = snapshot.docs.map((doc) => doc.reference.parent.parent!.id).toList();
        if (tipIds.isEmpty) return [];

        // 該当するTipsのドキュメントをまとめて取得
        final tipsQuery = await FirebaseFirestore.instance
            .collection('tips')
            .where(FieldPath.documentId, whereIn: tipIds)
            .get();

        return tipsQuery.docs.map((doc) => Tip.fromFirestore(doc)).toList();
      });
});