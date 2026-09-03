import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/app_data.dart';
import 'translation_service.dart';

/// アプリ内の固定UI文言（タブ名、ボタンラベルなど）を、
/// あらかじめ全言語に翻訳してキャッシュしておくクラス。
///
/// 投稿コメントの翻訳（TranslationService）とは別に、
/// 固定テキスト専用のキャッシュとして扱う。
///
/// 初回起動時にCloud Translation APIで翻訳し、結果をSharedPreferencesに
/// 保存する。2回目以降の起動ではローカル保存済みのデータを読み込むだけなので、
/// API呼び出しは発生しない。
class UiTranslations {
  UiTranslations._();

  static const _storageKey = 'ui_translations_cache_v1';

  /// {原文: {言語コード: 翻訳結果}} のキャッシュ
  static final Map<String, Map<String, String>> _cache = {};

  static bool _isPreloaded = false;
  static bool get isPreloaded => _isPreloaded;

  /// アプリ起動時に一度だけ呼ぶ。
  /// [texts]に渡した文言リストを、全言語に翻訳してキャッシュする。
  /// [originalLang]は[texts]の元の言語（例: 日本語の文言なら'ja'、
  /// 英語の文言なら'en'）。文言ごとに元の言語が違う場合は、
  /// このメソッドを言語ごとに複数回呼んでよい（すでにキャッシュ済みの
  /// 文言はスキップされるので、重複呼び出しのコストは小さい）。
  /// ローカル保存済みのデータがあればそれを使い、無ければAPIで翻訳して保存する。
  static Future<void> preload(
    List<String> texts, {
    String originalLang = 'ja',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!_isPreloaded) {
      final storedJson = prefs.getString(_storageKey);
      if (storedJson != null) {
        try {
          final decoded = jsonDecode(storedJson) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            _cache[key] = Map<String, String>.from(value as Map);
          });
        } catch (e) {
          // デコードに失敗したら、キャッシュを空のまま進める（下でAPI翻訳される）
        }
      }
    }

    // まだキャッシュに無い文言だけ、APIで翻訳する
    final missingTexts = texts.where((t) => !_cache.containsKey(t)).toList();

    if (missingTexts.isNotEmpty) {
      for (final text in missingTexts) {
        try {
          final translations =
              await TranslationService.instance.translateToAllLanguages(
            text: text,
            originalLang: originalLang,
          );
          _cache[text] = translations;
        } catch (e) {
          // 1つ失敗しても他は続行。失敗した場合は原文のみキャッシュしておく
          _cache[text] = {originalLang: text};
        }
      }

      // 新しく翻訳した分を含めて、ローカルに保存し直す
      await prefs.setString(_storageKey, jsonEncode(_cache));
    }

    _isPreloaded = true;
  }

  /// 原文キーを渡すと、今の言語設定（AppData.language）に応じた
  /// 翻訳済みテキストを返す。キャッシュに無い場合は原文をそのまま返す。
  static String t(String originalText) {
    final langCode =
        TranslationService.toLanguageCode(AppData.instance.language);
    return _cache[originalText]?[langCode] ?? originalText;
  }

  /// デバッグ・新機能追加時などにキャッシュを強制的にクリアしたい場合に使う。
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _cache.clear();
    _isPreloaded = false;
  }
}
