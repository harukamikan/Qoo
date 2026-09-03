import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// 5タブ共通のボトムナビゲーションバー。
/// 「地図・ガチャ・投稿・保存・プロフィール」に対応する。
class JamBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const JamBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    NavItemData(
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      label: '地図',
    ),
    NavItemData(
      icon: Icons.casino_outlined,
      activeIcon: Icons.casino,
      label: 'ガチャ',
    ),
    NavItemData(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: '投稿',
    ),
    NavItemData(
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
      label: '保存写真',
    ),
    NavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'プロフィール',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final active = index == currentIndex;
              final color = active ? AppColors.navy : AppColors.textGrey;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (active)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
