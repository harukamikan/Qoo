import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../utils/geo_utils.dart';

const double walkingAlertRadiusMeters = 100;
const int _positionUpdateDistanceMeters = 20;

/// Comments within [walkingAlertRadiusMeters] of [here] that aren't in
/// [alreadyNotified] yet, as (id, placeName) pairs.
List<MapEntry<String, String>> findNewlyNearby({
  required ll.LatLng here,
  required Map<String, Map<String, dynamic>> commentsById,
  required Set<String> alreadyNotified,
}) {
  final result = <MapEntry<String, String>>[];
  for (final entry in commentsById.entries) {
    if (alreadyNotified.contains(entry.key)) continue;

    final data = entry.value;
    final lat = (data['latitude'] as num?)?.toDouble();
    final lng = (data['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;

    if (distanceMeters(here, ll.LatLng(lat, lng)) <= walkingAlertRadiusMeters) {
      result
          .add(MapEntry(entry.key, data['place_name'] as String? ?? '近くのスポット'));
    }
  }
  return result;
}

// Foreground-only for now; keep start()/stop() as the only public surface so
// a background-capable location source can replace the position stream later
// without touching callers.
class NearbyAlertService {
  final _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<Position>? _positionSubscription;
  final Set<String> _notifiedCommentIds = {};
  bool _initialized = false;

  Future<void> start() async {
    if (_positionSubscription != null) return;

    await _ensureInitialized();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _positionUpdateDistanceMeters,
      ),
    ).listen(_checkNearbyComments);

    final current = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    await _checkNearbyComments(current);
  }

  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings: settings);
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> _checkNearbyComments(Position position) async {
    final here = ll.LatLng(position.latitude, position.longitude);
    final snapshot =
        await FirebaseFirestore.instance.collection('comments').get();
    final commentsById = {for (final doc in snapshot.docs) doc.id: doc.data()};

    final newlyNearby = findNewlyNearby(
      here: here,
      commentsById: commentsById,
      alreadyNotified: _notifiedCommentIds,
    );

    for (final entry in newlyNearby) {
      _notifiedCommentIds.add(entry.key);
      await _showNotification(entry.value);
    }
  }

  Future<void> _showNotification(String placeName) async {
    const androidDetails = AndroidNotificationDetails(
      'nearby_comments',
      '近くの口コミ通知',
      channelDescription: '歩いている間に近くの旅行者の口コミを通知します',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '近くに旅行者の口コミがあります',
      body: placeName,
      notificationDetails: details,
    );
  }
}
