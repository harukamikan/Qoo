// StoreRegistrationScreen のバリデーションのウィジェットテスト。
//
// 「店舗名 → 位置 → 電話番号」の順に必須チェックが走り、Firestore/Firebase Auth に
// 触れるのは全チェックを通過した後（登録実行時）だけなので、入力不備のケースは
// Firebase を初期化しなくてもテストできる。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qoo/screens/store/store_registration_screen.dart';

void main() {
  testWidgets('店舗名が空のまま登録すると「店舗名を入力してください」と出る',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StoreRegistrationScreen()),
    );

    await tester.tap(find.text('店舗を登録する'));
    await tester.pump();

    expect(find.text('店舗名を入力してください'), findsOneWidget);
  });

  testWidgets('店舗名だけ入力して位置未指定で登録すると位置指定エラーが出る',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StoreRegistrationScreen()),
    );

    await tester.enterText(find.widgetWithText(TextField, '店舗名'), 'テスト食堂');
    await tester.tap(find.text('店舗を登録する'));
    await tester.pump();

    expect(find.text('マップから住所・位置を指定してください'), findsOneWidget);
  });
}
