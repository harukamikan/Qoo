import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Cloud Translation APIを使って、投稿内容を複数言語に翻訳するサービス。
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  static const _endpoint =
      'https://translation.googleapis.com/language/translate/v2';

  /// アプリで対応する言語コード一覧。
  /// 'ja'（日本語）も含めることで、お店側の投稿・日本語話者の閲覧にも対応する。
  static const List<String> supportedLanguages = [
    'en', // 英語
    'ko', // 韓国語
    'zh-TW', // 繁体字中国語
    'zh-CN', // 簡体字中国語
    'th', // タイ語
    'ja', // 日本語
  ];

  /// [text]を[originalLang]から、[supportedLanguages]の全言語に翻訳する。
  /// 戻り値は {言語コード: 翻訳結果} のマップ。
  /// 原文と同じ言語には、翻訳せず原文をそのまま入れる（無駄なAPI呼び出しを避ける）。
  Future<Map<String, String>> translateToAllLanguages({
    required String text,
    required String originalLang,
  }) async {
    final apiKey = dotenv.env['TRANSLATION_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TRANSLATION_API_KEYが設定されていません（.envを確認してください）');
    }

    final Map<String, String> result = {};

    for (final targetLang in supportedLanguages) {
      // 原文と同じ言語なら、翻訳せずそのまま使う
      final normalizedOriginal = _normalize(originalLang);
      final normalizedTarget = _normalize(targetLang);
      if (normalizedOriginal == normalizedTarget) {
        result[targetLang] = text;
        continue;
      }

      try {
        final translated = await _translateSingle(
          text: text,
          targetLang: targetLang,
          apiKey: apiKey,
        );
        result[targetLang] = translated;
      } catch (e) {
        // 1言語の翻訳が失敗しても、他の言語の翻訳は続行する
        result[targetLang] = text; // フォールバック：原文をそのまま入れる
      }
    }

    return result;
  }

  Future<String> _translateSingle({
    required String text,
    required String targetLang,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$_endpoint?key=$apiKey');
    final response = await http.post(
      uri,
      body: {
        'q': text,
        'target': targetLang,
        'format': 'text',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('翻訳APIエラー: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final translatedText =
        data['data']['translations'][0]['translatedText'] as String;
    return translatedText;
  }

  /// AppData.languageの表示名（例: '日本語'）を言語コード（例: 'ja'）に変換する。
  static String toLanguageCode(String displayName) {
    switch (displayName) {
      case '日本語':
        return 'ja';
      case 'English':
        return 'en';
      case '中文':
        return 'zh-CN';
      case '한국어':
        return 'ko';
      default:
        return 'ja'; // フォールバック
    }
  }

  /// 'zh_tw' や 'zh-TW' のような表記ゆれを吸収するための正規化。
  String _normalize(String lang) {
    return lang.toLowerCase().replaceAll('_', '-');
  }
}
