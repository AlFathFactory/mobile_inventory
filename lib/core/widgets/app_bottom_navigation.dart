import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accentVerySoft),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 68,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppColors.accentSoft,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: isSelected
                      ? AppColors.accentDark
                      : AppColors.neutral600,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                return IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.accent
                      : AppColors.neutral600,
                  size: 24,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  key: Key('nav-dashboard'),
                  icon: _NavigationAssetIcon('assets/image/bnv/home.png'),
                  selectedIcon: _NavigationAssetIcon(
                    'assets/image/bnv/home_selected.png',
                  ),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  key: Key('nav-inventory'),
                  icon: _NavigationAssetIcon('assets/image/bnv/box.png'),
                  selectedIcon: _NavigationAssetIcon(
                    'assets/image/bnv/box_selected.png',
                  ),
                  label: 'المخزون',
                ),
                NavigationDestination(
                  key: Key('nav-alerts'),
                  icon: _NavigationAssetIcon(
                    'assets/image/bnv/notification.png',
                  ),
                  selectedIcon: _NavigationAssetIcon(
                    'assets/image/bnv/notification_selected.png',
                  ),
                  label: 'التنبيهات',
                ),
                NavigationDestination(
                  key: Key('nav-reports'),
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'التقارير',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationAssetIcon extends StatelessWidget {
  const _NavigationAssetIcon(this.assetName);

  final String assetName;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetName,
      width: 24,
      height: 24,
      filterQuality: FilterQuality.high,
    );
  }
}
