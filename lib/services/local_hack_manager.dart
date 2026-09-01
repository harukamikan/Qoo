import '../models/local_hack.dart';
import 'local_hack_service.dart';
import 'notification_service.dart';

class LocalHackManager {
  final LocalHackService _hackService = LocalHackService();
  final NotificationService _notificationService = NotificationService();

  // アプリ起動時に1度呼び出す初期化処理
  Future<void> init() async {
    await _notificationService.init();
  }

  // 現在地が更新された際（または一定間隔）に呼び出す処理
  Future<void> onLocationUpdated({
    required double userLat,
    required double userLng,
    required List<LocalHack> allHacks,
  }) async {
    // 1. 500m以内のHackを抽出
    final nearbyHacks = _hackService.getHacksAroundUser(
      userLat: userLat,
      userLng: userLng,
      allHacks: allHacks,
    );

    // 2. 条件（1時間に1回 / 24時間ルール）を満たせば通知を発行
    await _notificationService.checkAndNotifyAroundYou(nearbyHacks);
  }
}