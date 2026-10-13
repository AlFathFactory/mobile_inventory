import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../../../core/data/repositories/page.dart';
import '../data/models/movement_history_query.dart';
import '../data/repositories/movement_history_repository.dart';
import '../model/inventory_item.dart';
import '../model/inventory_movement.dart';

class MovementHistoryController extends ChangeNotifier {
  MovementHistoryController({
    required MovementHistoryRepository repository,
    required InventoryItem item,
    this.pageSize = 20,
  }) : _repository = repository,
       _itemRouteId = item.routeId;

  final MovementHistoryRepository _repository;
  final String _itemRouteId;
  final int pageSize;
  DataLoadState<List<InventoryMovement>> _state = const DataLoadState.initial();
  String? _nextCursor;
  bool _isLoadingMore = false;
  int _requestRevision = 0;

  DataLoadState<List<InventoryMovement>> get state => _state;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;

  Future<void> load() async {
    final revision = ++_requestRevision;
    _nextCursor = null;
    _isLoadingMore = false;
    _state = DataLoadState.loading(previousData: _state.data);
    notifyListeners();

    final result = await _repository.fetchMovements(
      MovementHistoryQuery(
        itemRouteId: _itemRouteId,
        page: PageRequest(limit: pageSize),
      ),
    );
    if (revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        _nextCursor = value.nextCursor;
        _state = value.items.isEmpty
            ? const DataLoadState.empty()
            : DataLoadState.success(value.items);
      case DataError(:final failure):
        _state = DataLoadState.failed(failure, previousData: _state.data);
    }
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore) return;

    final revision = _requestRevision;
    _isLoadingMore = true;
    notifyListeners();
    final result = await _repository.fetchMovements(
      MovementHistoryQuery(
        itemRouteId: _itemRouteId,
        page: PageRequest(limit: pageSize, cursor: cursor),
      ),
    );
    if (revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        final existing = _state.data ?? const <InventoryMovement>[];
        final knownIds = existing.map((movement) => movement.id).toSet();
        final combined = <InventoryMovement>[
          ...existing,
          ...value.items.where((movement) => knownIds.add(movement.id)),
        ];
        _nextCursor = value.nextCursor;
        _state = combined.isEmpty
            ? const DataLoadState.empty()
            : DataLoadState.success(combined);
      case DataError(:final failure):
        _state = DataLoadState.failed(failure, previousData: _state.data);
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _requestRevision++;
    super.dispose();
  }
}
