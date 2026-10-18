import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../../../core/data/repositories/page.dart';
import '../data/models/movement_history_query.dart';
import '../data/repositories/movement_history_repository.dart';
import '../model/inventory_item.dart';
import '../model/inventory_movement.dart';

class MovementHistoryCubit
    extends Cubit<DataLoadState<List<InventoryMovement>>> {
  MovementHistoryCubit({
    required MovementHistoryRepository repository,
    required InventoryItem item,
    this.pageSize = 20,
  }) : _repository = repository,
       _itemRouteId = item.routeId,
       super(const DataLoadState.initial());

  final MovementHistoryRepository _repository;
  final String _itemRouteId;
  final int pageSize;
  String? _nextCursor;
  bool _isLoadingMore = false;
  int _requestRevision = 0;

  bool get hasMore => _nextCursor != null;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> load() async {
    final revision = ++_requestRevision;
    _nextCursor = null;
    _isLoadingMore = false;
    emit(DataLoadState.loading(previousData: state.data));
    final result = await _fetch();
    if (isClosed || revision != _requestRevision) return;
    switch (result) {
      case DataSuccess(:final value):
        _nextCursor = value.nextCursor;
        emit(
          value.items.isEmpty
              ? const DataLoadState.empty()
              : DataLoadState.success(value.items),
        );
      case DataError(:final failure):
        emit(DataLoadState.failed(failure, previousData: state.data));
    }
  }

  Future<void> loadNextPage() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore) return;
    final revision = _requestRevision;
    _isLoadingMore = true;
    emit(DataLoadState.loading(previousData: state.data));
    final result = await _fetch(cursor: cursor);
    if (isClosed || revision != _requestRevision) return;
    switch (result) {
      case DataSuccess(:final value):
        final known = (state.data ?? const <InventoryMovement>[])
            .map((item) => item.id)
            .toSet();
        final items = [
          ...state.data ?? const <InventoryMovement>[],
          ...value.items.where((item) => known.add(item.id)),
        ];
        _nextCursor = value.nextCursor;
        emit(
          items.isEmpty
              ? const DataLoadState.empty()
              : DataLoadState.success(items),
        );
      case DataError(:final failure):
        emit(DataLoadState.failed(failure, previousData: state.data));
    }
    _isLoadingMore = false;
  }

  Future<DataResult<PageResult<InventoryMovement>>> _fetch({String? cursor}) =>
      _repository.fetchMovements(
        MovementHistoryQuery(
          itemRouteId: _itemRouteId,
          page: PageRequest(limit: pageSize, cursor: cursor),
        ),
      );

  @override
  Future<void> close() {
    _requestRevision++;
    return super.close();
  }
}
