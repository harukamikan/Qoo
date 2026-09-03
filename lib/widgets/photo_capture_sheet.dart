import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/ui_translations.dart';

enum PhotoVisibilityChoice { public, friends }

/// 写真投稿の入り口として、「今から撮る」か「アルバムから選ぶ」かを
/// 選択させるボトムシート。
///
/// 呼び出し側は [showPhotoCaptureSheet] を使うこと。
class PhotoCaptureSheet extends StatefulWidget {
  final Future<void> Function(String visibility) onTakePhoto;
  final Future<void> Function(String visibility) onPickFromGallery;

  const PhotoCaptureSheet({
    super.key,
    required this.onTakePhoto,
    required this.onPickFromGallery,
  });

  @override
  State<PhotoCaptureSheet> createState() => _PhotoCaptureSheetState();
}

class _PhotoCaptureSheetState extends State<PhotoCaptureSheet> {
  PhotoVisibilityChoice _visibility = PhotoVisibilityChoice.friends;

  String get _visibilityValue =>
      _visibility == PhotoVisibilityChoice.public ? 'public' : 'friends';

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
              title: Text(UiTranslations.t('今から撮る')),
              onTap: () {
                Navigator.pop(context);
                widget.onTakePhoto(_visibilityValue);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(UiTranslations.t('アルバムから選ぶ')),
              onTap: () {
                Navigator.pop(context);
                widget.onPickFromGallery(_visibilityValue);
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    UiTranslations.t('公開範囲'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<PhotoVisibilityChoice>(
                    segments: [
                      ButtonSegment(
                        value: PhotoVisibilityChoice.public,
                        label: Text(UiTranslations.t('全体公開')),
                        icon: const Icon(Icons.public),
                      ),
                      ButtonSegment(
                        value: PhotoVisibilityChoice.friends,
                        label: Text(UiTranslations.t('友達のみ')),
                        icon: const Icon(Icons.group),
                      ),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _visibility = selection.first;
                      });
                    },
                  ),
                ],
              ),
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
  required Future<void> Function(String visibility) onTakePhoto,
  required Future<void> Function(String visibility) onPickFromGallery,
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
