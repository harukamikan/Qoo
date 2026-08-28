import 'package:flutter/material.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String? _selectedNationality;
  String? _selectedLanguage;

  // 言語の選択肢（あとで増やせる）
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'ko', 'label': '한국어'},
    {'code': 'zh_tw', 'label': '繁體中文'},
    {'code': 'zh_cn', 'label': '简体中文'},
    {'code': 'th', 'label': 'ไทย'},
    {'code': 'ja', 'label': '日本語'},
  ];

  // 国籍の選択肢（サンプル、あとで増やせる）
  final List<String> _nationalities = [
    'South Korea',
    'Taiwan',
    'China',
    'Hong Kong',
    'Thailand',
    'USA',
    'Australia',
    'UK',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // 今はまだFirebase接続してないので、入力チェックだけ
    if (_nameController.text.isEmpty ||
        _selectedNationality == null ||
        _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を入力してください')),
      );
      return;
    }

      // TODO: ここでFirestoreにUserProfileを保存する処理を後で追加
    debugPrint('Name: ${_nameController.text}');
    debugPrint('Nationality: $_selectedNationality');
    debugPrint('Language: $_selectedLanguage');

    // 地図画面へ遷移
    Navigator.of(context).pushReplacement(
     MaterialPageRoute(builder: (context) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ようこそ！まずはあなたのことを教えてください',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 名前入力
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'お名前',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 国籍選択
            DropdownButtonFormField<String>(
              initialValue: _selectedNationality,
              decoration: const InputDecoration(
                labelText: '国籍',
                border: OutlineInputBorder(),
              ),
              items: _nationalities.map((nat) {
                return DropdownMenuItem(value: nat, child: Text(nat));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedNationality = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 言語選択
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: '表示言語',
                border: OutlineInputBorder(),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang['code'],
                  child: Text(lang['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _onSubmit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('はじめる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}