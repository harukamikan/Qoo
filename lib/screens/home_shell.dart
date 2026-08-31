import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'map_screen.dart'; // 本物のMapPage（Firestore連携・現在地・Tips投稿など）
import 'gacha/gacha_screen.dart';
import '../widgets/post_tips_dialog.dart';
import '../widgets/photo_capture_sheet.dart';
import 'package:latlong2/latlong.dart' as ll;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  // 地図タブだけ本物のMapPage、他の4つはAkitoさんが作ったモック画面（中身は今のところ空に近い）
  final pages = const [
    MapPage(),
    GachaScreen(),
    PostSelectionPage(),
    SavedPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: IndexedStack(index: index, children: pages)),
        bottomNavigationBar: NavigationBar(
          height: 82,
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: '地図'),
            NavigationDestination(
                icon: Icon(Icons.casino_outlined),
                selectedIcon: Icon(Icons.casino),
                label: 'ガチャ'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: '投稿'),
            NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark),
                label: '保存'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'プロフィール'),
          ],
        ),
      );
}

// --- 以下は仮のプレースホルダー。⑥〜⑪の担当者の実装がpushされ次第、差し替える想定 ---
// 参考: helpful_button.dart（評価）, search_bar_widget.dart（検索・カテゴリ）,
//       saved_spots_screen.dart（保存）, profile_screen.dart（マイページ）,
//       report_dialog.dart（通報） ※まだmainに未push

class PageHeader extends StatelessWidget {
  final String title;
  const PageHeader(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Row(children: [
          if (Navigator.canPop(context))
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back)),
          Text(title,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ]),
      );
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(
      child: Text('検索', style: TextStyle(fontSize: 32, color: AppColors.navy)));
}
class PostSelectionPage extends StatelessWidget {
  const PostSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader('投稿する'),
              const SizedBox(height: 32),
              _PostCard(
                icon: Icons.chat_bubble_outline,
                title: 'Tips投稿',
                description: '旅先で役立つ情報や困りごとをシェアしよう',
                onTap: () => showPostTipsDialog(
                  context,
                  targetPosition: const ll.LatLng(33.5902, 130.4017),
  currentCenter: const ll.LatLng(33.5902, 130.4017),
                  onPosted: (_) {},
                ),
              ),
              const SizedBox(height: 16),
              _PostCard(
                icon: Icons.photo_camera_outlined,
                title: '旅行写真',
                description: '旅の思い出を写真で残そう',
                onTap: () => showPhotoCaptureSheet(
                  context,
                  onTakePhoto: () {},
                  onPickFromGallery: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PostCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 48, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textGrey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewFormPage extends StatefulWidget {
  const ReviewFormPage({super.key});
  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  final controller = TextEditingController();
  String category = '食事';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeader('口コミを作成'),
          const SizedBox(height: 34),
          const Text('カテゴリー',
              style: TextStyle(fontSize: 30, color: AppColors.navy)),
          const SizedBox(height: 14),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['食事', '温泉', '文化', '交通']
                  .map((x) => ChoiceChip(
                      label: Text(x),
                      selected: category == x,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                          color: category == x
                              ? Colors.white
                              : AppColors.textGrey),
                      onSelected: (_) => setState(() => category = x)))
                  .toList()),
          const SizedBox(height: 34),
          const Text('あなたの口コミ',
              style: TextStyle(fontSize: 30, color: AppColors.navy)),
          const SizedBox(height: 12),
          TextField(
              controller: controller,
              maxLength: 500,
              maxLines: 7,
              decoration: InputDecoration(
                  hintText: '体験をシェアしましょう…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)))),
          const SizedBox(height: 30),
          FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('口コミを投稿しました'))),
              icon: const Icon(Icons.send),
              label: const Text('口コミを投稿'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(60))),
        ],
      );
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        children: const [
          PageHeader('保存した場所'),
          Padding(
            padding: EdgeInsets.all(24),
            child: Text('まだ保存した場所がありません',
                style: TextStyle(color: AppColors.textGrey)),
          ),
        ],
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          PageHeader('プロフィール'),
        ],
      );
}
