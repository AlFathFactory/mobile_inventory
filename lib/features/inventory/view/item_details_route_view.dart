import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/data/repositories/load_state.dart';
import '../../../core/router/not_found_view.dart';
import '../../../core/widgets/app_components.dart';
import '../controller/item_details_controller.dart';
import '../controller/movement_history_controller.dart';
import '../data/repositories/item_details_repository.dart';
import '../data/repositories/movement_history_repository.dart';
import '../model/inventory_item.dart';
import 'item_details_view.dart';
import 'movement_history_view.dart';

class ItemDetailsRouteView extends StatefulWidget {
  const ItemDetailsRouteView({
    required this.routeId,
    required this.repository,
    required this.movementRepository,
    required this.onBack,
    super.key,
  });

  final String routeId;
  final ItemDetailsRepository repository;
  final MovementHistoryRepository movementRepository;
  final VoidCallback onBack;

  @override
  State<ItemDetailsRouteView> createState() => _ItemDetailsRouteViewState();
}

class _ItemDetailsRouteViewState extends State<ItemDetailsRouteView> {
  late final ItemDetailsController _controller = ItemDetailsController(
    repository: widget.repository,
    routeId: widget.routeId,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _ItemRouteState(
        state: _controller.state,
        onRetry: _controller.load,
        onSuccess: (item) => _ItemDetailsWithMovements(
          item: item,
          repository: widget.movementRepository,
          onBack: widget.onBack,
        ),
      ),
    );
  }
}

class ItemHistoryRouteView extends StatefulWidget {
  const ItemHistoryRouteView({
    required this.routeId,
    required this.repository,
    required this.movementRepository,
    required this.onBack,
    this.initialItem,
    super.key,
  });

  final String routeId;
  final ItemDetailsRepository repository;
  final MovementHistoryRepository movementRepository;
  final ValueChanged<InventoryItem> onBack;
  final InventoryItem? initialItem;

  @override
  State<ItemHistoryRouteView> createState() => _ItemHistoryRouteViewState();
}

class _ItemHistoryRouteViewState extends State<ItemHistoryRouteView> {
  ItemDetailsController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem == null) {
      _controller = ItemDetailsController(
        repository: widget.repository,
        routeId: widget.routeId,
      );
      unawaited(_controller!.load());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialItem = widget.initialItem;
    if (initialItem != null) {
      return _MovementHistoryLoader(
        item: initialItem,
        repository: widget.movementRepository,
        directRoute: false,
        onBack: () => widget.onBack(initialItem),
      );
    }

    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) => _ItemRouteState(
        state: _controller!.state,
        onRetry: _controller!.load,
        onSuccess: (item) => _MovementHistoryLoader(
          item: item,
          repository: widget.movementRepository,
          directRoute: true,
          onBack: () => widget.onBack(item),
        ),
      ),
    );
  }
}

class _ItemDetailsWithMovements extends StatefulWidget {
  const _ItemDetailsWithMovements({
    required this.item,
    required this.repository,
    required this.onBack,
  });

  final InventoryItem item;
  final MovementHistoryRepository repository;
  final VoidCallback onBack;

  @override
  State<_ItemDetailsWithMovements> createState() =>
      _ItemDetailsWithMovementsState();
}

class _ItemDetailsWithMovementsState extends State<_ItemDetailsWithMovements> {
  late final MovementHistoryController _controller = MovementHistoryController(
    repository: widget.repository,
    item: widget.item,
    pageSize: 2,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => ItemDetailsView(
        item: widget.item,
        movements: _controller.state.data ?? const [],
        onBack: widget.onBack,
      ),
    );
  }
}

class _MovementHistoryLoader extends StatefulWidget {
  const _MovementHistoryLoader({
    required this.item,
    required this.repository,
    required this.directRoute,
    required this.onBack,
  });

  final InventoryItem item;
  final MovementHistoryRepository repository;
  final bool directRoute;
  final VoidCallback onBack;

  @override
  State<_MovementHistoryLoader> createState() => _MovementHistoryLoaderState();
}

class _MovementHistoryLoaderState extends State<_MovementHistoryLoader> {
  late final MovementHistoryController _controller = MovementHistoryController(
    repository: widget.repository,
    item: widget.item,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 240 && _controller.hasMore) {
      unawaited(_controller.loadNextPage());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.directRoute && Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;
          final movements = state.data;
          if (movements != null || state.status == DataLoadStatus.empty) {
            return NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: MovementHistoryView(
                item: widget.item,
                movements: movements ?? const [],
                onBack: widget.onBack,
              ),
            );
          }
          if (state.status == DataLoadStatus.failure) {
            return _MovementFailureState(
              message: state.failure!.message,
              onRetry: _controller.load,
            );
          }
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        },
      ),
    );
  }
}

class _MovementFailureState extends StatelessWidget {
  const _MovementFailureState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الحركات')),
      body: SafeArea(
        child: ResponsivePage(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptyState(
                title: 'تعذر تحميل سجل الحركات',
                message: message,
                icon: Icons.cloud_off_outlined,
              ),
              TextButton.icon(
                key: const Key('retry-movement-history'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRouteState extends StatelessWidget {
  const _ItemRouteState({
    required this.state,
    required this.onRetry,
    required this.onSuccess,
  });

  final DataLoadState<InventoryItem> state;
  final Future<void> Function() onRetry;
  final Widget Function(InventoryItem item) onSuccess;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      DataLoadStatus.success => onSuccess(state.data!),
      DataLoadStatus.empty => const NotFoundView(),
      DataLoadStatus.failure => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الصنف')),
        body: SafeArea(
          child: ResponsivePage(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(
                  title: 'تعذر تحميل الصنف',
                  message: state.failure!.message,
                  icon: Icons.cloud_off_outlined,
                ),
                TextButton.icon(
                  key: const Key('retry-item-details'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
      DataLoadStatus.initial || DataLoadStatus.loading => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
    };
  }
}
