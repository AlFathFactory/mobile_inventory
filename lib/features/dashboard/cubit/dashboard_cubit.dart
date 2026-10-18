import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/repositories/data_result.dart';
import '../data/models/dashboard_data.dart';
import '../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required DashboardRepository repository})
    : _repository = repository,
      super(const DashboardState.initial());

  final DashboardRepository _repository;
  int _requestRevision = 0;

  DashboardData? get data => state.data;

  Future<void> load({Duration delay = Duration.zero}) async {
    final revision = ++_requestRevision;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (isClosed || revision != _requestRevision) return;

    emit(DashboardState.loading(previousData: state.data));
    final result = await _repository.fetchDashboard();
    if (isClosed || revision != _requestRevision) return;

    switch (result) {
      case DataSuccess(:final value):
        emit(DashboardState.success(value));
      case DataError(:final failure):
        emit(DashboardState.failure(failure, previousData: state.data));
    }
  }

  Future<void> reload() => load();

  Future<void> retry() => load();

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _requestRevision++;
    return super.close();
  }
}
