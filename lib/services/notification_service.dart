import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_hack.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String keyLastNotificationTime = 'last_notification_time';
  static const String keyNotifiedHacks = 'notified_hacks_map';

  // 初期化処理
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(
      settings: initSettings,
    );
  }

  // 500m以内のHackリストから通知を送るべきものを判定して通知する
  Future<void> checkAndNotifyAroundYou(List<LocalHack> nearbyHacks) async {
    if (nearbyHacks.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // 1. 全体通知制限：前回の通知から1時間以上経過しているかチェック
    final lastTimeStr = prefs.getString(keyLastNotificationTime);
    if (lastTimeStr != null) {
      final lastTime = DateTime.parse(lastTimeStr);
      if (now.difference(lastTime).inHours < 1) {
        return; // 1時間以内なら通知しない
      }
    }

    // 履歴データの復元 (Hack ID -> 最終通知日時のマップ)
    final historyJson = prefs.getString(keyNotifiedHacks);
    Map<String, String> notifiedMap = historyJson != null
        ? Map<String, String>.from(jsonDecode(historyJson))
        : {};

    // 2. 個別制限：24時間以上経過している未通知Hackのみをフィルタリング
    List<LocalHack> targetHacks = nearbyHacks.where((hack) {
      if (!notifiedMap.containsKey(hack.id)) return true;
      final hackLastTime = DateTime.parse(notifiedMap[hack.id]!);
      return now.difference(hackLastTime).inHours >= 24;
    }).toList();

    if (targetHacks.isEmpty) return;

    // 3. 通知の送信（「Around You」としてまとめて通知）
    await _sendAroundYouNotification(targetHacks);

    // 4. 通知履歴の更新
    prefs.setString(keyLastNotificationTime, now.toIso8601String());
    for (var hack in targetHacks) {
      notifiedMap[hack.id] = now.toIso8601String();
    }
    prefs.setString(keyNotifiedHacks, jsonEncode(notifiedMap));
  }

  // ローカル通知を発行
  Future<void> _sendAroundYouNotification(List<LocalHack> hacks) async {
    const androidDetails = AndroidNotificationDetails(
      'local_hack_channel',
      'Local Hack Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    String title = '【Around You】近くに役立つ情報があります';
    String body = hacks.length == 1
        ? '「${hacks.first.title}」のHackをチェックしてみよう！'
        : '「${hacks.first.title}」など${hacks.length}件のHackがあります！';

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}