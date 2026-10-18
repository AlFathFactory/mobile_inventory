import 'dart:convert';

import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/load_state.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/features/inventory/model/inventory_movement.dart';
import 'package:el_fateh/features/reports/data/models/reports_query.dart';
import 'package:el_fateh/features/reports/data/models/reports_data.dart';
import 'package:el_fateh/features/reports/cubit/reports_cubit.dart';
import 'package:el_fateh/features/reports/data/repositories/preview_reports_repository.dart';
import 'package:el_fateh/features/reports/data/repositories/reports_repository_factory.dart';
import 'package:el_fateh/features/reports/data/repositories/reports_repository.dart';
import 'package:el_fateh/features/reports/data/repositories/supabase_reports_repository.dart';
import 'package:el_fateh/features/reports/data/services/reports_remote_data_source.dart';
import 'package:el_fateh/features/reports/data/services/supabase_reports_service.dart';
import 'package:el_fateh/features/reports/model/report_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps supported filters to the deployed RPC signature', () {
    final remote = ReportsRemoteQuery.fromQuery(
      ReportsQuery(
        page: const PageRequest(limit: 2, cursor: '20'),
        search: '  steel  ',
        types: const {MovementType.issue},
        categories: const {'Metals'},
        projects: const {'Project A'},
        startDate: DateTime(2026, 10, 1, 20),
        endDate: DateTime(2026, 10, 13, 1),
      ),
    );
    expect(remote.offset, 20);
    expect(remote.rangeEnd, 22);
    expect(remote.rpcParams, {
      'p_from_date': '2026-10-01',
      'p_to_date': '2026-10-13',
      'p_category_name': 'Metals',
      'p_project_name': 'Project A',
      'p_search': 'steel',
      'p_operation_type': 'issue',
      'p_page': 1,
      'p_page_size': 1,
    });
    expect(remote.safeSearch, 'steel');
    expect(ReportsRemoteQuery.rpcName, 'get_aggregated_inventory_report_rpc');
    expect(ReportsRemoteQuery.viewName, 'inventory_item_movements_view');
  });

  test('maps all operation types and rejects malformed cursors', () {
    for (final (type, value) in <(MovementType, String)>[
      (MovementType.addition, 'add'),
      (MovementType.issue, 'issue'),
      (MovementType.returned, 'return'),
      (MovementType.adjustment, 'adjust'),
    ]) {
      expect(
        ReportsRemoteQuery.fromQuery(ReportsQuery(types: {type})).operationType,
        value,
      );
    }
    expect(
      () => ReportsRemoteQuery.fromQuery(
        const ReportsQuery(page: PageRequest(cursor: 'invalid')),
      ),
      throwsFormatException,
    );
  });

  test(
    'maps timeline rows and global summary with bounded pagination',
    () async {
      final source = _FakeSource(
        rows: [
          _row('one', 'issue'),
          _row('two', 'add'),
          _row('three', 'return'),
        ],
        total: 87,
        summary: const {
          'issue_operations_count': 40,
          'addition_operations_count': 35,
        },
      );
      final repository = SupabaseReportsRepository(source);
      final result = await repository.fetchReports(
        const ReportsQuery(page: PageRequest(limit: 2)),
      );
      final data = (result as DataSuccess).value;
      expect(data.snapshot.total, 87);
      expect(data.snapshot.issues, 40);
      expect(data.snapshot.additions, 35);
      expect(data.movements.items, hasLength(2));
      expect(data.movements.nextCursor, '2');
      expect(data.movements.items.first.itemRouteId, 'paints::item-1');
      expect(data.movements.items.first.itemCode, 'DUPLICATE-CODE');
      expect(source.queries.single.rangeEnd, 2);
    },
  );

  test('empty and unknown operation results stay safe', () async {
    final empty = await SupabaseReportsRepository(
      _FakeSource(rows: const [], total: 0),
    ).fetchReports(const ReportsQuery());
    expect((empty as DataSuccess).value.movements.items, isEmpty);

    final unknown = await SupabaseReportsRepository(
      _FakeSource(rows: [_row('unknown', 'future_type')], total: 1),
    ).fetchReports(const ReportsQuery());
    expect((unknown as DataSuccess).value.movements.items, isEmpty);
  });

  test('maps backend failures without revealing raw errors', () async {
    for (final (error, kind) in <(Object, DataFailureKind)>[
      (ClientException('raw network detail'), DataFailureKind.offline),
      (
        const PostgrestException(message: 'raw policy', code: '42501'),
        DataFailureKind.unavailable,
      ),
      (
        const PostgrestException(message: 'raw server', code: 'XX000'),
        DataFailureKind.server,
      ),
      (StateError('raw unknown'), DataFailureKind.unknown),
    ]) {
      final result = await SupabaseReportsRepository(
        _FakeSource(error: error),
      ).fetchReports(const ReportsQuery());
      final failure = (result as DataError).failure;
      expect(failure.kind, kind);
      expect(failure.message, isNot(contains('raw')));
    }
  });

  test('selects preview only without a Supabase client', () {
    expect(
      ReportsRepositoryFactory.create(null),
      isA<PreviewReportsRepository>(),
    );
    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_example',
    );
    expect(
      ReportsRepositoryFactory.create(client),
      isA<SupabaseReportsRepository>(),
    );
    client.dispose();
  });

  test('service sends a bounded read, count, and actual summary RPC', () async {
    final requests = <Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_example',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith(
          '/rpc/get_aggregated_inventory_report_rpc',
        )) {
          return Response(
            jsonEncode({
              'rows': [],
              'total_items': 1,
              'summary': {
                'issue_operations_count': 6,
                'addition_operations_count': 3,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.method == 'HEAD') {
          return Response(
            '',
            200,
            headers: {
              'content-type': 'application/json',
              'content-range': '0-0/9',
            },
            request: request,
          );
        }
        return Response(
          jsonEncode([_row('one', 'issue')]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final query = ReportsRemoteQuery.fromQuery(
      ReportsQuery(
        page: const PageRequest(limit: 2),
        types: const {MovementType.issue},
        categories: const {'Metals'},
        projects: const {'Project A'},
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 13),
      ),
    );
    final service = SupabaseReportsService(client);
    final result = await service.fetchReports(query);

    expect(result.rows, hasLength(1));
    expect(result.totalMovements, 9);
    expect(result.aggregated['summary']['issue_operations_count'], 6);
    expect(requests, hasLength(3));
    final rowRequest = requests.singleWhere(
      (request) => request.method == 'GET',
    );
    expect(rowRequest.url.queryParameters['operation_type'], 'eq.issue');
    expect(rowRequest.url.queryParameters['category_name'], 'eq.Metals');
    expect(rowRequest.url.queryParameters['project_name'], 'eq.Project A');
    expect(rowRequest.url.queryParametersAll['operation_date'], [
      'gte.2026-10-01',
      'lte.2026-10-13',
    ]);
    expect(rowRequest.url.queryParameters['offset'], '0');
    expect(rowRequest.url.queryParameters['limit'], '3');
    final rpc = requests.singleWhere((request) => request.method == 'POST');
    expect(jsonDecode(rpc.body)['p_operation_type'], 'issue');
    expect(jsonDecode(rpc.body)['p_page_size'], 1);

    final next = ReportsRemoteQuery.fromQuery(
      ReportsQuery(
        page: const PageRequest(limit: 2, cursor: '2'),
        types: const {MovementType.issue},
        categories: const {'Metals'},
        projects: const {'Project A'},
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 13),
      ),
    );
    await service.fetchReports(next);
    expect(requests, hasLength(4));
    expect(requests.last.method, 'GET');
    expect(requests.last.url.queryParameters['offset'], '2');
  });

  test('filter options use bounded category keyset reads', () async {
    final requests = <Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_example',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/projects')) {
          return Response(
            jsonEncode([
              {'name': 'Project A'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        final after = request.url.queryParameters['category_name'];
        final rows = switch (after) {
          'gt.' => [
            {'category_name': 'Metals'},
          ],
          'gt.Metals' => [
            {'category_name': 'Paints'},
          ],
          _ => <Map<String, String>>[],
        };
        return Response(
          jsonEncode(rows),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final options = await SupabaseReportsService(client).fetchFilterOptions();
    expect(options.categories, ['Metals', 'Paints']);
    expect(options.projects, ['Project A']);
    final categoryRequests = requests.where(
      (request) => request.url.path.endsWith('/inventory_item_movements_view'),
    );
    expect(categoryRequests, hasLength(3));
    expect(
      categoryRequests.every(
        (request) =>
            request.url.queryParameters['select'] == 'category_name' &&
            request.url.queryParameters['limit'] == '1',
      ),
      isTrue,
    );
  });

  test(
    'controller sends date, type, category and project filters to repository',
    () async {
      final repository = _FakeReportsRepository();
      final controller = ReportsController.withRepository(
        repository: repository,
        clock: () => DateTime(2026, 10, 14),
        pageSize: 2,
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.categories, ['Metals']);
      expect(controller.projects, ['Project A']);
      expect(controller.snapshot.total, 87);
      expect(controller.hasMore, isTrue);
      await controller.loadNextPage();
      expect(repository.queries.last.page.cursor, '2');
      expect(controller.visibleMovements, hasLength(3));

      controller.selectDateRange(
        DateTimeRange(
          start: DateTime(2026, 10, 1, 3),
          end: DateTime(2026, 10, 13, 19),
        ),
      );
      controller.selectType(MovementType.issue);
      controller.selectCategory('Metals');
      controller.selectProject('Project A');
      await Future<void>.delayed(Duration.zero);
      final filtered = repository.queries.last;
      expect(filtered.startDate, DateTime(2026, 10, 1));
      expect(filtered.endDate, DateTime(2026, 10, 13));
      expect(filtered.types, {MovementType.issue});
      expect(filtered.categories, {'Metals'});
      expect(filtered.projects, {'Project A'});
      expect(filtered.page.cursor, isNull);

      controller.clearFilters();
      controller.selectPeriod(ReportPeriod.last30Days);
      await Future<void>.delayed(Duration.zero);
      expect(repository.queries.last.startDate, DateTime(2026, 9, 14));
      expect(repository.queries.last.endDate, DateTime(2026, 10, 14));
    },
  );

  test(
    'controller exposes empty and failure states without raw errors',
    () async {
      final repository = _FakeReportsRepository(empty: true);
      final controller = ReportsController.withRepository(
        repository: repository,
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.state.status, DataLoadStatus.empty);
      repository.failure = const DataFailure(
        kind: DataFailureKind.offline,
        message: 'Unable to reach the data service.',
      );
      controller.selectType(MovementType.issue);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.status, DataLoadStatus.failure);
      expect(controller.failure?.kind, DataFailureKind.offline);
    },
  );
}

Map<String, dynamic> _row(String id, String operationType) => {
  'id': id,
  'table_name': 'paints',
  'item_id': 'item-1',
  'item_name': 'Shared item',
  'item_label': 'Shared item',
  'category_name': 'Metals',
  'category_label': 'Metals',
  'project_name': 'Project A',
  'project': 'Project A',
  'operation_type': operationType,
  'quantity': 3,
  'operation_date': '2026-10-13',
  'created_at': '2026-10-13T12:00:00Z',
  'previous_balance': 10,
  'new_balance': 7,
  'supplier_name': null,
  'issued_to': 'Employee',
  'received_by': null,
  'purchase_order_number': null,
  'item_code': 'DUPLICATE-CODE',
  'notes': null,
  'code_number': null,
  'internal_code': null,
};

class _FakeSource implements ReportsRemoteDataSource {
  _FakeSource({
    this.rows = const [],
    this.total = 0,
    this.summary = const {
      'issue_operations_count': 0,
      'addition_operations_count': 0,
    },
    this.error,
  });

  final List<Map<String, dynamic>> rows;
  final int total;
  final Map<String, dynamic> summary;
  final Object? error;
  final List<ReportsRemoteQuery> queries = [];

  @override
  Future<ReportsRemoteResponse> fetchReports(ReportsRemoteQuery query) async {
    queries.add(query);
    if (error case final failure?) throw failure;
    return ReportsRemoteResponse(
      rows: rows,
      totalMovements: total,
      aggregated: {'summary': summary},
    );
  }

  @override
  Future<ReportsFilterOptions> fetchFilterOptions() async =>
      const ReportsFilterOptions(
        categories: ['Metals'],
        projects: ['Project A'],
      );
}

class _FakeReportsRepository implements ReportsRepository {
  _FakeReportsRepository({this.empty = false});

  final bool empty;
  DataFailure? failure;
  final List<ReportsQuery> queries = [];

  @override
  Future<DataResult<ReportsData>> fetchReports(ReportsQuery query) async {
    queries.add(query);
    if (failure case final error?) return DataError(error);
    final rows = empty
        ? <InventoryMovement>[]
        : query.page.cursor == null
        ? [
            InventoryMovement.tryFromMovementViewRow(_row('one', 'issue'))!,
            InventoryMovement.tryFromMovementViewRow(_row('two', 'add'))!,
          ]
        : [InventoryMovement.tryFromMovementViewRow(_row('three', 'return'))!];
    return DataSuccess(
      ReportsData(
        snapshot: const ReportSnapshot(total: 87, issues: 40, additions: 35),
        movements: PageResult(
          items: rows,
          nextCursor: empty || query.page.cursor != null ? null : '2',
        ),
      ),
    );
  }

  @override
  Future<DataResult<ReportsFilterOptions>> fetchFilterOptions() async =>
      const DataSuccess(
        ReportsFilterOptions(categories: ['Metals'], projects: ['Project A']),
      );
}
