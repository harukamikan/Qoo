// RoleSelectScreen（Step 2: 観光客/店舗の役割選択画面）のウィジェットテスト。
//
// AuthService.chooseRole() は Firebase を一切呼ばない（メモリ上の状態変更のみ）ため、
// Firebase の初期化なしにこのテストだけで画面とロジックの結線を検証できる。
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qoo/models/user_role.dart';
import 'package:qoo/screens/auth/role_select_screen.dart';
import 'package:qoo/services/auth_service.dart';

import 'support/firebase_mocks.dart';

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    // 各テスト開始時に状態をリセットしておく
    AuthService.instance.pendingRole = null;
  });

  testWidgets('観光客ボタンを押すと pendingRole が tourist になる',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectScreen()),
    );

    expect(AuthService.instance.pendingRole, isNull);

    await tester.tap(find.text('観光客として利用する'));
    await tester.pump();

    expect(AuthService.instance.pendingRole, UserRole.tourist);
  });

  testWidgets('お店を登録するボタンを押すと pendingRole が store になる',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectScreen()),
    );

    await tester.tap(find.text('お店を登録する'));
    await tester.pump();

    expect(AuthService.instance.pendingRole, UserRole.store);
  });

  testWidgets('役割を選ぶと refresh 通知（AuthGate再評価用）が発火する',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectScreen()),
    );

    final before = AuthService.instance.refresh.value;

    await tester.tap(find.text('観光客として利用する'));
    await tester.pump();

    expect(AuthService.instance.refresh.value, before + 1);
  });
}
