import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../../../core/data/repositories/load_state.dart';
import '../data/models/dashboard_data.dart';
import '../data/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({required DashboardRepository repository})
    : _repository = repository;

  final DashboardRepository _repository;
  DataLoadState<DashboardData> _state = const DataLoadState.initial();
  int _requestRevision = 0;

  DataLoadState<DashboardData> get state => _state;
  DashboardData? get data => _state.data;
  bool get isLoading => _state.isLoading;

  Future<void> load({Duration delay = Duration.zero}) async {
    final revision = ++_requestRevision;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (revision != _requestRevision) return;
    _state = DataLoadState.loading(previousData: _state.data);
    notifyListeners();

    final result = await _repository.fetchDashboard();
    if (revision != _requestRevision) return;

    _state = switch (result) {
      DataSuccess(:final value) => DataLoadState.success(value),
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
