import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/theme/app_theme.dart';
import 'package:el_fateh/features/dashboard/controller/dashboard_controller.dart';
import 'package:el_fateh/features/dashboard/data/models/dashboard_data.dart';
import 'package:el_fateh/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:el_fateh/features/dashboard/data/repositories/dashboard_repository_factory.dart';
import 'package:el_fateh/features/dashboard/data/repositories/preview_dashboard_repository.dart';
import 'package:el_fateh/features/dashboard/data/repositories/supabase_dashboard_repository.dart';
import 'package:el_fateh/features/dashboard/data/services/dashboard_remote_data_source.dart';
import 'package:el_fateh/features/dashboard/view/dashboard_route_view.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('dashboard live summary mapping', () {
    test('maps RPC metrics and legacy plus dynamic categories', () async {
      final source = _FakeDashboardSource(
        summary: {
          'total_items': 2038,
          'low_stock': 2,
          'out_of_stock': 650,
          'categories': [
            {'name': 'الدهانات', 'item_count': 86, 'attention_count': 4},
            {
              'category_id': '11111111-1111-1111-1111-111111111111',
              'category_name': 'مخزن الكهرباء',
              'total_items': 63,
              'low_count': 1,
            },
          ],
        },
      );
      final repository = SupabaseDashboardRepository(source);

      final result = await repository.fetchDashboard();
      final data = (result as DataSuccess).value as DashboardData;

      expect(data.metrics.map((metric) => '${metric.label}:${metric.value}'), [
        'إجمالي الأصناف:2038',
        'مخزون منخفض:2',
        'نفد المخزون:650',
      ]);
      expect(data.categories, hasLength(2));
      expect(data.categories[0].id, isNull);
      expect(data.categories[0].name, 'الدهانات');
      expect(data.categories[0].itemCount, 86);
      expect(data.categories[1].id, '11111111-1111-1111-1111-111111111111');
      expect(data.categories[1].attentionCount, 1);
    });

    test('tolerates missing RPC keys and nameless categories', () async {
      final source = _FakeDashboardSource(
        summary: {
          'categories': [
            {'item_count': 5},
          ],
        },
      );
      final repository = SupabaseDashboardRepository(source);

      final result = await repository.fetchDashboard();
      final data = (result as DataSuccess).value as DashboardData;

      expect(data.metrics.map((metric) => metric.value), [0, 0, 0]);
      expect(data.categories, isEmpty);
    });
  });

  group('dashboard attention and recent activity', () {
    test('keeps severity order, bounds, and backend identity', () async {
      final source = _FakeDashboardSource(
        attention: [
          _attentionRow(index: 1, status: 'منتهي', stock: 0),
          _attentionRow(index: 2, status: 'قليل', stock: 3, minimum: 5),
        ],
      );
      final repository = SupabaseDashboardRepository(source);

      final result = await repository.fetchDashboard(attentionLimit: 10);
      final data = (result as DataSuccess).value as DashboardData;

      expect(data.attentionItems, hasLength(2));
      expect(data.attentionItems[0].status, StockStatus.outOfStock);
      expect(data.attentionItems[1].status, StockStatus.low);
      expect(
        data.attentionItems[0].routeId,
        'inventory_items::00000000-0000-0000-0000-000000000001',
      );
      expect(data.attentionItems[0].tableName, 'inventory_items');
      expect(data.attentionItems[0].itemId, isNotNull);
    });

    test(
      'bounds attention and recent slices to the requested limits',
      () async {
        final source = _FakeDashboardSource(
          attention: List.generate(
            5,
            (index) => _attentionRow(index: index, status: 'منتهي', stock: 0),
          ),
          recent: List.generate(5, (index) => _recentRow(index: index)),
        );
        final repository = SupabaseDashboardRepository(source);

        final result = await repository.fetchDashboard(
          attentionLimit: 2,
          recentMovementLimit: 2,
        );
        final data = (result as DataSuccess).value as DashboardData;

        expect(data.attentionItems, hasLength(2));
        expect(data.recentMovements, hasLength(2));
        expect(source.attentionLimit, 2);
        expect(source.recentLimit, 2);
      },
    );

    test('skips unknown movement operations instead of crashing', () async {
      final source = _FakeDashboardSource(
        recent: [
          _recentRow(index: 1, operation: 'add'),
          _recentRow(index: 2, operation: 'mystery-op'),
        ],
      );
      final repository = SupabaseDashboardRepository(source);

      final result = await repository.fetchDashboard();
      final data = (result as DataSuccess).value as DashboardData;

      expect(data.recentMovements, hasLength(1));
      expect(data.recentMovements.single.type, isNotNull);
    });

    test('zero limits return empty slices', () async {
      final source = _FakeDashboardSource(
        attention: [_attentionRow(index: 1, status: 'منتهي', stock: 0)],
        recent: [_recentRow(index: 1)],
      );
      final repository = SupabaseDashboardRepository(source);

      final result = await repository.fetchDashboard(
        attentionLimit: 0,
        recentMovementLimit: 0,
      );
      final data = (result as DataSuccess).value as DashboardData;

      expect(data.attentionItems, isEmpty);
      expect(data.recentMovements, isEmpty);
    });
  });

  group('dashboard fallback and failures', () {
    test('uses PreviewData only when no Supabase client is configured', () {
      expect(
        DashboardRepositoryFactory.create(null),
        isA<PreviewDashboardRepository>(),
      );

      final client = SupabaseClient(
        'https://example.supabase.co',
        'sb_publishable_example',
      );
      expect(
        DashboardRepositoryFactory.create(client),
        isA<SupabaseDashboardRepository>(),
      );
      client.dispose();
    });

    test('preview repository respects bounds', () async {
      const repository = PreviewDashboardRepository();

      final limited = await repository.fetchDashboard(attentionLimit: 1);
      final limitedData = (limited as DataSuccess).value as DashboardData;
      expect(limitedData.attentionItems, hasLength(1));
      expect(limitedData.recentMovements, hasLength(3));

      final empty = await repository.fetchDashboard(
        attentionLimit: -1,
        recentMovementLimit: -1,
      );
      final emptyData = (empty as DataSuccess).value as DashboardData;
      expect(emptyData.attentionItems, isEmpty);
      expect(emptyData.recentMovements, isEmpty);
    });

    test(
      'maps connectivity and PostgREST errors without raw messages',
      () async {
        final offline = await SupabaseDashboardRepository(
          _FakeDashboardSource(error: ClientException('raw network detail')),
        ).fetchDashboard();
        final unavailable = await SupabaseDashboardRepository(
          _FakeDashboardSource(
            error: const PostgrestException(
              message: 'raw policy detail',
              code: '42501',
            ),
          ),
        ).fetchDashboard();
        final server = await SupabaseDashboardRepository(
          _FakeDashboardSource(
            error: const PostgrestException(
              message: 'raw database detail',
              code: 'XX000',
            ),
          ),
        ).fetchDashboard();

        expect((offline as DataError).failure.kind, DataFailureKind.offline);
        expect(
          (unavailable as DataError).failure.kind,
          DataFailureKind.unavailable,
        );
        final serverFailure = (server as DataError).failure;
        expect(serverFailure.kind, DataFailureKind.server);
        expect(serverFailure.message, isNot(contains('raw database detail')));
      },
    );
  });

  group('DashboardController', () {
    test('loads successfully through the repository contract', () async {
      final controller = DashboardController(
        repository: const PreviewDashboardRepository(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.data, isNotNull);
      expect(controller.data!.metrics.first.label, 'إجمالي الأصناف');
      expect(controller.data!.categories, isNotEmpty);
    });

    test('surfaces failure and recovers on retry', () async {
      final repository = _ToggleDashboardRepository();
      final controller = DashboardController(repository: repository);
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.data, isNull);

      repository.shouldFail = false;
      await controller.load();
      expect(controller.data, isNotNull);
    });
  });

  group('DashboardRouteView', () {
    testWidgets('renders preview dashboard and forwards category taps', (
      tester,
    ) async {
      final controller = DashboardController(
        repository: const PreviewDashboardRepository(),
      );
      addTearDown(controller.dispose);

      String? openedCategory;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: DashboardRouteView(
            controller: controller,
            onShowInventory: (category) => openedCategory = category,
            onShowAlerts: () {},
            onShowReports: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إجمالي الأصناف'), findsOneWidget);
      expect(find.text('الدهانات'), findsWidgets);

      await tester.tap(find.text('الدهانات').first);
      await tester.pumpAndSettle();
      expect(openedCategory, 'الدهانات');
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows retry on failure and recovers', (tester) async {
      final repository = _ToggleDashboardRepository();
      final controller = DashboardController(repository: repository);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: DashboardRouteView(
            controller: controller,
            onShowInventory: (_) {},
            onShowAlerts: () {},
            onShowReports: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('retry-dashboard')), findsOneWidget);

      repository.shouldFail = false;
      await tester.tap(find.byKey(const Key('retry-dashboard')));
      await tester.pumpAndSettle();

      expect(find.text('إجمالي الأصناف'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Map<String, dynamic> _attentionRow({
  required int index,
  required String status,
  required Object stock,
  Object minimum = 2,
}) {
  return {
    'table_name': 'inventory_items',
    'item_id': '00000000-0000-0000-0000-${index.toString().padLeft(12, '0')}',
    'item_key': 'item-$index',
    'category_name': 'Consumables',
    'project_name': 'Project A',
    'item_name': 'Item $index',
    'stock_balance': stock,
    'min_quantity': minimum,
    'status': status,
    'code_number': 'CN-$index',
    'internal_code': null,
  };
}

Map<String, dynamic> _recentRow({
  required int index,
  String operation = 'add',
}) {
  return {
    'id': 'movement-$index',
    'table_name': 'inventory_items',
    'category_name': 'Consumables',
    'category_label': 'Consumables',
    'item_id': '00000000-0000-0000-0000-${index.toString().padLeft(12, '0')}',
    'item_name': 'Item $index',
    'item_label': 'Item $index',
    'project_name': 'Project A',
    'project': 'Project A',
    'operation_type': operation,
    'quantity': 5,
    'operation_date': '2026-08-1$index',
    'previous_balance': 10,
    'new_balance': 15,
    'supplier_name': 'Supplier A',
    'issued_to': null,
    'received_by': null,
    'purchase_order_number': null,
    'item_code': 'CN-$index',
    'notes': null,
    'created_at': '2026-08-1${index}T10:00:00Z',
    'code_number': 'CN-$index',
    'internal_code': null,
  };
}

class _FakeDashboardSource implements DashboardRemoteDataSource {
  _FakeDashboardSource({
    this.summary = const {},
    this.attention = const [],
    this.recent = const [],
    this.error,
  });

  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> attention;
  final List<Map<String, dynamic>> recent;
  final Object? error;
  int? attentionLimit;
  int? recentLimit;

  @override
  Future<Map<String, dynamic>> fetchSummary() async {
    if (error case final error?) throw error;
    return summary;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttentionItems({
    required int limit,
  }) async {
    attentionLimit = limit;
    if (error case final error?) throw error;
    return attention.take(limit).toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecentMovements({
    required int limit,
  }) async {
    recentLimit = limit;
    if (error case final error?) throw error;
    return recent.take(limit).toList(growable: false);
  }
}

class _ToggleDashboardRepository implements DashboardRepository {
  bool shouldFail = true;

  @override
  Future<DataResult<DashboardData>> fetchDashboard({
    int attentionLimit = 10,
    int recentMovementLimit = 3,
  }) async {
    if (shouldFail) {
      return const DataError(
        DataFailure(kind: DataFailureKind.unavailable, message: 'Unavailable.'),
      );
    }
    return const PreviewDashboardRepository().fetchDashboard(
      attentionLimit: attentionLimit,
      recentMovementLimit: recentMovementLimit,
    );
  }
}
