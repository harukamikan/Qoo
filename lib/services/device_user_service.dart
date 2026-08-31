import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// ログイン機能が無い/未導入の間、端末ごとに一意なIDを発行・保持するサービス。
/// ログイン機能マージ後は、これを実際のFirebase UIDに置き換える想定。
class DeviceUserService {
  static const String _deviceUserIdKey = 'device_user_id';

  /// 端末に紐づくユーザーIDを取得する。無ければ新規発行して保存する。
  static Future<String> getOrCreateDeviceUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceUserIdKey);
    if (id == null) {
      id = _generateId();
      await prefs.setString(_deviceUserIdKey, id);
    }
    return id;
  }

  static String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return 'user_${timestamp}_$randomPart';
  }
}