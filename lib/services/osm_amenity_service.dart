import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

/// トイレ・ゴミ箱の位置情報。
class Amenity {
  final String id;
  final String type; // 'toilets' or 'waste_basket'
  final ll.LatLng position;

  Amenity({required this.id, required this.type, required this.position});
}

/// OpenStreetMapのOverpass APIから、周辺のトイレ・ゴミ箱を取得するサービス。
class OsmAmenityService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// 指定範囲（バウンディングボックス）内のトイレ・ゴミ箱を取得する。
  static Future<List<Amenity>> fetchAmenities({
    required ll.LatLng center,
    double radiusDegrees = 0.01, // 約1km四方
  }) async {
    final south = center.latitude - radiusDegrees;
    final north = center.latitude + radiusDegrees;
    final west = center.longitude - radiusDegrees;
    final east = center.longitude + radiusDegrees;
    final bbox = '$south,$west,$north,$east';

    final query = '''
[out:json][timeout:15];
(
  node["amenity"="toilets"]($bbox);
  node["amenity"="waste_basket"]($bbox);
);
out body;
''';

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final elements = data['elements'] as List;

      return elements.map((e) {
        final tags = e['tags'] as Map<String, dynamic>? ?? {};
        return Amenity(
          id: e['id'].toString(),
          type: tags['amenity'] as String? ?? 'unknown',
          position: ll.LatLng(
            (e['lat'] as num).toDouble(),
            (e['lon'] as num).toDouble(),
          ),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}