import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../models/nearby_comment.dart';

const String _helpfulPrefsKey = 'helpful_marked_comment_ids';

final likedTipsProvider = FutureProvider<List<NearbyComment>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final likedIds = prefs.getStringList(_helpfulPrefsKey) ?? [];

  if (likedIds.isEmpty) return [];

  final snapshot = await FirebaseFirestore.instance.collection('comments').get();
  final results = <NearbyComment>[];

  for (final doc in snapshot.docs) {
    if (likedIds.contains(doc.id)) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

      results.add(
        NearbyComment(
          id: doc.id,
          placeName: data['place_name'] as String? ?? '(名称未設定)',
          category: data['category'] as String? ?? 'General',
          content: data['content'] as String? ?? '',
          userName: data['user_name'] as String? ?? 'Traveler',
          userCountry: data['user_country'] as String? ?? '🇯🇵',
          helpfulCount: (data['helpful_count'] as num?)?.toInt() ?? 0,
          position: ll.LatLng(lat, lng),
          distanceMeters: 0,
        ),
      );
    }
  }

  return results;
});