import 'package:flutter/material.dart';
import 'saved_spots_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 現在のユーザー設定値
  String _userName = 'ナカ';
  String _userNationality = '日本 🇯🇵';
  String _userLanguage = '日本語';

  // 選択肢リスト
  final List<String> _nationalities = [
    '日本 🇯🇵',
    'アメリカ 🇺🇸',
    '韓国 🇰🇷',
    '中国 🇨🇳',
    'その他'
  ];
  final List<String> _languages = ['日本語', 'English', '한국어', '中文'];

  // 国籍変更ダイアログ
  void _showNationalityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('国籍の変更'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _nationalities.map((nation) {
              return RadioListTile<String>(
                title: Text(nation),
                value: nation,
                groupValue: _userNationality,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _userNationality = value;
                    });
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 言語変更ダイアログ
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('表示言語の変更'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang),
                value: lang,
                groupValue: _userLanguage,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _userLanguage = value;
                    });
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // プロフィールアイコン
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              _userName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // プロフィール詳細カード（タップで変更可能）
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.flag, color: Colors.teal),
                      title: const Text('国籍'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_userNationality,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: _showNationalityDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.language, color: Colors.teal),
                      title: const Text('表示言語'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_userLanguage,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: _showLanguageDialog,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // メニュー一覧（保存機能への導線）
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.bookmark, color: Colors.blueAccent),
                    title: const Text('保存したスポット・口コミ'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SavedSpotsScreen()),
                      );
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
