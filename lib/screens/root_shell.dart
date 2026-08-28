// import 'package:flutter/material.dart';

// import '../widgets/bottom_nav_bar.dart';
// import 'create_review/create_review_screen.dart';
// import 'map/map_screen.dart';
// import 'profile/profile_screen.dart';
// import 'saved/saved_places_screen.dart';
// import 'gacha/gacha_screen.dart';

// /// アプリのルートとなるシェル。ボトムナビゲーションで
// /// 「地図・検索・投稿・保存・プロフィール」の5タブを切り替える。
// ///
// /// 「投稿」タブだけは常設ページではなく、タップ時に
// /// 口コミ作成画面をモーダル的にプッシュする（他アプリの「＋」タブと同様の挙動）。
// class RootShell extends StatefulWidget {
//   const RootShell({super.key});

//   @override
//   State<RootShell> createState() => _RootShellState();
// }

// class _RootShellState extends State<RootShell> {
//   int _currentIndex = 0;

//   void _onNavTap(int index) {
//     if (index == 2) {
//       Navigator.of(context)
//           .push(MaterialPageRoute(builder: (_) => const CreateReviewScreen()))
//           .then((_) => setState(() {}));
//       return;
//     }
//     setState(() => _currentIndex = index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pages = [
//       MapScreen(onSwitchTab: _onNavTap),
//       const GachaScreen(),
//       const SizedBox.shrink(), // 「投稿」のプッシュ遷移のため未使用
//       const SavedPlacesScreen(),
//       const ProfileScreen(),
//     ];

//     return Scaffold(
//       body: IndexedStack(index: _currentIndex, children: pages),
//       bottomNavigationBar: JamBottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: _onNavTap,
//       ),
//     );
//   }
// }
