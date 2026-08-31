import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'd14dvonx';
  static const String _uploadPreset = 'qoo_photos';

  /// 画像データ（バイト列）をCloudinaryにアップロードして、画像URLを返す。
  /// アップロード失敗時はnullを返す。
  static Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'photo.jpg',
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonData = jsonDecode(responseString);
      if (response.statusCode == 200) {
        return jsonData['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }
}