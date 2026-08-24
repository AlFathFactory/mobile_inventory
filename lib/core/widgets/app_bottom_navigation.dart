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
    return NavigationBar(
      height: 70,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentSoft,
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
          icon: _NavigationAssetIcon('assets/image/bnv/notification.png'),
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
