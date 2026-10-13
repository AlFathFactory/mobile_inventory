import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/router/app_router.dart';
import 'package:el_fateh/features/inventory/data/repositories/item_details_repository.dart';
import 'package:el_fateh/features/inventory/data/repositories/item_details_repository_factory.dart';
import 'package:el_fateh/features/inventory/data/repositories/preview_inventory_repository.dart';
import 'package:el_fateh/features/inventory/data/repositories/supabase_item_details_repository.dart';
import 'package:el_fateh/features/inventory/data/services/item_details_remote_data_source.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const firstId = '00000000-0000-0000-0000-000000000001';
  const secondId = '00000000-0000-0000-0000-000000000002';

  group('SupabaseItemDetailsRepository', () {
    test('looks up and maps one item by table name plus item id', () async {
      final source = _FakeItemDetailsSource(
        rows: {('paints', firstId): _row(tableName: 'paints', itemId: firstId)},
      );
      final repository = SupabaseItemDetailsRepository(source);

      final result = await repository.fetchItemByRouteId('paints::$firstId');

      final item = (result as DataSuccess<InventoryItem?>).value!;
      expect(source.requests, hasLength(1));
      expect(source.requests.single.tableName, 'paints');
      expect(source.requests.single.itemId, firstId);
      expect(
        ItemDetailsRemoteQuery.viewName,
        'inventory_category_items_summary_view',
      );
      expect(item.tableName, 'paints');
      expect(item.itemId, firstId);
      expect(item.code, 'DUPLICATE-CODE');
      expect(item.name, 'Live paint');
      expect(item.quantity, 7.5);
      expect(item.minimum, 2);
      expect(item.supplier, 'Supplier');
      expect(item.expiry, '2027-03-01');
      expect(item.notes, 'Read only');
      expect(item.updatedAt, DateTime.parse('2026-10-13T10:00:00Z'));
    });

    test(
      'returns empty when the active unified view has no matching row',
      () async {
        final repository = SupabaseItemDetailsRepository(
          _FakeItemDetailsSource(),
        );

        final result = await repository.fetchItemByRouteId('paints::$firstId');

        expect((result as DataSuccess<InventoryItem?>).value, isNull);
      },
    );

    test('rejects malformed live identity without making a request', () async {
      final source = _FakeItemDetailsSource();
      final repository = SupabaseItemDetailsRepository(source);

      for (final routeId in [
        '',
        'paints',
        'paints::not-a-uuid',
        'paints::$firstId::extra',
        'Paints::$firstId',
      ]) {
        final result = await repository.fetchItemByRouteId(routeId);
        expect(
          (result as DataError<InventoryItem?>).failure.kind,
          DataFailureKind.unknown,
        );
      }
      expect(source.requests, isEmpty);
    });

    test(
      'maps offline, unavailable, and server errors without raw details',
      () async {
        final failures = <Object, DataFailureKind>{
          ClientException('raw connection detail'): DataFailureKind.offline,
          const PostgrestException(message: 'raw policy detail', code: '42501'):
              DataFailureKind.unavailable,
          const PostgrestException(message: 'raw server detail', code: 'XX000'):
              DataFailureKind.server,
          StateError('raw unknown detail'): DataFailureKind.unknown,
        };

        for (final MapEntry(key: error, value: kind) in failures.entries) {
          final result = await SupabaseItemDetailsRepository(
            _FakeItemDetailsSource(error: error),
          ).fetchItemByRouteId('paints::$firstId');
          final failure = (result as DataError<InventoryItem?>).failure;
          expect(failure.kind, kind);
          expect(failure.message, isNot(contains('raw')));
        }
      },
    );

    test(
      'duplicate display codes resolve independently by backend identity',
      () async {
        final source = _FakeItemDetailsSource(
          rows: {
            ('paints', firstId): _row(
              tableName: 'paints',
              itemId: firstId,
              name: 'First item',
            ),
            ('screws', secondId): _row(
              tableName: 'screws',
              itemId: secondId,
              name: 'Second item',
            ),
          },
        );
        final repository = SupabaseItemDetailsRepository(source);

        final first =
            (await repository.fetchItemByRouteId('paints::$firstId')
                    as DataSuccess<InventoryItem?>)
                .value!;
        final second =
            (await repository.fetchItemByRouteId('screws::$secondId')
                    as DataSuccess<InventoryItem?>)
                .value!;

        expect(first.code, second.code);
        expect(first.name, 'First item');
        expect(second.name, 'Second item');
        expect(first.routeId, isNot(second.routeId));
      },
    );
  });

  test('selects PreviewData only when no Supabase client is configured', () {
    expect(
      ItemDetailsRepositoryFactory.create(null),
      isA<PreviewInventoryRepository>(),
    );

    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_example',
    );
    expect(
      ItemDetailsRepositoryFactory.create(client),
      isA<SupabaseItemDetailsRepository>(),
    );
    client.dispose();
  });

  testWidgets('direct live route resolves through ItemDetailsRepository', (
    tester,
  ) async {
    final item = InventoryItem.fromInventorySummaryRow(
      _row(tableName: 'paints', itemId: firstId, name: 'Direct live item'),
    );
    final repository = _FakeItemDetailsRepository(item);
    final appRouter = AppRouter(
      previewLoadDelay: Duration.zero,
      itemDetailsRepository: repository,
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter.router));
    await tester.pumpAndSettle();
    appRouter.router.go('/inventory/paints::$firstId');
    await tester.pumpAndSettle();

    expect(repository.routeIds, ['paints::$firstId']);
    expect(find.byKey(const Key('item-details-list')), findsOneWidget);
    expect(find.text('Direct live item'), findsOneWidget);
    expect(find.text('DUPLICATE-CODE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _row({
  required String tableName,
  required String itemId,
  String name = 'Live paint',
}) {
  return {
    'table_name': tableName,
    'category_name': 'الدهانات',
    'item_id': itemId,
    'item_key': 'item-key',
    'project_name': 'Project A',
    'item_name': name,
    'stock_balance': '7.5',
    'min_quantity': 2,
    'supplier_name': 'Supplier',
    'expire_date': '2027-03-01',
    'notes': 'Read only',
    'updated_at': '2026-10-13T10:00:00Z',
    'code_number': null,
    'internal_code': 'DUPLICATE-CODE',
  };
}

class _FakeItemDetailsSource implements ItemDetailsRemoteDataSource {
  _FakeItemDetailsSource({this.rows = const {}, this.error});

  final Map<(String, String), Map<String, dynamic>> rows;
  final Object? error;
  final List<ItemDetailsRemoteQuery> requests = [];

  @override
  Future<Map<String, dynamic>?> fetchItem(ItemDetailsRemoteQuery query) async {
    requests.add(query);
    if (error case final error?) throw error;
    return rows[(query.tableName, query.itemId)];
  }
}

class _FakeItemDetailsRepository implements ItemDetailsRepository {
  _FakeItemDetailsRepository(this.item);

  final InventoryItem item;
  final List<String> routeIds = [];

  @override
  Future<DataResult<InventoryItem?>> fetchItemByRouteId(String routeId) async {
    routeIds.add(routeId);
    return DataSuccess(item);
  }
}
