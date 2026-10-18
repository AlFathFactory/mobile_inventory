import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../features/inventory/cubit/inventory_cubit.dart';
import '../../features/inventory/cubit/inventory_state.dart';
import '../widgets/app_bottom_navigation.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.inventoryCubit,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final InventoryCubit inventoryCubit;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<InventoryCubit, InventoryState>(
            bloc: inventoryCubit,
            buildWhen: (previous, current) =>
                previous.isLoading != current.isLoading,
            builder: (context, state) =>
                Skeletonizer(enabled: state.isLoading, child: navigationShell),
          ),
        ),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
