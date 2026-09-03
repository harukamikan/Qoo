import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../models/store.dart';
import '../../services/auth_service.dart';
import '../../services/store_repository.dart';
import '../../services/ui_translations.dart';
import '../../widgets/location_picker_sheet.dart';

/// 店舗登録フォーム（店名 → 地図で位置指定 → 電話番号 → 登録）。
///
/// [AuthGate] は「ログイン済み・店舗ロール選択・stores/{uid} 未登録」の状態で
/// この画面を表示する。保存が完了すると [AuthService.notifyProfileChanged] を
/// 呼び、AuthGate が自動的に店舗ダッシュボード（[StoreHomeScreen]）へ切り替える。
///
/// 電話番号はSMS等での検証は行わず、連絡先として保存するだけ。
/// 本人確認は既存のメール認証基盤（[User.sendEmailVerification]）に委ねる。
class StoreRegistrationScreen extends StatefulWidget {
  const StoreRegistrationScreen({super.key});

  @override
  State<StoreRegistrationScreen> createState() =>
      _StoreRegistrationScreenState();
}

class _StoreRegistrationScreenState extends State<StoreRegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  ll.LatLng? _position;
  String _address = '';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    await showLocationPickerSheet(
      context,
      initialPosition: _position ?? const ll.LatLng(33.5902, 130.4017),
      onLocationSelected: (position, placeName) {
        setState(() {
          _position = position;
          _address = placeName;
        });
      },
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      _showError(UiTranslations.t('店舗名を入力してください'));
      return;
    }
    if (_position == null) {
      _showError(UiTranslations.t('マップから住所・位置を指定してください'));
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError(UiTranslations.t('電話番号を入力してください'));
      return;
    }

    final uid = AuthService.instance.uid;
    if (uid == null) {
      _showError(UiTranslations.t('ログイン情報が取得できませんでした。もう一度ログインしてください'));
      return;
    }

    setState(() => _saving = true);
    try {
      await StoreRepository.instance.saveStore(
        Store(
          id: uid,
          ownerUid: uid,
          name: _nameController.text.trim(),
          address: _address,
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          phoneNumber: _phoneController.text.trim(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(UiTranslations.t('登録に失敗しました。通信環境を確認してもう一度お試しください'));
      return;
    }

    // 本人確認は既存のメール認証基盤に委ねる。ここで await すると送信が遅い/
    // 失敗したときに画面遷移まで止まってしまうため、結果を待たずに投げっぱなしにする。
    // 再送信は StoreHomeScreen から手動でも行える。
    final user = AuthService.instance.currentUser;
    if (user != null && !user.emailVerified) {
      unawaited(
        user.sendEmailVerification().then(
              (_) => debugPrint('sendEmailVerification: sent to ${user.email}'),
              onError: (e) => debugPrint('sendEmailVerification failed: $e'),
            ),
      );
    }

    // 画面遷移は AuthGate が再評価して行う。
    AuthService.instance.notifyProfileChanged();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(UiTranslations.t('店舗登録'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                UiTranslations.t('お店の情報を登録してください'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 店名入力
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: UiTranslations.t('店舗名'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 住所・位置指定
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _position == null
                        ? UiTranslations.t('マップから住所・位置を指定')
                        : _address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_position != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${UiTranslations.t('緯度')}: ${_position!.latitude.toStringAsFixed(5)} '
                  '${UiTranslations.t('経度')}: ${_position!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 16),

              // 電話番号（検証なし・連絡先として保存するのみ）
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: UiTranslations.t('電話番号'),
                  helperText: UiTranslations.t('SMS等での認証は行いません。連絡先として保存されます'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(UiTranslations.t('店舗を登録する')),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    _saving ? null : () => AuthService.instance.signOut(),
                child: Text(UiTranslations.t('ログアウト')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
