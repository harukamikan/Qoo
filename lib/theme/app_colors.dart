import 'package:flutter/material.dart';

/// JAMアプリ全体で使うカラーパレット。
/// スクリーンショットの「朱色（vermillion）× ネイビー × クリーム」の
/// トーンを踏襲しています。
class AppColors {
  AppColors._();

  /// ページ全体の背景（淡いクリーム／ピーチ）
  static const Color background = Color(0xFFFCF1EA);

  /// カードなどの表面色
  static const Color surface = Color(0xFFFFFFFF);

  /// メインカラー（朱色 / vermillion）
  static const Color primary = Color(0xFFE8552E);

  /// メインカラーの淡色（未選択チップの背景など）
  static const Color primaryLight = Color(0xFFFBDED0);

  /// メインカラーのさらに淡い背景（バナーなど）
  static const Color primaryFaint = Color(0xFFFDEDE6);

  /// ネイビー（タイトルやリンクに使用）
  static const Color navy = Color(0xFF1E2A5E);

  /// ネイビーの明るいバリエーション
  static const Color navyLight = Color(0xFF33407F);

  /// 選択中チップの背景（ネイビー）
  static const Color chipActiveBg = Color(0xFF29346B);

  /// 未選択チップの背景（淡いピーチ）
  static const Color chipInactiveBg = Color(0xFFFCE0D2);

  /// 本文テキスト
  static const Color textDark = Color(0xFF2B2B2B);

  /// 補助テキスト（グレー）
  static const Color textGrey = Color(0xFF7A7A7A);

  /// 星評価の色
  static const Color star = Color(0xFFE8552E);

  /// アクセントの成功色（未使用時の予備）
  static const Color success = Color(0xFF3FA34D);

  /// 枠線色
  static const Color border = Color(0xFFF0DCCF);

  /// 影用の薄い黒
  static const Color shadow = Color(0x1A1E2A5E);
}
