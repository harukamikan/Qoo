import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const double nearbyRadiusMeters = 500;

final ll.LatLng fukuokaFallback = ll.LatLng(33.5902, 130.4017);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  ll.LatLng? _currentLocation;
  List<NearbyComment> _nearbyComments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() => _isLoading = true);

    final position = await _getCurrentPosition();
    final center = position ?? fukuokaFallback;
    final comments = await _fetchNearbyComments(center);

    if (!mounted) return;
    setState(() {
      _currentLocation = position;
      _nearbyComments = comments;
      _isLoading = false;
    });
  }

  Future<ll.LatLng?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return ll.LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<List<NearbyComment>> _fetchNearbyComments(ll.LatLng center) async {
    final snapshot = await FirebaseFirestore.instance.collection('comments').get();

    final results = <NearbyComment>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final point = ll.LatLng(lat, lng);
      final distance = _distanceMeters(center, point);
      if (distance <= nearbyRadiusMeters) {
        results.add(NearbyComment(
          id: doc.id,
          placeName: data['place_name'] as String? ?? '(名称未設定)',
          category: data['category'] as String? ?? '',
          content: data['content'] as String? ?? '',
          position: point,
          distanceMeters: distance,
        ));
      }
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  double _distanceMeters(ll.LatLng a, ll.LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final center = _currentLocation ?? fukuokaFallback;

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.qoo',
          ),
          MarkerLayer(
            markers: [
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 24,
                  height: 24,
                  child: const _CurrentLocationDot(),
                ),
              for (final comment in _nearbyComments)
                Marker(
                  point: comment.position,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showCommentSheet(context, comment),
                    child: const _CommentPin(),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadEverything,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showCommentSheet(BuildContext context, NearbyComment comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.placeName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(comment.category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Text(comment.content, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class NearbyComment {
  final String id;
  final String placeName;
  final String category;
  final String content;
  final ll.LatLng position;
  final double distanceMeters;

  NearbyComment({
    required this.id,
    required this.placeName,
    required this.category,
    required this.content,
    required this.position,
    required this.distanceMeters,
  });
}

class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _CommentPin extends StatelessWidget {
  const _CommentPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.deepOrange, width: 2),
      ),
      child: const Icon(Icons.place, color: Colors.deepOrange, size: 20),
    );
  }
}