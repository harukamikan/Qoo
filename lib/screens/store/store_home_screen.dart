import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/store.dart';
import '../../services/auth_service.dart';
import '../../services/store_repository.dart';
import '../../services/ui_translations.dart';
import '../map_screen.dart';

/// 登録済み店舗オーナー向けのホーム画面。
///
/// 現時点では登録情報の確認表示のみ。店舗コメント・Local Hackの編集UIは
/// 今後の別ステップで実装する。
/// [AuthGate] は「ログイン済み・stores/{uid} 登録済み」の状態でこの画面を表示する。
class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  bool _sendingVerification = false;

  Future<void> _resendVerificationEmail() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    setState(() => _sendingVerification = true);
    try {
      await user.reload(); // 直近で確認済みになっていないか最新化してから送る
      if (user.emailVerified) {
        _showMessage(UiTranslations.t('既にメール確認済みです'));
      } else {
        await user.sendEmailVerification();
        debugPrint('sendEmailVerification: sent to ${user.email}');
        _showMessage(
            '${UiTranslations.t('確認メールを')} ${user.email} ${UiTranslations.t('に再送信しました')}');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('sendEmailVerification failed: ${e.code} ${e.message}');
      if (e.code == 'too-many-requests') {
        _showMessage(UiTranslations.t('送信しすぎです。しばらく待ってから再度お試しください'));
      } else {
        _showMessage('${UiTranslations.t('送信に失敗しました')}（${e.code}）');
      }
    } catch (e) {
      debugPrint('sendEmailVerification failed: $e');
      _showMessage(UiTranslations.t('送信に失敗しました'));
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    final user = AuthService.instance.currentUser;
    final emailVerified = user?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(UiTranslations.t('店舗管理'))),
      body: uid == null
          ? Center(child: Text(UiTranslations.t('ログイン情報を取得できませんでした')))
          : FutureBuilder<Store?>(
              future: StoreRepository.instance.fetchStore(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final store = snapshot.data;
                if (store == null) {
                  return Center(
                      child: Text(UiTranslations.t('店舗情報が見つかりませんでした')));
                }
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Icon(Icons.storefront, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      store.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          emailVerified ? Icons.verified : Icons.error_outline,
                          size: 16,
                          color: emailVerified ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          emailVerified
                              ? UiTranslations.t('メール確認済み')
                              : '${UiTranslations.t('メール未確認')}（${user?.email ?? ''}）',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    if (!emailVerified) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _sendingVerification
                              ? null
                              : _resendVerificationEmail,
                          icon: _sendingVerification
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.email_outlined, size: 18),
                          label: Text(UiTranslations.t('確認メールを再送信')),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          UiTranslations.t('届かない場合は迷惑メールフォルダもご確認ください'),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(store.address),
                      subtitle: Text(
                        '${UiTranslations.t('緯度')}: ${store.latitude.toStringAsFixed(5)} '
                        '${UiTranslations.t('経度')}: ${store.longitude.toStringAsFixed(5)}',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(store.phoneNumber),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      UiTranslations.t('店舗コメント・Local Hackの編集は準備中です'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    // 店舗ロールのままだと観光客側の画面（地図タブ等）には
                    // 通常たどり着けないため、確認用にここから直接プレビューできる
                    // ようにしている。ログイン状態やロールは変更しない。
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MapPage()),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(UiTranslations.t('観光客側の地図をプレビュー')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => AuthService.instance.signOut(),
                      child: Text(UiTranslations.t('ログアウト')),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
