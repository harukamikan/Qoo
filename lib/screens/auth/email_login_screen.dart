import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// メールアドレス＋パスワードでログインする専用ページ。
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    _showError('メールアドレスとパスワードを入力してください');
    return;
  }
  setState(() => _loading = true);
  try {
    await AuthService.instance.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );
    if (mounted) Navigator.of(context).pop();  // ← これを追加
    } on FirebaseAuthException catch (e) {
    if (e.code == 'invalid-email') {
      _showError('無効なメールアドレスです');
    } else if (e.code == 'user-not-found') {
      _showError('このメールアドレスは登録されていません');
    } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
      _showError('パスワードが正しくありません');
    } else {
      _showError('ログインに失敗しました');
    }
    debugPrint('signInWithEmail error: $e');
  } finally {
    if (mounted) setState(() => _loading = false);
  } 
}

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _signIn,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ログイン'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}