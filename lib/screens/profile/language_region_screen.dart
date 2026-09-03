import 'package:flutter/material.dart';

import '../../state/app_data.dart';
import '../../theme/app_colors.dart';

/// プロフィール画面の「言語と地域」から遷移する設定画面。
class LanguageRegionScreen extends StatefulWidget {
  const LanguageRegionScreen({super.key});

  @override
  State<LanguageRegionScreen> createState() => _LanguageRegionScreenState();
}

class _LanguageRegionScreenState extends State<LanguageRegionScreen> {
  static const _languages = [
    '日本語',
    'English',
    '한국어',
    '繁體中文',
    '简体中文',
    'ไทย',
  ];
  static const _regions = [
    '日本',
    'アメリカ',
    '韓国',
    '台湾',
    '中国',
    'タイ',
  ];

  late String _language;
  late String _region;

  @override
  void initState() {
    super.initState();
    _language = AppData.instance.language;
    _region = AppData.instance.region;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('言語と地域')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('表示言語',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            ..._languages.map(
              (lang) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: lang,
                groupValue: _language,
                activeColor: AppColors.primary,
                title: Text(lang),
                onChanged: (v) => setState(() => _language = v!),
              ),
            ),
            const SizedBox(height: 20),
            const Text('地域',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            ..._regions.map(
              (reg) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: reg,
                groupValue: _region,
                activeColor: AppColors.primary,
                title: Text(reg),
                onChanged: (v) => setState(() => _region = v!),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                AppData.instance.setLanguageRegion(_language, _region);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('言語と地域を更新しました')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
