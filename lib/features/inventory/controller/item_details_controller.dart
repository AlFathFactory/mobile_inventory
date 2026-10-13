import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../data/repositories/item_details_repository.dart';
import '../model/inventory_item.dart';

class ItemDetailsController extends ChangeNotifier {
  ItemDetailsController({
    required ItemDetailsRepository repository,
    required String routeId,
  }) : _repository = repository,
       _routeId = routeId;

  final ItemDetailsRepository _repository;
  final String _routeId;
  DataLoadState<InventoryItem> _state = const DataLoadState.initial();
  int _requestRevision = 0;

  DataLoadState<InventoryItem> get state => _state;

  Future<void> load() async {
    final revision = ++_requestRevision;
    _state = DataLoadState.loading(previousData: _state.data);
    notifyListeners();

    final result = await _repository.fetchItemByRouteId(_routeId);
    if (revision != _requestRevision) return;

    _state = switch (result) {
      DataSuccess(value: final item?) => DataLoadState.success(item),
      DataSuccess() => const DataLoadState.empty(),
      DataError(:final failure) => DataLoadState.failed(
        failure,
        previousData: _state.data,
      ),
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _requestRevision++;
    super.dispose();
  }
}
