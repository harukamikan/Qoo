import 'package:geolocator/geolocator.dart';
import '../models/local_hack.dart';

class LocalHackService {
  // 現在地から500m以内にあるHackを抽出する関数
  List<LocalHack> getHacksAroundUser({
    required double userLat,
    required double userLng,
    required List<LocalHack> allHacks,
  }) {
    List<LocalHack> nearbyHacks = [];

    for (var hack in allHacks) {
      // ユーザーの現在地とHackの距離（メートル単位）を計算
      double distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        hack.latitude,
        hack.longitude,
      );

      // 500m以内の場合に追加
      if (distanceInMeters <= 500) {
        nearbyHacks.add(hack);
      }
    }

    return nearbyHacks;
  }
}