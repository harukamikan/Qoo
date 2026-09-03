import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/store_repository.dart';
import '../../services/user_repository.dart';
import '../home_shell.dart';
import '../onboarding_screen.dart';
import '../store/store_home_screen.dart';
import '../store/store_registration_screen.dart';
import 'auth_destination.dart';
import 'login_screen.dart';
import 'role_select_screen.dart';

/// 認証状態に応じて表示する画面を振り分けるゲート。
///
/// - 未ログイン・役割未選択           → [RoleSelectScreen]
/// - 未ログイン・役割選択済み         → [LoginScreen]
/// - ログイン済み・stores/{uid} 登録済み → [StoreHomeScreen]
/// - ログイン済み・users/{uid} 登録済み  → [HomeShell]
/// - ログイン済み・未登録・店舗ロール    → [StoreRegistrationScreen]
/// - ログイン済み・未登録・観光客ロール  → [OnboardingScreen]
///
/// 店舗/観光客どちらのプロフィールも存在しない「新規ユーザー」の場合のみ、
/// ログイン前に選んだ [AuthService.pendingRole] を見て振り分ける。
/// 既にどちらかのプロフィールが存在する場合は、選んだ役割に関わらず
/// 実データを優先する（役割選択を間違えてログインしても事故らないようにするため）。
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<AuthDestination> _resolveDestination(String uid) async {
    final hasStore = await StoreRepository.instance.hasStore(uid);
    // 既に店舗登録済みなら、観光客プロフィールの有無を確認するまでもない。
    final hasProfile =
        hasStore ? false : await UserRepository.instance.hasProfile(uid);
    return resolveAuthDestination(
      hasStore: hasStore,
      hasProfile: hasProfile,
      pendingRole: AuthService.instance.pendingRole,
    );
  }

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
              return AuthService.instance.pendingRole == null
                  ? const RoleSelectScreen()
                  : const LoginScreen();
            }

            return FutureBuilder<AuthDestination>(
              future: _resolveDestination(user.uid),
              builder: (context, destSnap) {
                if (!destSnap.hasData) return const _Splash();
                switch (destSnap.data!) {
                  case AuthDestination.storeHome:
                    return const StoreHomeScreen();
                  case AuthDestination.touristHome:
                    return const HomeShell();
                  case AuthDestination.storeRegistration:
                    return const StoreRegistrationScreen();
                  case AuthDestination.onboarding:
                    return const OnboardingScreen();
                }
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
