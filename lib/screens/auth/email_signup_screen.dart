import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// メールアドレス＋パスワードで新規登録する専用ページ。
class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({super.key});

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    _showError('メールアドレスとパスワードを入力してください');
    return;
  }
  setState(() => _loading = true);
  try {
    await AuthService.instance.signUpWithEmail(
      _emailController.text,
      _passwordController.text,
    );
    if (mounted) Navigator.of(context).pop();  // ← これを追加
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      _showError('このメールアドレスは既に使用されています');
    } else if (e.code == 'invalid-email') {
      _showError('無効なメールアドレスです');
    } else if (e.code == 'weak-password') {
      _showError('パスワードは6文字以上にしてください');
    } else {
      _showError('新規登録に失敗しました');
    }
    debugPrint('signUpWithEmail error: $e');
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
      appBar: AppBar(title: const Text('新規登録')),
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
                  labelText: 'パスワード（6文字以上）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _signUp,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('登録する'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}