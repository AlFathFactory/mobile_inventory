import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../data/repositories/item_details_repository.dart';
import '../model/inventory_item.dart';

class ItemDetailsCubit extends Cubit<DataLoadState<InventoryItem>> {
  ItemDetailsCubit({
    required ItemDetailsRepository repository,
    required String routeId,
  }) : _repository = repository,
       _routeId = routeId,
       super(const DataLoadState.initial());

  final ItemDetailsRepository _repository;
  final String _routeId;
  int _requestRevision = 0;

  Future<void> load() async {
    final revision = ++_requestRevision;
    emit(DataLoadState.loading(previousData: state.data));
    final result = await _repository.fetchItemByRouteId(_routeId);
    if (isClosed || revision != _requestRevision) return;
    emit(switch (result) {
      DataSuccess(value: final item?) => DataLoadState.success(item),
      DataSuccess() => const DataLoadState.empty(),
      DataError(:final failure) => DataLoadState.failed(
        failure,
        previousData: state.data,
      ),
    });
  }

  Future<void> retry() => load();

  @override
  Future<void> close() {
    _requestRevision++;
    return super.close();
  }
}
