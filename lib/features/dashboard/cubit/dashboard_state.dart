import 'package:flutter/foundation.dart';

import '../../../core/data/repositories/data_result.dart';
import '../data/models/dashboard_data.dart';

enum DashboardStatus { initial, loading, success, failure }

@immutable
class DashboardState {
  const DashboardState._({required this.status, this.data, this.failure});

  const DashboardState.initial() : this._(status: DashboardStatus.initial);

  const DashboardState.loading({DashboardData? previousData})
    : this._(status: DashboardStatus.loading, data: previousData);

  const DashboardState.success(DashboardData data)
    : this._(status: DashboardStatus.success, data: data);

  const DashboardState.failure(
    DataFailure failure, {
    DashboardData? previousData,
  }) : this._(
         status: DashboardStatus.failure,
         data: previousData,
         failure: failure,
       );

  final DashboardStatus status;
  final DashboardData? data;
  final DataFailure? failure;

  bool get isLoading => status == DashboardStatus.loading;
  bool get hasData => data != null;
}
