import 'dart:async';

import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:el_fateh/features/dashboard/cubit/dashboard_state.dart';
import 'package:el_fateh/features/dashboard/data/models/dashboard_data.dart';
import 'package:el_fateh/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:el_fateh/features/dashboard/data/repositories/preview_dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardCubit', () {
    test(
      'starts initial and loads from the preview repository fallback',
      () async {
        final cubit = DashboardCubit(
          repository: const PreviewDashboardRepository(),
        );
        addTearDown(cubit.close);

        expect(cubit.state.status, DashboardStatus.initial);
        await cubit.load();

        expect(cubit.state.status, DashboardStatus.success);
        expect(cubit.state.data?.metrics, isNotEmpty);
      },
    );

    test(
      'retains the latest result when an older request completes late',
      () async {
        final firstRequest = Completer<DataResult<DashboardData>>();
        var requests = 0;
        final cubit = DashboardCubit(
          repository: _FakeDashboardRepository(() {
            requests++;
            return requests == 1
                ? firstRequest.future
                : const PreviewDashboardRepository().fetchDashboard();
          }),
        );
        addTearDown(cubit.close);

        unawaited(cubit.load());
        await Future<void>.delayed(Duration.zero);
        await cubit.reload();
        firstRequest.complete(
          const DataError(
            DataFailure(kind: DataFailureKind.server, message: 'Server error.'),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.status, DashboardStatus.success);
        expect(cubit.state.failure, isNull);
      },
    );

    test('cancels a delayed initial request when reloaded', () async {
      final repository = _FakeDashboardRepository(
        () => const PreviewDashboardRepository().fetchDashboard(),
      );
      final cubit = DashboardCubit(repository: repository);
      addTearDown(cubit.close);

      unawaited(cubit.load(delay: const Duration(milliseconds: 20)));
      await cubit.reload();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.calls, 1);
      expect(cubit.state.status, DashboardStatus.success);
    });
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository(this._fetch);

  final FutureOr<DataResult<DashboardData>> Function() _fetch;
  int calls = 0;

  @override
  Future<DataResult<DashboardData>> fetchDashboard({
    int attentionLimit = 10,
    int recentMovementLimit = 3,
  }) async {
    calls++;
    return _fetch();
  }
}
