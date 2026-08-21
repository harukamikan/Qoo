import 'package:flutter/foundation.dart';

import '../models/place.dart';
import '../models/review.dart';
import '../services/seed_data.dart';
import '../services/storage_service.dart';

/// アプリ全体で共有するデータストア。
///
/// Provider / Riverpod のような外部パッケージは使わず、Flutter SDK標準の
/// [ChangeNotifier] + [AnimatedBuilder] / [ListenableBuilder] だけで
/// 画面間のデータ同期を行うシンプルな実装。
/// 各画面は `AppData.instance` を直接参照し、更新系メソッドを呼ぶと
/// 自動的に `notifyListeners()` されて再描画される。
class AppData extends ChangeNotifier {
  AppData._();
  static final AppData instance = AppData._();

  final List<Place> places = [];
  final List<Review> reviews = [];

  int _myHelpfulTaps = 0;
  bool alertEnabled = true;
  String language = '日本語';
  String region = '日本';
  String profileName = 'Traveler Explorer';
  int avatarSeed = 0;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// baseline（表示上のプロフィール数値をスクリーンショット通りにするための下駄）
  static const int _savedBaseline = 38; // 38 + 保存中4件 = 42
  static const int _postedBaseline = 128; // 128 + 自分の新規投稿数
  static const int _helpfulBaseline = 356; // 356 + 自分が押した「参考になった」数

  /// 初回のみ実行される初期化処理。SharedPreferencesから読み込み、
  /// データが存在しなければシードデータを投入する。
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await StorageService.instance.init();

    final storedPlaces = await StorageService.instance.loadPlaces();
    if (storedPlaces.isEmpty) {
      places.addAll(SeedData.places());
      await StorageService.instance.savePlaces(places);
    } else {
      places.addAll(storedPlaces);
    }

    final storedReviews = await StorageService.instance.loadReviews();
    if (storedReviews.isEmpty) {
      reviews.addAll(SeedData.reviews());
      await StorageService.instance.saveReviews(reviews);
    } else {
      reviews.addAll(storedReviews);
    }

    _myHelpfulTaps = StorageService.instance.loadHelpfulTaps();
    alertEnabled = StorageService.instance.loadAlertEnabled();
    final langRegion = StorageService.instance.loadLanguageRegion().split('|');
    language = langRegion.isNotEmpty ? langRegion[0] : '日本語';
    region = langRegion.length > 1 ? langRegion[1] : '日本';
    profileName = StorageService.instance.loadProfileName();
    avatarSeed = StorageService.instance.loadAvatarSeed();

    _loaded = true;
    notifyListeners();
  }

  // ---------------- 派生値（プロフィール統計） ----------------

  int get savedCount =>
      _savedBaseline + places.where((p) => p.isSaved).length;

  int get postedCount =>
      _postedBaseline + reviews.where((r) => r.isMine).length;

  int get helpfulTotal => _helpfulBaseline + _myHelpfulTaps;

  // ---------------- Places ----------------

  List<Place> get savedPlaces => places.where((p) => p.isSaved).toList();

  List<Place> savedPlacesByCategory(String category) {
    if (category == 'すべて') return savedPlaces;
    return savedPlaces.where((p) => p.category == category).toList();
  }

  Place placeById(String id) => places.firstWhere((p) => p.id == id);

  void toggleSaved(String placeId) {
    final place = places.firstWhere((p) => p.id == placeId);
    place.isSaved = !place.isSaved;
    StorageService.instance.savePlaces(places);
    notifyListeners();
  }

  List<Place> searchPlaces(String query) {
    final q = query.trim();
    if (q.isEmpty) return places;
    return places
        .where((p) =>
            p.name.contains(q) ||
            p.category.contains(q) ||
            p.locationLabel.contains(q))
        .toList();
  }

  // ---------------- Reviews ----------------

  List<Review> reviewsForPlace(String placeId) {
    final list = reviews.where((r) => r.placeId == placeId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Review> get myReviews {
    final list = reviews.where((r) => r.isMine).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void addReview(Review review) {
    reviews.insert(0, review);
    // レビュー投稿でスポット側の評価件数も加算しておく（簡易反映）
    try {
      final place = places.firstWhere((p) => p.id == review.placeId);
      final totalScore =
          place.rating * place.ratingCount + review.stars.toDouble();
      place.ratingCount += 1;
      place.rating = double.parse(
        (totalScore / place.ratingCount).toStringAsFixed(1),
      );
      if (place.footerIconKey == 'star') {
        place.footerLabel = place.rating.toStringAsFixed(1);
      }
    } catch (_) {
      // 該当スポットが見つからない場合は評価反映をスキップ
    }
    StorageService.instance.saveReviews(reviews);
    StorageService.instance.savePlaces(places);
    notifyListeners();
  }

  void removeReview(String reviewId) {
    reviews.removeWhere((r) => r.id == reviewId);
    StorageService.instance.saveReviews(reviews);
    notifyListeners();
  }

  void incrementHelpful(String reviewId) {
    final review = reviews.firstWhere((r) => r.id == reviewId);
    review.helpfulCount += 1;
    _myHelpfulTaps += 1;
    StorageService.instance.saveReviews(reviews);
    StorageService.instance.saveHelpfulTaps(_myHelpfulTaps);
    notifyListeners();
  }

  // ---------------- 設定 ----------------

  void setAlertEnabled(bool value) {
    alertEnabled = value;
    StorageService.instance.saveAlertEnabled(value);
    notifyListeners();
  }

  void setLanguageRegion(String lang, String reg) {
    language = lang;
    region = reg;
    StorageService.instance.saveLanguageRegion(lang, reg);
    notifyListeners();
  }

  void updateProfile({String? name, int? avatarSeedValue}) {
    if (name != null && name.trim().isNotEmpty) {
      profileName = name.trim();
      StorageService.instance.saveProfileName(profileName);
    }
    if (avatarSeedValue != null) {
      avatarSeed = avatarSeedValue;
      StorageService.instance.saveAvatarSeed(avatarSeed);
    }
    notifyListeners();
  }
}
