import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'cloudinary_service.dart';
import 'device_user_service.dart';

/// 写真投稿の共通ロジック（Cloudinaryアップロード→Firestore保存）。
/// map_screen.dartとPostSelectionPageの両方から呼び出せる。
class PhotoUploadService {
  /// 画像バイトをCloudinaryにアップロードしてFirestoreに保存する。
  /// 成功したら`imageUrl`を返す。失敗したら`null`を返す。
  static Future<String?> uploadAndSave({
    required Uint8List bytes,
    required String filename,
    required ll.LatLng position,
  }) async {
    final imageUrl = await CloudinaryService.uploadImageBytes(
      bytes,
      filename: filename,
    );
    if (imageUrl == null) return null;

    final userId = await DeviceUserService.getOrCreateDeviceUserId();

    await FirebaseFirestore.instance.collection('travel_photos').add({
      'imageUrl': imageUrl,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return imageUrl;
  }
}