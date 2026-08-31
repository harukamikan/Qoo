import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_repository.dart';
import '../home_shell.dart';
import '../onboarding_screen.dart';
import 'login_screen.dart';

/// 認証状態に応じて表示する画面を振り分けるゲート。
///
/// - 未ログイン           → [LoginScreen]
/// - ログイン済み・プロフィール未登録 → [OnboardingScreen]
/// - ログイン済み・プロフィール登録済み → [HomeShell]
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.instance.refresh,
      builder: (context, _, __) {
        return StreamBuilder<User?>(
          stream: AuthService.instance.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }

            final user = snapshot.data;
            if (user == null) {
              return const LoginScreen();
            }

            return FutureBuilder<bool>(
              future: UserRepository.instance.hasProfile(user.uid),
              builder: (context, profileSnap) {
                if (!profileSnap.hasData) return const _Splash();
                return profileSnap.data!
                    ? const HomeShell()
                    : const OnboardingScreen();
              },
            );
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
