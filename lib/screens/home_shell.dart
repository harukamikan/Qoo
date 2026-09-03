import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/ui_translations.dart';
import 'gacha/gacha_item.dart';
import 'map_screen.dart';
import 'gacha/gacha_screen.dart';
import 'gacha/coin_manager.dart';
import 'gacha/inventory_manager.dart';
import 'gacha/collection_screen.dart';
import 'collection/collection_screen.dart';
import '../widgets/post_tips_dialog.dart';
import '../widgets/photo_capture_sheet.dart';
import '../widgets/friend_management_panel.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:image_picker/image_picker.dart';
import '../services/photo_upload_service.dart';
import '../services/user_repository.dart';
import '../models/user_profile.dart';
import '../widgets/location_picker_sheet.dart';
import 'friend_photo_feed_screen.dart';
import 'profile/language_region_screen.dart';
import 'admin/store_approval_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MapPage(),
      const GachaScreen(),
      const PostSelectionPage(),
      const SavedPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) {
          setState(() {
            index = value;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            activeIcon: const Icon(Icons.map_rounded),
            label: UiTranslations.t('地図'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.casino_outlined),
            activeIcon: const Icon(Icons.casino),
            label: UiTranslations.t('ガチャ'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.rate_review_outlined),
            activeIcon: const Icon(Icons.rate_review),
            label: UiTranslations.t('口コミ'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border),
            activeIcon: const Icon(Icons.bookmark),
            label: UiTranslations.t('保存'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: UiTranslations.t('プロフィール'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 共通ヘッダー
// ============================================================

class PageHeader extends StatelessWidget {
  final String title;

  const PageHeader(
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 検索ページ
// ============================================================

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '検索',
        style: TextStyle(
          fontSize: 32,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class PostSelectionPage extends StatefulWidget {
  const PostSelectionPage({super.key});

  @override
  State<PostSelectionPage> createState() => _PostSelectionPageState();
}

class _PostSelectionPageState extends State<PostSelectionPage> {
  ll.LatLng _selectedPosition = const ll.LatLng(33.5902, 130.4017);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(UiTranslations.t('投稿する')),
              const SizedBox(height: 32),
              _PostCard(
                icon: Icons.chat_bubble_outline,
                title: UiTranslations.t('Tips投稿'),
                description: UiTranslations.t('旅先で役立つ情報や困りごとをシェアしよう'),
                onTap: () => showLocationPickerSheet(
                  context,
                  initialPosition: _selectedPosition,
                  onLocationSelected: (position, placeName) {
                    setState(() => _selectedPosition = position);
                    showPostTipsDialog(
                      context,
                      targetPosition: position,
                      currentCenter: position,
                      onPosted: (_) {},
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _PostCard(
                icon: Icons.photo_camera_outlined,
                title: UiTranslations.t('旅行写真'),
                description: UiTranslations.t('旅の思い出を写真で残そう'),
                onTap: () => showLocationPickerSheet(
                  context,
                  initialPosition: _selectedPosition,
                  onLocationSelected: (position, placeName) {
                    setState(() => _selectedPosition = position);
                    showPhotoCaptureSheet(
                      context,
                      onTakePhoto: (visibility) async {
                        final picker = ImagePicker();
                        final photo =
                            await picker.pickImage(source: ImageSource.camera);
                        if (photo == null) return;
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(UiTranslations.t('アップロード中...'))),
                        );
                        final result = await PhotoUploadService.uploadAndSave(
                          bytes: await photo.readAsBytes(),
                          filename: photo.name,
                          position: position,
                          visibility: visibility,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result != null
                                  ? UiTranslations.t('写真を投稿しました')
                                  : UiTranslations.t('アップロードに失敗しました'))),
                        );
                      },
                      onPickFromGallery: (visibility) async {
                        final picker = ImagePicker();
                        final photo =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (photo == null) return;
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(UiTranslations.t('アップロード中...'))),
                        );
                        final result = await PhotoUploadService.uploadAndSave(
                          bytes: await photo.readAsBytes(),
                          filename: photo.name,
                          position: position,
                          visibility: visibility,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(result != null
                                  ? UiTranslations.t('写真を投稿しました')
                                  : UiTranslations.t('アップロードに失敗しました'))),
                        );
                      },
                    );
                  },
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

// ============================================================
// 口コミ投稿ページ
// ============================================================

class ReviewFormPage extends StatefulWidget {
  const ReviewFormPage({super.key});

  @override
  State<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<ReviewFormPage> {
  final TextEditingController controller = TextEditingController();

  String category = '食事';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeader('口コミを作成'),
        const SizedBox(height: 34),
        const Text(
          'カテゴリー',
          style: TextStyle(
            fontSize: 30,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['食事', '温泉', '文化', '交通']
              .map(
                (x) => ChoiceChip(
                  label: Text(x),
                  selected: category == x,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: category == x ? Colors.white : AppColors.textGrey,
                  ),
                  onSelected: (_) {
                    setState(() {
                      category = x;
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 34),
        const Text(
          'あなたの口コミ',
          style: TextStyle(
            fontSize: 30,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: '体験をシェアしましょう…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: () {
            final coinData = CoinDataProvider.of(context);

            // 口コミ投稿で +30コイン
            coinData.addCoins(30);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '口コミを投稿しました！ +30コイン獲得🎉',
                ),
              ),
            );

            controller.clear();
          },
          icon: const Icon(Icons.send),
          label: const Text('口コミ投稿'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(60),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 保存した場所
// ============================================================

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const FriendPhotoFeedScreen();
  }
}

// ============================================================
// プロフィール
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    // ★重要
    // ここではInventoryData()を新しく作らない。
    // main.dartから提供されているInventoryDataを取得する。
    final inventoryData = InventoryProvider.of(context);

    return AnimatedBuilder(
      animation: inventoryData,
      builder: (context, _) {
        final frame = inventoryData.getEquippedItem(
          GachaItemType.profileFrame,
        );

        final avatar = inventoryData.getEquippedItem(
          GachaItemType.avatarSkin,
        );

        final badge = inventoryData.getEquippedItem(
          GachaItemType.badge,
        );

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PageHeader(UiTranslations.t('プロフィール')),

            const SizedBox(height: 8),

            Center(
              child: Column(
                children: [
                  // ------------------------------------------
                  // プロフィールアイコン
                  // ------------------------------------------
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: frame != null
                            ? frame.rarity.color
                            : AppColors.primary,
                        width: frame != null ? 4 : 2,
                      ),
                      boxShadow: frame != null
                          ? [
                              BoxShadow(
                                color: frame.rarity.color.withOpacity(0.5),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        avatar?.iconOrAsset ?? '🙂',
                        style: const TextStyle(
                          fontSize: 48,
                        ),
                      ),
                    ),
                  ),

                  // ------------------------------------------
                  // 装備中フレーム名
                  // ------------------------------------------
                  if (frame != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      frame.name,
                      style: TextStyle(
                        color: frame.rarity.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  // ------------------------------------------
                  // 装備中バッジ
                  // ------------------------------------------
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badge.rarity.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: badge.rarity.color,
                        ),
                      ),
                      child: Text(
                        '${badge.iconOrAsset} ${badge.name}',
                        style: TextStyle(
                          color: badge.rarity.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  // ------------------------------------------
                  // ログイン中のユーザー情報
                  // ------------------------------------------
                  if (user != null) ...[
                    const SizedBox(height: 16),
                    FutureBuilder<UserProfile?>(
                      future: UserRepository.instance.fetchProfile(user.uid),
                      builder: (context, snap) {
                        final profile = snap.data;
                        if (profile == null) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final name = profile.name.isNotEmpty
                            ? profile.name
                            : user.displayName ?? UiTranslations.t('名前未設定');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FriendManagementPanel(profile: profile),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ------------------------------------------
            // コレクション
            // ------------------------------------------
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CollectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.style),
              label: Text(UiTranslations.t('コレクションを見る')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
            ),

                       const SizedBox(height: 16),
            // ------------------------------------------
            // 地域コレクション
            // ------------------------------------------
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TravelCollectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('地域コレクション'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StoreApprovalScreen(),
      ),
    );
  },
  icon: const Icon(Icons.admin_panel_settings),
  label: const Text('店舗承認（Admin）'),
  style: OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    foregroundColor: Colors.orange,
    side: const BorderSide(color: Colors.orange),
  ),
),
const SizedBox(height: 16),

            // ------------------------------------------
            // 言語と地域
            // ------------------------------------------
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguageRegionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.language),
              label: Text(UiTranslations.t('言語と地域')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ------------------------------------------
            // ログアウト
            // ------------------------------------------
            OutlinedButton.icon(
              onPressed: () => AuthService.instance.signOut(),
              icon: const Icon(Icons.logout),
              label: Text(UiTranslations.t('ログアウト')),
            ),
          ],
        );
      },
    );
  }
}
