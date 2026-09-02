import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

/// 通報用のダイアログを表示する汎用関数
void showReportDialog(BuildContext context, {required String title}) {
  showDialog(
    context: context,
    builder: (context) {
      String selectedReason = '不適切なコンテンツ';
      final reasons = [
        '不適切なコンテンツ',
        'スパム・宣伝目的',
        '虚偽の情報',
        'その他',
      ];

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('$title の通報'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '通報の理由を選択してください。',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedReason,
                  isExpanded: true,
                  items: reasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedReason = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await FirebaseFirestore.instance.collection('reports').add({
                      'title': title,
                      'reason': selectedReason,
                      'reported_at': FieldValue.serverTimestamp(),
                      'reporter_uid': AuthService.instance.uid ?? 'anonymous',
                    });
                  } catch (e) {
                    debugPrint('通報の保存に失敗: $e');
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「$selectedReason」として通報を受け付けました')),
                    );
                  }
                },
                child: const Text('通報する'),
              ),
            ],
          );
        },
      );
    },
  );
}
