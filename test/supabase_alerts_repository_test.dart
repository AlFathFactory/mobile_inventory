import 'package:el_fateh/app.dart';
import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/features/alerts/data/models/alerts_data.dart';
import 'package:el_fateh/features/alerts/data/models/alerts_query.dart';
import 'package:el_fateh/features/alerts/data/repositories/alerts_repository.dart';
import 'package:el_fateh/features/alerts/data/repositories/alerts_repository_factory.dart';
import 'package:el_fateh/features/alerts/data/repositories/preview_alerts_repository.dart';
import 'package:el_fateh/features/alerts/data/repositories/supabase_alerts_repository.dart';
import 'package:el_fateh/features/alerts/data/services/alerts_remote_data_source.dart';
import 'package:el_fateh/features/alerts/model/alert_summary.dart';
import 'package:el_fateh/features/inventory/data/repositories/item_details_repository.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('live alerts query plan', () {
    test('sanitizes and retains server-side alert filters', () {
      final query = AlertsRemoteQuery.fromAlertsQuery(
        const AlertsQuery(
          page: PageRequest(limit: 20, cursor: '40'),
          search: ' A-1,(unsafe)* ',
          statuses: {StockStatus.low, StockStatus.outOfStock},
          categories: {'Paint', 'Consumables'},
          projects: {'Project B', 'Project A'},
        ),
      );

      expect(query.offset, 40);
      expect(query.pageSize, 20);
      expect(query.fetchLimit, 21);
      expect(query.search, 'A-1 unsafe');
      expect(query.categories, ['Consumables', 'Paint']);
      expect(query.projects, ['Project A', 'Project B']);
      expect(query.statuses, [StockStatus.outOfStock, StockStatus.low]);
      expect(
        AlertsRemoteQuery.orderColumns
            .map((order) => '${order.column}:${order.ascending}')
            .toList(),
        ['updated_at:false', 'table_name:true', 'item_id:true'],
      );
      expect(AlertsRemoteQuery.selectedColumns, [
        'table_name',
        'item_id',
        'item_key',
        'category_name',
        'project_name',
        'item_name',
        'stock_balance',
        'min_quantity',
        'status',
        'code_number',
        'internal_code',
      ]);
    });

    test('rejects an invalid opaque cursor without fetching rows', () async {
      final source = _FakeAlertsSource();
      final result = await SupabaseAlertsRepository(
        source,
      ).fetchAlerts(const AlertsQuery(page: PageRequest(cursor: 'invalid')));

      expect(result, isA<DataError<AlertsData>>());
      expect((result as DataError).failure.kind, DataFailureKind.unknown);
      expect(source.countRequests, isEmpty);
      expect(source.fetchRequests, isEmpty);
    });
  });

  group('SupabaseAlertsRepository', () {
    test('all alerts are severity-first and use bounded look-ahead', () async {
      final source = _FakeAlertsSource(
        rows: {
          StockStatus.outOfStock: [
            _row(1, status: 'منتهي'),
            _row(2, status: 'منتهي'),
          ],
          StockStatus.low: [_row(3, status: 'قليل'), _row(4, status: 'قليل')],
        },
      );
      final repository = SupabaseAlertsRepository(source);

      final data = _success(
        await repository.fetchAlerts(
          const AlertsQuery(page: PageRequest(limit: 3)),
        ),
      );

      expect(data.alerts.items.map((item) => item.status), [
        StockStatus.outOfStock,
        StockStatus.outOfStock,
        StockStatus.low,
      ]);
      expect(data.alerts.nextCursor, '3');
      expect(source.fetchRequests.map((request) => request.status), [
        StockStatus.outOfStock,
        StockStatus.low,
      ]);
      expect(source.fetchRequests.map((request) => request.limit), [2, 2]);
      expect(
        source.fetchRequests.every((request) => request.limit <= 4),
        isTrue,
      );
    });

    test(
      'low-stock and out-of-stock filters fetch only their segment',
      () async {
        final source = _FakeAlertsSource(
          rows: {
            StockStatus.outOfStock: [_row(1, status: 'منتهي')],
            StockStatus.low: [_row(2, status: 'قليل')],
          },
        );
        final repository = SupabaseAlertsRepository(source);

        final low = _success(
          await repository.fetchAlerts(
            const AlertsQuery(statuses: {StockStatus.low}),
          ),
        );
        expect(low.alerts.items.single.status, StockStatus.low);
        expect(source.fetchRequests.single.status, StockStatus.low);

        source.fetchRequests.clear();
        final out = _success(
          await repository.fetchAlerts(
            const AlertsQuery(statuses: {StockStatus.outOfStock}),
          ),
        );
        expect(out.alerts.items.single.status, StockStatus.outOfStock);
        expect(source.fetchRequests.single.status, StockStatus.outOfStock);
      },
    );

    test('pagination crosses severity segments without duplicates', () async {
      final source = _FakeAlertsSource(
        rows: {
          StockStatus.outOfStock: [
            _row(1, status: 'منتهي'),
            _row(2, status: 'منتهي'),
          ],
          StockStatus.low: [_row(3, status: 'قليل'), _row(4, status: 'قليل')],
        },
      );
      final repository = SupabaseAlertsRepository(source);
      final first = _success(
        await repository.fetchAlerts(
          const AlertsQuery(page: PageRequest(limit: 3)),
        ),
      );
      final second = _success(
        await repository.fetchAlerts(
          AlertsQuery(
            page: PageRequest(limit: 3, cursor: first.alerts.nextCursor),
          ),
        ),
      );

      expect(second.alerts.items.single.itemId, _id(4));
      expect(second.alerts.nextCursor, isNull);
      expect(
        {
          ...first.alerts.items,
          ...second.alerts.items,
        }.map((item) => item.routeId).toSet(),
        hasLength(4),
      );
    });

    test('maps live rows and preserves backend identity and status', () async {
      final source = _FakeAlertsSource(
        rows: {
          StockStatus.outOfStock: [
            _row(
              7,
              status: 'منتهي',
              stockBalance: 0,
              minimum: 1,
              displayCode: 'DUPLICATE',
            ),
          ],
        },
      );

      final data = _success(
        await SupabaseAlertsRepository(
          source,
        ).fetchAlerts(const AlertsQuery(statuses: {StockStatus.outOfStock})),
      );
      final item = data.alerts.items.single;

      expect(item.code, 'DUPLICATE');
      expect(item.status, StockStatus.outOfStock);
      expect(item.tableName, 'inventory_items');
      expect(item.itemId, _id(7));
      expect(item.routeId, 'inventory_items::${_id(7)}');
    });

    test(
      'returns an empty success and maps failures without raw details',
      () async {
        final empty = _success(
          await SupabaseAlertsRepository(
            _FakeAlertsSource(),
          ).fetchAlerts(const AlertsQuery()),
        );
        expect(empty.alerts.items, isEmpty);
        expect(empty.alerts.nextCursor, isNull);

        final failures = <Object, DataFailureKind>{
          ClientException('raw network detail'): DataFailureKind.offline,
          const PostgrestException(message: 'raw policy detail', code: '42501'):
              DataFailureKind.unavailable,
          const PostgrestException(message: 'raw server detail', code: 'XX000'):
              DataFailureKind.server,
          StateError('raw unknown detail'): DataFailureKind.unknown,
        };
        for (final entry in failures.entries) {
          final result = await SupabaseAlertsRepository(
            _FakeAlertsSource(error: entry.key),
          ).fetchAlerts(const AlertsQuery());
          final failure = (result as DataError).failure;
          expect(failure.kind, entry.value);
          expect(failure.message, isNot(contains('raw')));
        }
      },
    );
  });

  test('does not use PreviewData when no Supabase client is configured', () {
    expect(
      AlertsRepositoryFactory.create(null),
      isNot(isA<PreviewAlertsRepository>()),
    );

    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_example',
    );
    expect(
      AlertsRepositoryFactory.create(client),
      isA<SupabaseAlertsRepository>(),
    );
    client.dispose();
  });

  testWidgets('duplicate display codes navigate by table and item id', (
    tester,
  ) async {
    final first = InventoryItem.fromInventorySummaryRow(
      _row(11, status: 'منتهي', displayCode: 'SAME-CODE'),
    );
    final second = InventoryItem.fromInventorySummaryRow(
      _row(12, status: 'قليل', displayCode: 'SAME-CODE'),
    );
    final details = _RecordingItemDetailsRepository({
      first.routeId: first,
      second.routeId: second,
    });

    await tester.pumpWidget(
      MyApp(
        previewLoadDelay: Duration.zero,
        alertsRepository: _StaticAlertsRepository([first, second]),
        itemDetailsRepository: details,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('alert-${second.routeId}')));
    await tester.pumpAndSettle();

    expect(details.requestedRouteIds, [second.routeId]);
    expect(find.byKey(const Key('item-details-list')), findsOneWidget);
    expect(find.text(_id(12)), findsNothing);
  });
}

AlertsData _success(DataResult<AlertsData> result) {
  expect(result, isA<DataSuccess<AlertsData>>());
  return (result as DataSuccess<AlertsData>).value;
}

String _id(int index) =>
    '00000000-0000-0000-0000-${index.toString().padLeft(12, '0')}';

Map<String, dynamic> _row(
  int index, {
  required String status,
  Object? stockBalance,
  Object minimum = 2,
  String? displayCode,
}) {
  return {
    'table_name': 'inventory_items',
    'item_id': _id(index),
    'item_key': 'item-$index',
    'category_name': 'Consumables',
    'project_name': 'Project A',
    'item_name': 'Item $index',
    'stock_balance': stockBalance ?? (status == 'قليل' ? 1 : 0),
    'min_quantity': minimum,
    'status': status,
    'code_number': null,
    'internal_code': displayCode ?? 'INT-$index',
  };
}

class _FetchRequest {
  const _FetchRequest({
    required this.query,
    required this.status,
    required this.offset,
    required this.limit,
  });

  final AlertsRemoteQuery query;
  final StockStatus status;
  final int offset;
  final int limit;
}

class _FakeAlertsSource implements AlertsRemoteDataSource {
  _FakeAlertsSource({this.rows = const {}, this.error});

  final Map<StockStatus, List<Map<String, dynamic>>> rows;
  final Object? error;
  final List<StockStatus> countRequests = [];
  final List<_FetchRequest> fetchRequests = [];

  @override
  Future<int> countAlerts(
    AlertsRemoteQuery query, {
    required StockStatus status,
  }) async {
    countRequests.add(status);
    if (error case final error?) throw error;
    return rows[status]?.length ?? 0;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAlerts(
    AlertsRemoteQuery query, {
    required StockStatus status,
    required int offset,
    required int limit,
  }) async {
    fetchRequests.add(
      _FetchRequest(query: query, status: status, offset: offset, limit: limit),
    );
    if (error case final error?) throw error;
    return (rows[status] ?? const [])
        .skip(offset)
        .take(limit)
        .toList(growable: false);
  }
}

class _StaticAlertsRepository implements AlertsRepository {
  const _StaticAlertsRepository(this.items);

  final List<InventoryItem> items;

  @override
  Future<DataResult<AlertsData>> fetchAlerts(AlertsQuery query) async {
    return DataSuccess(
      AlertsData(
        summary: const AlertSummary(lowCount: 1, outOfStockCount: 1),
        alerts: PageResult(items: items),
      ),
    );
  }
}

class _RecordingItemDetailsRepository implements ItemDetailsRepository {
  _RecordingItemDetailsRepository(this.items);

  final Map<String, InventoryItem> items;
  final List<String> requestedRouteIds = [];

  @override
  Future<DataResult<InventoryItem?>> fetchItemByRouteId(String routeId) async {
    requestedRouteIds.add(routeId);
    return DataSuccess(items[routeId]);
  }
}
