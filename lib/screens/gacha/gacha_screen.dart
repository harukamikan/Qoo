import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    home: GachaScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

/// レアリティ定義
enum Rarity { N, R, SR, SSR }

extension RarityExtension on Rarity {
  String get label {
    switch (this) {
      case Rarity.N: return 'N';
      case Rarity.R: return 'R';
      case Rarity.SR: return 'SR';
      case Rarity.SSR: return 'SSR';
    }
  }

  Color get color {
    switch (this) {
      case Rarity.N: return const Color(0xFF8D8D8D);
      case Rarity.R: return const Color(0xFF1E88E5);
      case Rarity.SR: return const Color(0xFF8E24AA);
      case Rarity.SSR: return const Color(0xFFFFB300);
    }
  }
}

/// ガチャアイテムモデル
class GachaItem {
  final String name;
  final String icon;
  final Rarity rarity;

  GachaItem({required this.name, required this.icon, required this.rarity});
}

/// 和風演出テーマ
enum CustomGachaTheme {
  sakuraShrine,  // N / R演出
  samuraiSlash,  // SR演出
  hanabiFestival,// SSR演出
}

// -----------------------------------------------------------------------------
// ガチャアイテムデータベース
// -----------------------------------------------------------------------------
final List<GachaItem> _itemPool = [
  // SSR (3%)
  GachaItem(name: '黄金の開運招き猫', icon: '🐱', rarity: Rarity.SSR),
  GachaItem(name: '鳳凰の天羽衣', icon: '🦚', rarity: Rarity.SSR),
  GachaItem(name: '龍神の霊珠', icon: '🐉', rarity: Rarity.SSR),
  
  // SR (12%)
  GachaItem(name: '妖刀・村正', icon: '⚔️', rarity: Rarity.SR),
  GachaItem(name: '影ノ忍装束', icon: '𥉌', rarity: Rarity.SR),
  GachaItem(name: '陰陽師の式神扇', icon: '🪭', rarity: Rarity.SR),

  // R (25%)
  GachaItem(name: '風神の漆椀', icon: '🍵', rarity: Rarity.R),
  GachaItem(name: '狐の白面', icon: '🦊', rarity: Rarity.R),
  GachaItem(name: '般若の面', icon: '👺', rarity: Rarity.R),
  GachaItem(name: '涼やかな風鈴', icon: '🎐', rarity: Rarity.R),

  // N (60%)
  GachaItem(name: '足軽の竹刀', icon: '🎋', rarity: Rarity.N),
  GachaItem(name: '破れ和傘', icon: '☂️', rarity: Rarity.N),
  GachaItem(name: '三色団子', icon: '🍡', rarity: Rarity.N),
  GachaItem(name: '塗下駄', icon: '👞', rarity: Rarity.N),
  GachaItem(name: '木札のお守り', icon: '🪵', rarity: Rarity.N),
];

// -----------------------------------------------------------------------------
// メイン画面
// -----------------------------------------------------------------------------

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  final Random _random = Random();
  int _userCoins = 3000;

  // ガチャ抽せんロジック
  GachaItem _drawSingleItem() {
    final randVal = _random.nextDouble() * 100;
    Rarity selectedRarity;

    if (randVal < 3) {
      selectedRarity = Rarity.SSR;
    } else if (randVal < 15) {
      selectedRarity = Rarity.SR;
    } else if (randVal < 40) {
      selectedRarity = Rarity.R;
    } else {
      selectedRarity = Rarity.N;
    }

    final filteredPool = _itemPool.where((item) => item.rarity == selectedRarity).toList();
    return filteredPool[_random.nextInt(filteredPool.length)];
  }

  // ガチャ実行
  void _pullGacha(int count, int cost) {
    if (_userCoins < cost) {
      _showCoinShortageDialog();
      return;
    }

    setState(() {
      _userCoins -= cost;
    });

    List<GachaItem> results = [];
    for (int i = 0; i < count; i++) {
      results.add(_drawSingleItem());
    }

    Rarity highestRarity = results.map((e) => e.rarity).reduce((a, b) => a.index > b.index ? a : b);
    CustomGachaTheme theme;
    if (highestRarity == Rarity.SSR) {
      theme = CustomGachaTheme.hanabiFestival;
    } else if (highestRarity == Rarity.SR) {
      theme = CustomGachaTheme.samuraiSlash;
    } else {
      theme = CustomGachaTheme.sakuraShrine;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return MasterGachaOverlay(
          theme: theme,
          results: results,
        );
      },
    );
  }

  void _addCoins() {
    setState(() => _userCoins += 1000);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('1000コインを獲得しました！', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFC2185B),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showCoinShortageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
        ),
        title: const Text('コイン不足', style: TextStyle(color: Color(0xFF4A1525), fontWeight: FontWeight.bold)),
        content: const Text('ガチャを引くためのコインが不足しています。', style: TextStyle(color: Color(0xFF6B2D3E))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる', style: TextStyle(color: Color(0xFF880E4F))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _addCoins();
            },
            child: const Text('コイン補充'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 最背景グラデーション ＆ 桜の花びら背景描画
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFF0F5), // 淡い桜雪色
                    Color(0xFFFCE4EC), // さくらピンク
                    Color(0xFFF8BBD0), // 華やかピンク
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: CustomPaint(
                painter: _SakuraBackgroundPainter(),
              ),
            ),
          ),

          // 2. メインUIコンテンツ
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // コイン保有数表示ヘッダー（明るい桜風）
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              '$_userCoins',
                              style: const TextStyle(
                                color: Color(0xFF880E4F),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _addCoins,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE91E63).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 16, color: Colors.white),
                                Text(
                                  '補充',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const Spacer(),

                  // タイトル（和風深紅文字）
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFC2185B).withOpacity(0.3)),
                    ),
                    child: const Text(
                      '🌸 神幻和風ガチャ 🌸',
                      style: TextStyle(
                        color: Color(0xFF880E4F),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '最高レアリティに応じて演出が豪華に昇格！\n【SSR 3% / SR 12% / R 25% / N 60%】',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF4A1525).withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ガチャボタン群
                  Row(
                    children: [
                      Expanded(
                        child: _buildJapaneseGachaButton(
                          title: '1回ガチャ',
                          subtitle: '100 コイン',
                          baseColors: [const Color(0xFF4A2E35), const Color(0xFF2C1820)], // 桜紫墨
                          accentColor: const Color(0xFFFFB7C5),
                          seed: 101,
                          onTap: () => _pullGacha(1, 100),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildJapaneseGachaButton(
                          title: '10連ガチャ',
                          subtitle: '1000 コイン',
                          baseColors: [const Color(0xFFAD1457), const Color(0xFF6A1B4D)], // 鮮やか華桜紅
                          accentColor: const Color(0xFFFFD700),
                          isSpecial: true,
                          seed: 202,
                          onTap: () => _pullGacha(10, 1000),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 和風デザインガチャボタン Widget（不要な非表示テキスト削除済み）
  // ---------------------------------------------------------------------------
  Widget _buildJapaneseGachaButton({
    required String title,
    required String subtitle,
    required List<Color> baseColors,
    required Color accentColor,
    required int seed,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isSpecial ? const Color(0xFFE91E63) : baseColors.first).withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _JapaneseButtonPainter(
              baseColors: baseColors,
              accentColor: accentColor,
              isSpecial: isSpecial,
              seed: seed,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFFFFF8E7),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 背景の桜描画 CustomPainter（舞い散る桜の花びら＆雲文様）
// -----------------------------------------------------------------------------
class _SakuraBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);

    // 1. 散り桜の花びらを描画
    final petalPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 45; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final scale = 0.6 + rand.nextDouble() * 0.8;
      final opacity = 0.2 + rand.nextDouble() * 0.4;
      final angle = rand.nextDouble() * pi * 2;

      petalPaint.color = Color.lerp(
        const Color(0xFFFFB7C5),
        const Color(0xFFF48FB1),
        rand.nextDouble(),
      )!.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.scale(scale);

      final path = Path();
      path.moveTo(0, -8);
      path.cubicTo(6, -12, 8, -2, 0, 8);
      path.cubicTo(-8, -2, -6, -12, 0, -8);
      canvas.drawPath(path, petalPaint);

      canvas.restore();
    }

    // 2. うっすら浮かぶ和風雲文様
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.15), 60, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.12), 45, cloudPaint);

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.75), 70, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.78), 50, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// ボタン和柄描画 CustomPainter (漆・市松模様・金箔散らし・和風二重枠)
// -----------------------------------------------------------------------------
class _JapaneseButtonPainter extends CustomPainter {
  final List<Color> baseColors;
  final Color accentColor;
  final bool isSpecial;
  final int seed;

  _JapaneseButtonPainter({
    required this.baseColors,
    required this.accentColor,
    required this.isSpecial,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: baseColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(rrect, bgPaint);

    canvas.save();
    canvas.clipRRect(rrect);

    final checkerPaint = Paint()..color = Colors.white.withOpacity(0.04);
    const tileSize = 12.0;
    for (double x = 0; x < size.width; x += tileSize) {
      for (double y = 0; y < size.height; y += tileSize) {
        if (((x / tileSize).floor() + (y / tileSize).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), checkerPaint);
        }
      }
    }

    final rand = Random(seed);
    final goldPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 22; i++) {
      final px = rand.nextDouble() * size.width;
      final py = rand.nextDouble() * size.height;
      final pSize = 1.2 + rand.nextDouble() * 2.5;
      final opacity = 0.2 + rand.nextDouble() * 0.5;

      goldPaint.color = isSpecial
          ? const Color(0xFFFFD700).withOpacity(opacity)
          : accentColor.withOpacity(opacity);

      final path = Path()
        ..moveTo(px, py)
        ..lineTo(px + pSize, py - pSize * 0.5)
        ..lineTo(px + pSize * 1.5, py + pSize)
        ..lineTo(px - pSize * 0.3, py + pSize * 1.2)
        ..close();

      canvas.drawPath(path, goldPaint);
    }

    canvas.restore();

    final outerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSpecial ? 2.0 : 1.2
      ..shader = LinearGradient(
        colors: isSpecial
            ? [const Color(0xFFFFE082), const Color(0xFFFFD700), const Color(0xFFB8860B), const Color(0xFFFFE082)]
            : [accentColor.withOpacity(0.8), accentColor.withOpacity(0.3), accentColor.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(rrect, outerBorderPaint);

    final innerRRect = RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(12));
    final innerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = (isSpecial ? const Color(0xFFFFD700) : accentColor).withOpacity(0.35);

    canvas.drawRRect(innerRRect, innerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _JapaneseButtonPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// マスター演出オーバーレイ
// -----------------------------------------------------------------------------

class MasterGachaOverlay extends StatefulWidget {
  final CustomGachaTheme theme;
  final List<GachaItem> results;

  const MasterGachaOverlay({
    super.key,
    required this.theme,
    required this.results,
  });

  @override
  State<MasterGachaOverlay> createState() => _MasterGachaOverlayState();
}

class _MasterGachaOverlayState extends State<MasterGachaOverlay> with TickerProviderStateMixin {
  late AnimationController _timelineController;
  late Animation<double> _climaxAnim;
  late Animation<double> _flashAnim;

  bool _showResult = false;

  @override
  void initState() {
    super.initState();

    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _climaxAnim = CurvedAnimation(parent: _timelineController, curve: const Interval(0.65, 0.85, curve: Curves.elasticOut));
    _flashAnim = CurvedAnimation(parent: _timelineController, curve: const Interval(0.72, 0.90, curve: Curves.easeInOut));

    _timelineController.addListener(() {
      if (_timelineController.value >= 0.65 && _timelineController.value < 0.68) {
        HapticFeedback.heavyImpact();
      }
    });

    _timelineController.forward().then((_) {
      if (mounted) setState(() => _showResult = true);
    });
  }

  void _skipAnimation() {
    if (_showResult) return;
    _timelineController.stop();
    setState(() {
      _showResult = true;
    });
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  Offset _getShakeOffset() {
    final progress = _timelineController.value;
    if (progress < 0.62 || progress > 0.85) return Offset.zero;

    final intensity = (1.0 - (progress - 0.62) / 0.23) * 18.0;
    final rand = Random((progress * 1000).toInt());
    return Offset((rand.nextDouble() - 0.5) * intensity, (rand.nextDouble() - 0.5) * intensity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skipAnimation,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _timelineController,
          builder: (context, child) {
            return Transform.translate(
              offset: _getShakeOffset(),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _JapaneseGachaPainter(
                        theme: widget.theme,
                        progress: _timelineController.value,
                      ),
                    ),
                  ),

                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _showResult ? _buildResultView() : _buildThemeStage(),
                    ),
                  ),

                  if (!_showResult && _flashAnim.value > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: _getThemeColor().withOpacity(
                            (sin(_flashAnim.value * pi) * 0.95).clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                    ),

                  if (!_showResult)
                    const Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Text(
                        '画面タップでスキップ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.5),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getThemeColor() {
    switch (widget.theme) {
      case CustomGachaTheme.sakuraShrine: return const Color(0xFFFFB7C5);
      case CustomGachaTheme.samuraiSlash: return const Color(0xFFE53935);
      case CustomGachaTheme.hanabiFestival: return const Color(0xFFFFD54F);
    }
  }

  Widget _buildThemeStage() {
    switch (widget.theme) {
      case CustomGachaTheme.sakuraShrine:
        return _buildStageContent('⛩️', '〜 桜吹雪・通常引き 〜', const Color(0xFFFFB7C5));
      case CustomGachaTheme.samuraiSlash:
        return _buildStageContent('⚔️', '〜 秘伝一閃・SR昇格 〜', const Color(0xFFE53935));
      case CustomGachaTheme.hanabiFestival:
        return _buildStageContent('🎆', '〜 大輪極彩・SSR確定 〜', const Color(0xFFFFD54F));
    }
  }

  Widget _buildStageContent(String icon, String title, Color color) {
    final scale = 1.0 + _climaxAnim.value * 0.4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: scale,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2C1820),
              border: Border.all(color: color, width: 3),
              boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 40)],
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 72))),
          ),
        ),
        const SizedBox(height: 32),
        Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // リザルト画面
  // ---------------------------------------------------------------------------
  Widget _buildResultView() {
    final isTenPull = widget.results.length > 1;

    return Container(
      width: isTenPull ? 350 : 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE91E63), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.3),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '獲得結果',
            style: TextStyle(color: Color(0xFF4A1525), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 16),

          if (isTenPull)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.results.length,
              itemBuilder: (context, index) {
                final item = widget.results[index];
                return _buildGridItemCard(item);
              },
            )
          else
            _buildSingleResultCard(widget.results.first),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('獲得する', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSingleResultCard(GachaItem item) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: item.rarity.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.rarity.label,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Text(item.icon, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          item.name,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF3D1E28), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGridItemCard(GachaItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.rarity.color, width: 1.5),
        boxShadow: item.rarity == Rarity.SSR
            ? [BoxShadow(color: item.rarity.color.withOpacity(0.6), blurRadius: 8)]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: item.rarity.color, borderRadius: BorderRadius.circular(6)),
            child: Text(
              item.rarity.label,
              style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(item.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF3D1E28), fontSize: 8, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// パーティクル描画 (CustomPainter)
// -----------------------------------------------------------------------------

class _JapaneseGachaPainter extends CustomPainter {
  final CustomGachaTheme theme;
  final double progress;

  _JapaneseGachaPainter({required this.theme, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    switch (theme) {
      case CustomGachaTheme.sakuraShrine:
        _drawSakuraPetals(canvas, size);
        break;
      case CustomGachaTheme.samuraiSlash:
        _drawSamuraiSlashes(canvas, center, size);
        break;
      case CustomGachaTheme.hanabiFestival:
        _drawHanabiBurst(canvas, center, size);
        break;
    }
  }

  void _drawSakuraPetals(Canvas canvas, Size size) {
    final rand = Random(77);
    final paint = Paint()..color = const Color(0xFFFFB7C5);

    for (int i = 0; i < 35; i++) {
      final xBase = rand.nextDouble() * size.width;
      final speed = 150 + rand.nextDouble() * 250;
      final y = (progress * speed + rand.nextDouble() * size.height) % size.height;
      final x = xBase + sin(progress * 10 + i) * 20;

      paint.color = const Color(0xFFFFB7C5).withOpacity(rand.nextDouble() * 0.8 + 0.2);
      canvas.drawCircle(Offset(x, y), 3.0 + rand.nextDouble() * 3.0, paint);
    }
  }

  void _drawSamuraiSlashes(Canvas canvas, Offset center, Size size) {
    if (progress < 0.55) return;
    final burstProgress = (progress - 0.55) / 0.45;
    final rand = Random(123);

    for (int i = 0; i < 8; i++) {
      final angle = (i * (pi / 4)) + (rand.nextDouble() * 0.2);
      final length = burstProgress * size.width * 0.9;

      final start = center + Offset(cos(angle) * 10, sin(angle) * 10);
      final end = center + Offset(cos(angle) * length, sin(angle) * length);

      final paint = Paint()
        ..color = (i % 2 == 0 ? const Color(0xFFE53935) : Colors.white).withOpacity((1.0 - burstProgress).clamp(0.0, 1.0))
        ..strokeWidth = 2.0 + rand.nextDouble() * 4.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, end, paint);
    }
  }

  void _drawHanabiBurst(Canvas canvas, Offset center, Size size) {
    if (progress < 0.60) return;
    final burstProgress = (progress - 0.60) / 0.40;
    final rand = Random(555);

    const particleCount = 24;
    final radius = burstProgress * size.width * 0.6;

    for (int i = 0; i < particleCount; i++) {
      final angle = (pi * 2 / particleCount) * i;
      final pCenter = center + Offset(cos(angle) * radius, sin(angle) * radius);

      final paint = Paint()
        ..color = HSLColor.fromAHSL((1.0 - burstProgress).clamp(0.0, 1.0), (i * 15) % 360, 1.0, 0.6).toColor();

      canvas.drawCircle(pCenter, 4.0 + rand.nextDouble() * 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _JapaneseGachaPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}