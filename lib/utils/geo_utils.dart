import 'dart:math';

import 'package:latlong2/latlong.dart' as ll;

double distanceMeters(ll.LatLng a, ll.LatLng b) {
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
