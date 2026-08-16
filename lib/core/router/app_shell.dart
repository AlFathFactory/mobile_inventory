import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../features/inventory/controller/inventory_controller.dart';
import '../widgets/app_bottom_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.loadingController,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final InventoryController loadingController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: loadingController,
          child: navigationShell,
          builder: (context, child) =>
              Skeletonizer(enabled: loadingController.isLoading, child: child!),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
