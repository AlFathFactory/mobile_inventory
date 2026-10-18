import 'dart:convert';

import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/features/inventory/data/models/inventory_query.dart';
import 'package:el_fateh/features/inventory/data/repositories/inventory_repository_factory.dart';
import 'package:el_fateh/features/inventory/data/repositories/preview_inventory_repository.dart';
import 'package:el_fateh/features/inventory/data/repositories/supabase_inventory_repository.dart';
import 'package:el_fateh/features/inventory/data/services/inventory_remote_data_source.dart';
import 'package:el_fateh/features/inventory/data/services/supabase_inventory_service.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('live inventory row mapping', () {
    test('maps the exact unified-view fields and backend identity', () {
      final item = InventoryItem.fromInventorySummaryRow(
        _row(
          index: 7,
          stockBalance: '1.5',
          minimum: '1.5',
          internalCode: null,
          codeNumber: 'CN-7',
        ),
      );

      expect(item.tableName, 'inventory_items');
      expect(item.itemId, '00000000-0000-0000-0000-000000000007');
      expect(item.itemKey, 'item-7');
      expect(item.categoryId, isNull);
      expect(item.category, 'مستهلكات');
      expect(item.code, 'CN-7');
      expect(item.quantity, 1.5);
      expect(item.minimum, 1.5);
      expect(item.status, StockStatus.low);
      expect(
        item.routeId,
        'inventory_items::00000000-0000-0000-0000-000000000007',
      );
    });

    test('maps every legacy category key to its Arabic view name', () {
      const expectedNames = {
        'consumables': 'مستهلكات',
        'paints': 'الدهانات',
        'screws': 'مسامير',
        'stock_screws': 'مسامير استوك',
        'raw_materials': 'خامات',
      };

      for (final entry in expectedNames.entries) {
        final item = InventoryItem.fromInventorySummaryRow(
          _row(index: 1, categoryName: entry.key),
        );
        expect(item.category, entry.value);
      }
      expect(
        InventoryItem.fromInventorySummaryRow(
          _row(index: 2, categoryName: 'اختبار'),
        ).category,
        'اختبار',
      );
    });
  });

  group('live inventory query plan', () {
    test(
      'keeps search and filters server-side with deterministic ordering',
      () {
        final plan = InventoryRemoteQuery.fromInventoryQuery(
          const InventoryQuery(
            page: PageRequest(limit: 20, cursor: '40'),
            search: ' P-100,(unsafe)* ',
            statuses: {StockStatus.low, StockStatus.outOfStock},
            categories: {'الدهانات', 'مستهلكات'},
            projects: {'Project B', 'Project A'},
          ),
        );

        expect(plan.offset, 40);
        expect(plan.pageSize, 20);
        expect(plan.fetchLimit, 21);
        expect(plan.rangeEnd, 60);
        expect(plan.search, 'P-100 unsafe');
        expect(plan.categories, ['الدهانات', 'مستهلكات']);
        expect(plan.projects, ['Project A', 'Project B']);
        expect(plan.statuses, ['قليل', 'منتهي']);
        expect(InventoryRemoteQuery.searchColumns, [
          'item_name',
          'internal_code',
          'code_number',
          'project_name',
          'supplier_name',
        ]);
        expect(
          InventoryRemoteQuery.orderColumns
              .map((order) => '${order.column}:${order.ascending}')
              .toList(),
          ['updated_at:false', 'table_name:true', 'item_id:true'],
        );
      },
    );

    test('rejects an invalid opaque cursor before making a request', () async {
      final source = _FakeInventorySource();
      final repository = SupabaseInventoryRepository(source);

      final result = await repository.fetchItems(
        const InventoryQuery(page: PageRequest(cursor: 'invalid')),
      );

      expect(result, isA<DataError<Object?>>());
      expect((result as DataError).failure.kind, DataFailureKind.unknown);
      expect(source.requests, isEmpty);
    });
  });

  group('live inventory category catalog', () {
    test('returns legacy categories plus valid unique dynamic names', () async {
      final requests = <Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'sb_publishable_example',
        httpClient: MockClient((request) async {
          requests.add(request);
          return Response(
            jsonEncode([
              {'name': 'اختبار'},
              {'name': 'الدهانات'},
              {'name': ''},
              {'name': 'اختبار'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);

      final categories = await SupabaseInventoryService(
        client,
      ).fetchCategories();

      expect(categories, [
        'مستهلكات',
        'الدهانات',
        'مسامير',
        'مسامير استوك',
        'خامات',
        'اختبار',
      ]);
      expect(requests, hasLength(1));
      expect(requests.single.url.path, endsWith('/categories'));
      expect(
        requests.single.url.queryParameters,
        containsPair('select', 'name'),
      );
      expect(
        requests.single.url.queryParameters,
        containsPair('is_archived', 'eq.false'),
      );
      expect(
        requests.single.url.queryParameters,
        containsPair('order', 'name.asc.nullslast'),
      );
    });
  });

  group('SupabaseInventoryRepository', () {
    test('returns bounded pages and an opaque look-ahead cursor', () async {
      final source = _FakeInventorySource(
        rows: List.generate(21, (index) => _row(index: index)),
      );
      final repository = SupabaseInventoryRepository(source);

      final result = await repository.fetchItems(const InventoryQuery());
      final page = (result as DataSuccess).value as PageResult<InventoryItem>;

      expect(page.items, hasLength(20));
      expect(page.nextCursor, '20');
      expect(source.requests.single.fetchLimit, 21);
    });

    test('returns an empty successful page', () async {
      final repository = SupabaseInventoryRepository(_FakeInventorySource());

      final result = await repository.fetchItems(const InventoryQuery());
      final page = (result as DataSuccess).value as PageResult<InventoryItem>;

      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test(
      'maps connectivity and PostgREST errors without raw messages',
      () async {
        final offline = await SupabaseInventoryRepository(
          _FakeInventorySource(error: ClientException('raw network detail')),
        ).fetchItems(const InventoryQuery());
        final unavailable = await SupabaseInventoryRepository(
          _FakeInventorySource(
            error: const PostgrestException(
              message: 'raw policy detail',
              code: '42501',
            ),
          ),
        ).fetchItems(const InventoryQuery());
        final server = await SupabaseInventoryRepository(
          _FakeInventorySource(
            error: const PostgrestException(
              message: 'raw database detail',
              code: 'XX000',
            ),
          ),
        ).fetchItems(const InventoryQuery());

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

  test('uses PreviewData only when no Supabase client is configured', () {
    expect(
      InventoryRepositoryFactory.create(null),
      isA<PreviewInventoryRepository>(),
    );

    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_example',
    );
    expect(
      InventoryRepositoryFactory.create(client),
      isA<SupabaseInventoryRepository>(),
    );
    client.dispose();
  });
}

Map<String, dynamic> _row({
  required int index,
  Object stockBalance = 10,
  Object minimum = 2,
  String categoryName = 'consumables',
  String? internalCode = 'INT-1',
  String? codeNumber,
}) {
  return {
    'table_name': 'inventory_items',
    'category_name': categoryName,
    'item_id': '00000000-0000-0000-0000-${index.toString().padLeft(12, '0')}',
    'item_key': 'item-$index',
    'project_name': 'Project A',
    'item_name': 'Item $index',
    'stock_balance': stockBalance,
    'min_quantity': minimum,
    'status': 'آمن',
    'supplier_name': 'Supplier A',
    'expire_date': '2027-01-01',
    'notes': null,
    'updated_at': '2026-10-13T10:00:00Z',
    'created_at': '2026-01-01T10:00:00Z',
    'code_number': codeNumber,
    'internal_code': internalCode == 'INT-1' ? 'INT-$index' : internalCode,
  };
}

class _FakeInventorySource implements InventoryRemoteDataSource {
  _FakeInventorySource({this.rows = const [], this.error});

  final List<Map<String, dynamic>> rows;
  final Object? error;
  final List<InventoryRemoteQuery> requests = [];

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    requests.add(query);
    if (error case final error?) throw error;
    return rows;
  }

  @override
  Future<List<String>> fetchCategories() async => const [];
}
