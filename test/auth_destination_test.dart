// AuthGate のログイン後ロール判定ロジック（resolveAuthDestination）の単体テスト。
//
// Firestore/Firebase を一切使わない純粋関数として切り出してあるため、
// Firebase の初期化なしに全パターンを検証できる（Step 3 の中心ロジック）。
import 'package:flutter_test/flutter_test.dart';

import 'package:qoo/models/user_role.dart';
import 'package:qoo/screens/auth/auth_destination.dart';

void main() {
  group('resolveAuthDestination', () {
    test('店舗プロフィールがあれば、役割選択に関わらず storeHome', () {
      expect(
        resolveAuthDestination(
          hasStore: true,
          hasProfile: false,
          pendingRole: UserRole.tourist, // 選択を間違えていても実データを優先
        ),
        AuthDestination.storeHome,
      );
    });

    test('観光客プロフィールがあれば、役割選択に関わらず touristHome', () {
      expect(
        resolveAuthDestination(
          hasStore: false,
          hasProfile: true,
          pendingRole: UserRole.store, // 選択を間違えていても実データを優先
        ),
        AuthDestination.touristHome,
      );
    });

    test('両方のプロフィールが存在する場合は store が優先される', () {
      expect(
        resolveAuthDestination(
          hasStore: true,
          hasProfile: true,
          pendingRole: UserRole.tourist,
        ),
        AuthDestination.storeHome,
      );
    });

    test('未登録・店舗ロール選択中なら storeRegistration', () {
      expect(
        resolveAuthDestination(
          hasStore: false,
          hasProfile: false,
          pendingRole: UserRole.store,
        ),
        AuthDestination.storeRegistration,
      );
    });

    test('未登録・観光客ロール選択中なら onboarding', () {
      expect(
        resolveAuthDestination(
          hasStore: false,
          hasProfile: false,
          pendingRole: UserRole.tourist,
        ),
        AuthDestination.onboarding,
      );
    });

    test('未登録・役割不明（null）でも onboarding にフォールバックする', () {
      expect(
        resolveAuthDestination(
          hasStore: false,
          hasProfile: false,
          pendingRole: null,
        ),
        AuthDestination.onboarding,
      );
    });
  });
}
