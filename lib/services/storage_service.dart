import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';
import '../models/review.dart';

/// 端末ローカル（SharedPreferences）へのデータ永続化を担当するサービス。
/// アプリ内の他のクラスは、このクラスを経由してのみ端末保存を行う。
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _kPlaces = 'jam_places';
  static const _kReviews = 'jam_reviews';
  static const _kHelpfulTaps = 'jam_helpful_taps';
  static const _kAlertEnabled = 'jam_alert_enabled';
  static const _kLanguageRegion = 'jam_language_region';
  static const _kProfileName = 'jam_profile_name';
  static const _kAvatarSeed = 'jam_avatar_seed';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------------- Places ----------------

  Future<List<Place>> loadPlaces() async {
    final raw = _prefs?.getString(_kPlaces);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlaces(List<Place> places) async {
    final raw = jsonEncode(places.map((p) => p.toJson()).toList());
    await _prefs?.setString(_kPlaces, raw);
  }

  // ---------------- Reviews ----------------

  Future<List<Review>> loadReviews() async {
    final raw = _prefs?.getString(_kReviews);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReviews(List<Review> reviews) async {
    final raw = jsonEncode(reviews.map((r) => r.toJson()).toList());
    await _prefs?.setString(_kReviews, raw);
  }

  // ---------------- Misc settings ----------------

  int loadHelpfulTaps() => _prefs?.getInt(_kHelpfulTaps) ?? 0;

  Future<void> saveHelpfulTaps(int value) async {
    await _prefs?.setInt(_kHelpfulTaps, value);
  }

  bool loadAlertEnabled() => _prefs?.getBool(_kAlertEnabled) ?? true;

  Future<void> saveAlertEnabled(bool value) async {
    await _prefs?.setBool(_kAlertEnabled, value);
  }

  /// "言語|地域" の形式で保存
  String loadLanguageRegion() =>
      _prefs?.getString(_kLanguageRegion) ?? '日本語|日本';

  Future<void> saveLanguageRegion(String language, String region) async {
    await _prefs?.setString(_kLanguageRegion, '$language|$region');
  }

  String loadProfileName() =>
      _prefs?.getString(_kProfileName) ?? 'Traveler Explorer';

  Future<void> saveProfileName(String value) async {
    await _prefs?.setString(_kProfileName, value);
  }

  int loadAvatarSeed() => _prefs?.getInt(_kAvatarSeed) ?? 0;

  Future<void> saveAvatarSeed(int value) async {
    await _prefs?.setInt(_kAvatarSeed, value);
  }

  /// デバッグ・検証用：保存データを全消去する
  Future<void> clearAll() async {
    await _prefs?.remove(_kPlaces);
    await _prefs?.remove(_kReviews);
    await _prefs?.remove(_kHelpfulTaps);
    await _prefs?.remove(_kAlertEnabled);
    await _prefs?.remove(_kLanguageRegion);
  }
}
