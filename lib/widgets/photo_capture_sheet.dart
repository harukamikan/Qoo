import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 写真投稿の入り口として、「今から撮る」か「アルバムから選ぶ」かを
/// 選択させるボトムシート。
///
/// 呼び出し側は [showPhotoCaptureSheet] を使うこと。
class PhotoCaptureSheet extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFromGallery;

  const PhotoCaptureSheet({
    super.key,
    required this.onTakePhoto,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('今から撮る'),
              onTap: () {
                Navigator.pop(context);
                onTakePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('アルバムから選ぶ'),
              onTap: () {
                Navigator.pop(context);
                onPickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// [PhotoCaptureSheet] をボトムシートとして表示するヘルパー関数。
Future<void> showPhotoCaptureSheet(
  BuildContext context, {
  required VoidCallback onTakePhoto,
  required VoidCallback onPickFromGallery,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => PhotoCaptureSheet(
      onTakePhoto: onTakePhoto,
      onPickFromGallery: onPickFromGallery,
    ),
  );
}