import 'package:latlong2/latlong.dart' as ll;

class TravelPhoto {
  final String id;
  final String imageUrl;
  final ll.LatLng position;
  final String userId;
  final double distanceMeters;

  TravelPhoto({
    required this.id,
    required this.imageUrl,
    required this.position,
    required this.userId,
    required this.distanceMeters,
  });
}