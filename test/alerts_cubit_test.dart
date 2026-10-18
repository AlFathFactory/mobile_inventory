import 'dart:async';

import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/features/alerts/cubit/alerts_cubit.dart';
import 'package:el_fateh/features/alerts/cubit/alerts_state.dart';
import 'package:el_fateh/features/alerts/data/models/alerts_data.dart';
import 'package:el_fateh/features/alerts/data/models/alerts_query.dart';
import 'package:el_fateh/features/alerts/data/repositories/alerts_repository.dart';
import 'package:el_fateh/features/alerts/data/repositories/preview_alerts_repository.dart';
import 'package:el_fateh/features/alerts/model/alert_summary.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlertsCubit', () {
    test(
      'starts initial and loads successfully through the repository',
      () async {
        final cubit = AlertsCubit(repository: const PreviewAlertsRepository());
        addTearDown(cubit.close);

        expect(cubit.state.status, AlertsStatus.initial);
        await cubit.load();

        expect(cubit.state.status, AlertsStatus.success);
        expect(cubit.state.items, hasLength(4));
        expect(cubit.state.failure, isNull);
      },
    );

    test('reports an empty result', () async {
      final cubit = AlertsCubit(
        repository: _FakeAlertsRepository((_) => _data(const [])),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, AlertsStatus.empty);
      expect(cubit.state.items, isEmpty);
    });

    test('reports failure and retry reloads successfully', () async {
      var shouldFail = true;
      final cubit = AlertsCubit(
        repository: _FakeAlertsRepository((_) {
          if (shouldFail) return _failure();
          return _data([PreviewData.alertItems.first]);
        }),
      );
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, AlertsStatus.failure);
      expect(cubit.state.failure?.kind, DataFailureKind.offline);

      shouldFail = false;
      await cubit.retry();
      expect(cubit.state.status, AlertsStatus.success);
      expect(cubit.state.failure, isNull);
    });

    test('debounces search and resets the first-page cursor', () async {
      final repository = _RecordingAlertsRepository();
      final cubit = AlertsCubit(
        repository: repository,
        searchDebounce: const Duration(milliseconds: 1),
      );
      addTearDown(cubit.close);

      await cubit.load();
      cubit.setSearch('oxygen');
      expect(cubit.state.search, 'oxygen');
      expect(cubit.state.nextCursor, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repository.queries.last.search, 'oxygen');
      expect(repository.queries.last.page.cursor, isNull);
    });

    test('filters update the query and trigger a first-page reload', () async {
      final repository = _RecordingAlertsRepository();
      final cubit = AlertsCubit(repository: repository);
      addTearDown(cubit.close);

      await cubit.load();
      cubit.setCategories({'hardware'});
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.categories, {'hardware'});
      expect(repository.queries.last.categories, {'hardware'});
      expect(repository.queries.last.page.cursor, isNull);
    });

    test('load more appends rows and ignores concurrent requests', () async {
      final secondPage = Completer<DataResult<AlertsData>>();
      var calls = 0;
      final cubit = AlertsCubit(
        repository: _FakeAlertsRepository((_) {
          calls++;
          if (calls == 1) {
            return _data([PreviewData.alertItems[0]], nextCursor: 'next');
          }
          return secondPage.future;
        }),
      );
      addTearDown(cubit.close);

      await cubit.load();
      unawaited(cubit.loadNextPage());
      unawaited(cubit.loadNextPage());
      await Future<void>.delayed(Duration.zero);

      expect(calls, 2);
      expect(cubit.state.isLoadingMore, isTrue);
      secondPage.complete(_data([PreviewData.alertItems[1]]));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.items.map((item) => item.code), hasLength(2));
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.hasMore, isFalse);
    });

    test('stale responses cannot overwrite a newer reload', () async {
      final firstRequest = Completer<DataResult<AlertsData>>();
      var calls = 0;
      final cubit = AlertsCubit(
        repository: _FakeAlertsRepository((_) {
          calls++;
          return calls == 1
              ? firstRequest.future
              : _data([PreviewData.alertItems[1]]);
        }),
      );
      addTearDown(cubit.close);

      unawaited(cubit.load());
      await Future<void>.delayed(Duration.zero);
      await cubit.reload();
      firstRequest.complete(_data([PreviewData.alertItems[0]]));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.items.single.code, PreviewData.alertItems[1].code);
    });

    test('remains compatible with the preview repository fallback', () async {
      final cubit = AlertsCubit(repository: const PreviewAlertsRepository());
      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadNextPage();

      expect(cubit.state.items, hasLength(4));
      expect(cubit.state.hasMore, isFalse);
    });
  });
}

class _FakeAlertsRepository implements AlertsRepository {
  _FakeAlertsRepository(this._fetch);

  final FutureOr<DataResult<AlertsData>> Function(AlertsQuery query) _fetch;

  @override
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query) async =>
      _fetch(query);
}

class _RecordingAlertsRepository implements AlertsRepository {
  final List<AlertsQuery> queries = [];

  @override
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query) async {
    queries.add(query);
    return _data([PreviewData.alertItems.first], nextCursor: 'cursor');
  }
}

DataResult<AlertsData> _data(List<InventoryItem> items, {String? nextCursor}) {
  return DataSuccess(
    AlertsData(
      summary: const AlertSummary(lowCount: 1, outOfStockCount: 1),
      alerts: PageResult(items: items, nextCursor: nextCursor),
    ),
  );
}

DataResult<AlertsData> _failure() => const DataError(
  DataFailure(kind: DataFailureKind.offline, message: 'Offline'),
);
