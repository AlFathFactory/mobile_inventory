import 'package:el_fateh/core/config/supabase_config.dart';
import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/load_state.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/core/data/services/supabase_bootstrap.dart';
import 'package:el_fateh/features/alerts/data/models/alerts_query.dart';
import 'package:el_fateh/features/alerts/data/repositories/preview_alerts_repository.dart';
import 'package:el_fateh/features/dashboard/data/repositories/preview_dashboard_repository.dart';
import 'package:el_fateh/features/dashboard/model/dashboard_models.dart';
import 'package:el_fateh/features/inventory/data/models/inventory_query.dart';
import 'package:el_fateh/features/inventory/data/models/movement_history_query.dart';
import 'package:el_fateh/features/inventory/data/repositories/preview_inventory_repository.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:el_fateh/features/inventory/model/inventory_movement.dart';
import 'package:el_fateh/features/reports/data/models/reports_query.dart';
import 'package:el_fateh/features/reports/data/repositories/preview_reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';

T _successValue<T>(DataResult<T> result) {
  expect(result, isA<DataSuccess<T>>());
  return (result as DataSuccess<T>).value;
}

void main() {
  group('PreviewData repositories', () {
    test('inventory applies filters and opaque cursor pagination', () async {
      const repository = PreviewInventoryRepository();

      final first = _successValue(
        await repository.fetchItems(
          const InventoryQuery(page: PageRequest(limit: 2)),
        ),
      );
      expect(first.items, hasLength(2));
      expect(first.nextCursor, isNotNull);

      final second = _successValue(
        await repository.fetchItems(
          InventoryQuery(page: PageRequest(limit: 2, cursor: first.nextCursor)),
        ),
      );
      expect(second.items, hasLength(2));
      expect(second.items.first.code, isNot(first.items.first.code));

      final filtered = _successValue(
        await repository.fetchItems(
          const InventoryQuery(
            search: 'GS-OX',
            statuses: {StockStatus.outOfStock},
            categories: {'اسطوانات'},
          ),
        ),
      );
      expect(filtered.items.single.code, 'GS-OX-004');
    });

    test('item details and movement history preserve item context', () async {
      const repository = PreviewInventoryRepository();

      final item = _successValue(await repository.fetchItemByCode('PA-GN-059'));
      expect(item?.code, 'PA-GN-059');
      expect(
        _successValue(await repository.fetchItemByCode('missing')),
        isNull,
      );

      final history = _successValue(
        await repository.fetchMovements(
          const MovementHistoryQuery(
            itemCode: 'PA-GN-059',
            page: PageRequest(limit: 2),
          ),
        ),
      );
      expect(history.items, hasLength(2));
      expect(history.items.every((row) => row.itemCode == 'PA-GN-059'), isTrue);
      expect(history.hasMore, isTrue);
    });

    test('alerts supports server-shaped status filters', () async {
      const repository = PreviewAlertsRepository();
      final data = _successValue(
        await repository.fetchAlerts(
          const AlertsQuery(statuses: {StockStatus.outOfStock}),
        ),
      );

      expect(data.alerts.items.single.code, 'GS-OX-004');
      expect(data.summary.outOfStockCount, 3);
    });

    test('reports supports type and inclusive date filters', () async {
      const repository = PreviewReportsRepository();
      final data = _successValue(
        await repository.fetchReports(
          ReportsQuery(
            types: const {MovementType.issue},
            startDate: DateTime(2026, 8, 15),
            endDate: DateTime(2026, 8, 15, 23, 59),
          ),
        ),
      );

      expect(data.movements.items.single.itemCode, 'PA-GN-059');
      expect(data.snapshot.total, 128);
    });

    test('dashboard limits collection reads', () async {
      const repository = PreviewDashboardRepository();
      final data = _successValue(
        await repository.fetchDashboard(
          attentionLimit: 1,
          recentMovementLimit: 2,
        ),
      );

      expect(data.attentionItems, hasLength(1));
      expect(data.recentMovements, hasLength(2));
      expect(data.categories, isNotEmpty);
    });
  });

  group('Supabase-ready domain mapping', () {
    test('maps inventory and movement rows without DTO duplication', () {
      final item = InventoryItem.fromJson(const {
        'code': 'TEST-1',
        'name': 'Test item',
        'category': 'Test category',
        'category_id': 'category-1',
        'project': 'Project',
        'quantity': 2,
        'minimum': 3,
        'supplier': null,
        'expiry': null,
        'notes': null,
      });
      expect(item.categoryId, 'category-1');
      expect(item.status, StockStatus.low);
      expect(item.status.dataValue, 'low');

      final movement = InventoryMovement.fromJson(const {
        'id': 'movement-1',
        'item_code': 'TEST-1',
        'item_name': 'Test item',
        'category': 'Test category',
        'category_id': 'category-1',
        'type': 'issue',
        'quantity': 1,
        'before': 2,
        'after': 1,
        'date': '2026-10-13T10:00:00Z',
        'project': 'Project',
        'party_label': null,
        'party_name': null,
        'purchase_order': null,
        'note': null,
      });
      expect(movement.type, MovementType.issue);
      expect(movement.date.isUtc, isTrue);
    });

    test('maps category summaries with optional stable ids', () {
      final category = CategorySummary.fromJson(const {
        'id': 'category-1',
        'name': 'Test category',
        'item_count': 8,
        'attention_count': 2,
      });

      expect(category.id, 'category-1');
      expect(category.itemCount, 8);
    });
  });

  test('load state retains typed offline failures and cached data', () {
    const failure = DataFailure(
      kind: DataFailureKind.offline,
      message: 'No connection',
    );
    const state = DataLoadState<int>.failed(failure, previousData: 4);

    expect(state.status, DataLoadStatus.failure);
    expect(state.failure?.kind, DataFailureKind.offline);
    expect(state.data, 4);
  });

  test('Supabase bootstrap is optional while PreviewData is active', () async {
    const missing = SupabaseConfig(url: '', publishableKey: '');
    const configured = SupabaseConfig(
      url: 'https://project.supabase.co',
      publishableKey: 'sb_publishable_example',
    );

    expect(missing.isConfigured, isFalse);
    expect(configured.isConfigured, isTrue);
    expect(await SupabaseBootstrap.initialize(config: missing), isNull);
  });
}
