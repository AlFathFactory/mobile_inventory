import 'package:flutter/foundation.dart';

import 'data_result.dart';

enum DataLoadStatus { initial, loading, success, empty, failure }

/// Controller-facing state for repositories that will load asynchronously.
/// Existing controllers can adopt this incrementally without changing views.
@immutable
class DataLoadState<T> {
  const DataLoadState._({required this.status, this.data, this.failure});

  const DataLoadState.initial() : this._(status: DataLoadStatus.initial);

  const DataLoadState.loading({T? previousData})
    : this._(status: DataLoadStatus.loading, data: previousData);

  const DataLoadState.success(T value)
    : this._(status: DataLoadStatus.success, data: value);

  const DataLoadState.empty() : this._(status: DataLoadStatus.empty);

  const DataLoadState.failed(DataFailure error, {T? previousData})
    : this._(
        status: DataLoadStatus.failure,
        data: previousData,
        failure: error,
      );

  final DataLoadStatus status;
  final T? data;
  final DataFailure? failure;

  bool get isLoading => status == DataLoadStatus.loading;
  bool get hasData => data != null;
}
