import 'package:flutter/material.dart';
import 'package:masti_adda_app/constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(
        Icons.favorite_border_rounded,
        Icons.favorite_rounded,
        'Watchlist',
      ),
      _NavItem(
        Icons.smart_display_outlined,
        Icons.smart_display_rounded,
        'AI Reels',
      ),
      _NavItem(Icons.search_rounded, Icons.search_rounded, 'Discover'),
      _NavItem(
        Icons.movie_outlined,
        Icons.movie_rounded,
        'Micro Drama',
      ),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(
          top: BorderSide(
            color: AppColors.accentColor.withValues(alpha: 0.14),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = currentIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 1,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        size: 20,
                        color: isActive
                            ? AppColors.accentColor
                            : AppColors.secondaryTextColor,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: -0.2,
                            color: isActive
                                ? AppColors.accentColor
                                : AppColors.secondaryTextColor,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}
