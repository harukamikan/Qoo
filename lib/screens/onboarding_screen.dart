import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';

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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Googleアカウントの表示名を初期値に入れておく
    _nameController.text =
        AuthService.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_nameController.text.isEmpty ||
        _selectedNationality == null ||
        _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を入力してください')),
      );
      return;
    }

    final uid = AuthService.instance.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログイン情報が取得できませんでした。もう一度ログインしてください')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await UserRepository.instance.saveProfile(
        UserProfile(
          userId: uid,
          name: _nameController.text.trim(),
          nationality: _selectedNationality!,
          language: _selectedLanguage!,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました。通信環境を確認してもう一度お試しください')),
      );
      return;
    }

    // 保存完了。画面遷移は AuthGate が再評価して行う。
    AuthService.instance.notifyProfileChanged();
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
              onPressed: _saving ? null : _onSubmit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('はじめる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
