import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/core/router/app_router.dart';
import 'package:el_fateh/features/inventory/data/models/movement_history_query.dart';
import 'package:el_fateh/features/inventory/data/repositories/item_details_repository.dart';
import 'package:el_fateh/features/inventory/data/repositories/movement_history_repository.dart';
import 'package:el_fateh/features/inventory/data/repositories/movement_history_repository_factory.dart';
import 'package:el_fateh/features/inventory/data/repositories/preview_inventory_repository.dart';
import 'package:el_fateh/features/inventory/data/repositories/supabase_movement_history_repository.dart';
import 'package:el_fateh/features/inventory/data/services/movement_history_remote_data_source.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:el_fateh/features/inventory/model/inventory_movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const firstId = '00000000-0000-0000-0000-000000000001';
  const secondId = '00000000-0000-0000-0000-000000000002';
  const firstRouteId = 'paints::$firstId';
  const secondRouteId = 'screws::$secondId';

  group('live movement row mapping', () {
    test('maps the exact view fields into InventoryMovement', () {
      final movement = InventoryMovement.tryFromMovementViewRow(
        _movementRow(
          id: 'movement-1',
          tableName: 'paints',
          itemId: firstId,
          operationType: 'add',
          quantity: '7.5',
          before: '2.5',
          after: 10,
          supplier: 'Supplier A',
        ),
      )!;

      expect(movement.id, 'movement-1');
      expect(movement.tableName, 'paints');
      expect(movement.itemId, firstId);
      expect(movement.itemCode, 'DUPLICATE-CODE');
      expect(movement.type, MovementType.addition);
      expect(movement.quantity, 7.5);
      expect(movement.before, 2.5);
      expect(movement.after, 10);
      expect(movement.partyName, 'Supplier A');
      expect(movement.purchaseOrder, 'PO-1');
      expect(movement.note, 'Read only');
      expect(movement.date, DateTime(2026, 10, 13));
      expect(movement.createdAt, DateTime.parse('2026-10-13T12:00:00Z'));
    });

    test('maps actual operation values and safely ignores unknown values', () {
      expect(movementTypeFromOperationValue('add'), MovementType.addition);
      expect(movementTypeFromOperationValue('issue'), MovementType.issue);
      expect(movementTypeFromOperationValue('return'), MovementType.returned);
      expect(movementTypeFromOperationValue('adjust'), MovementType.adjustment);
      expect(movementTypeFromOperationValue('future_type'), isNull);

      final adjustment = InventoryMovement.tryFromMovementViewRow(
        _movementRow(
          id: 'adjustment',
          tableName: 'paints',
          itemId: firstId,
          operationType: 'adjust',
          quantity: 4,
          before: 10,
          after: 6,
        ),
      )!;
      expect(adjustment.quantity, -4);

      expect(
        InventoryMovement.tryFromMovementViewRow(
          _movementRow(
            id: 'unknown',
            tableName: 'paints',
            itemId: firstId,
            operationType: 'future_type',
          ),
        ),
        isNull,
      );
    });
  });

  group('SupabaseMovementHistoryRepository', () {
    test('looks up only by table name plus item id', () async {
      final source = _FakeMovementSource(
        rows: {
          ('paints', firstId): [
            _movementRow(
              id: 'movement-1',
              tableName: 'paints',
              itemId: firstId,
            ),
          ],
        },
      );
      final repository = SupabaseMovementHistoryRepository(source);

      final result = await repository.fetchMovements(
        const MovementHistoryQuery(itemRouteId: firstRouteId),
      );
      final page = (result as DataSuccess<PageResult<InventoryMovement>>).value;

      expect(source.requests, hasLength(1));
      expect(source.requests.single.identity.tableName, 'paints');
      expect(source.requests.single.identity.itemId, firstId);
      expect(page.items.single.id, 'movement-1');
    });

    test(
      'uses deterministic newest-first ordering without client reordering',
      () async {
        expect(
          MovementHistoryRemoteQuery.orderColumns
              .map((order) => '${order.column}:${order.ascending}')
              .toList(),
          ['operation_date:false', 'created_at:false', 'id:false'],
        );

        final source = _FakeMovementSource(
          rows: {
            ('paints', firstId): [
              for (final id in ['newest', 'middle', 'oldest'])
                _movementRow(id: id, tableName: 'paints', itemId: firstId),
            ],
          },
        );
        final result = await SupabaseMovementHistoryRepository(
          source,
        ).fetchMovements(const MovementHistoryQuery(itemRouteId: firstRouteId));
        final page =
            (result as DataSuccess<PageResult<InventoryMovement>>).value;

        expect(page.items.map((movement) => movement.id), [
          'newest',
          'middle',
          'oldest',
        ]);
      },
    );

    test(
      'uses bounded look-ahead pagination and opaque offset cursors',
      () async {
        final source = _FakeMovementSource(
          rows: {
            ('paints', firstId): [
              for (var index = 0; index < 25; index++)
                _movementRow(
                  id: 'movement-$index',
                  tableName: 'paints',
                  itemId: firstId,
                ),
            ],
          },
        );
        final repository = SupabaseMovementHistoryRepository(source);

        final first = await repository.fetchMovements(
          const MovementHistoryQuery(itemRouteId: firstRouteId),
        );
        final firstPage =
            (first as DataSuccess<PageResult<InventoryMovement>>).value;
        final second = await repository.fetchMovements(
          MovementHistoryQuery(
            itemRouteId: firstRouteId,
            page: PageRequest(cursor: firstPage.nextCursor),
          ),
        );
        final secondPage =
            (second as DataSuccess<PageResult<InventoryMovement>>).value;

        expect(firstPage.items, hasLength(20));
        expect(firstPage.nextCursor, '20');
        expect(source.requests.first.fetchLimit, 21);
        expect(source.requests.first.rangeEnd, 20);
        expect(secondPage.items, hasLength(5));
        expect(secondPage.nextCursor, isNull);
      },
    );

    test('returns an empty successful page', () async {
      final result = await SupabaseMovementHistoryRepository(
        _FakeMovementSource(),
      ).fetchMovements(const MovementHistoryQuery(itemRouteId: firstRouteId));

      final page = (result as DataSuccess<PageResult<InventoryMovement>>).value;
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('rejects malformed identity and cursor before querying', () async {
      final source = _FakeMovementSource();
      final repository = SupabaseMovementHistoryRepository(source);

      final malformed = await repository.fetchMovements(
        const MovementHistoryQuery(itemRouteId: 'DUPLICATE-CODE'),
      );
      final badCursor = await repository.fetchMovements(
        const MovementHistoryQuery(
          itemRouteId: firstRouteId,
          page: PageRequest(cursor: 'invalid'),
        ),
      );

      expect((malformed as DataError).failure.kind, DataFailureKind.unknown);
      expect((badCursor as DataError).failure.kind, DataFailureKind.unknown);
      expect(source.requests, isEmpty);
    });

    test('maps Supabase failures without exposing raw details', () async {
      final failures = <Object, DataFailureKind>{
        ClientException('raw connection detail'): DataFailureKind.offline,
        const PostgrestException(message: 'raw policy detail', code: '42501'):
            DataFailureKind.unavailable,
        const PostgrestException(message: 'raw server detail', code: 'XX000'):
            DataFailureKind.server,
        StateError('raw unknown detail'): DataFailureKind.unknown,
      };

      for (final MapEntry(key: error, value: kind) in failures.entries) {
        final result = await SupabaseMovementHistoryRepository(
          _FakeMovementSource(error: error),
        ).fetchMovements(const MovementHistoryQuery(itemRouteId: firstRouteId));
        final failure = (result as DataError).failure;
        expect(failure.kind, kind);
        expect(failure.message, isNot(contains('raw')));
      }
    });

    test('duplicate display codes return independent histories', () async {
      final source = _FakeMovementSource(
        rows: {
          ('paints', firstId): [
            _movementRow(
              id: 'paint-history',
              tableName: 'paints',
              itemId: firstId,
            ),
          ],
          ('screws', secondId): [
            _movementRow(
              id: 'screw-history',
              tableName: 'screws',
              itemId: secondId,
            ),
          ],
        },
      );
      final repository = SupabaseMovementHistoryRepository(source);

      final first = await repository.fetchMovements(
        const MovementHistoryQuery(itemRouteId: firstRouteId),
      );
      final second = await repository.fetchMovements(
        const MovementHistoryQuery(itemRouteId: secondRouteId),
      );

      expect(
        (first as DataSuccess<PageResult<InventoryMovement>>)
            .value
            .items
            .single
            .id,
        'paint-history',
      );
      expect(
        (second as DataSuccess<PageResult<InventoryMovement>>)
            .value
            .items
            .single
            .id,
        'screw-history',
      );
    });
  });

  test('selects PreviewData only when no Supabase client is configured', () {
    expect(
      MovementHistoryRepositoryFactory.create(null),
      isA<PreviewInventoryRepository>(),
    );

    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_example',
    );
    expect(
      MovementHistoryRepositoryFactory.create(client),
      isA<SupabaseMovementHistoryRepository>(),
    );
    client.dispose();
  });

  testWidgets('direct live history route resolves stable item identity', (
    tester,
  ) async {
    final item = InventoryItem.fromInventorySummaryRow(
      _itemRow(tableName: 'paints', itemId: firstId),
    );
    final itemRepository = _FakeItemDetailsRepository(item);
    final movementRepository = _FakeMovementRepository(
      InventoryMovement.tryFromMovementViewRow(
        _movementRow(
          id: 'direct-history',
          tableName: 'paints',
          itemId: firstId,
        ),
      )!,
    );
    final appRouter = AppRouter(
      previewLoadDelay: Duration.zero,
      itemDetailsRepository: itemRepository,
      movementHistoryRepository: movementRepository,
    );
    addTearDown(appRouter.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter.router));
    await tester.pumpAndSettle();
    appRouter.router.go('/inventory/$firstRouteId/history');
    await tester.pumpAndSettle();

    expect(itemRepository.routeIds, [firstRouteId]);
    expect(movementRepository.routeIds, [firstRouteId]);
    expect(find.byKey(const Key('movement-history-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('direct-history')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'live Item Details opens history without resolving the item twice',
    (tester) async {
      final item = InventoryItem.fromInventorySummaryRow(
        _itemRow(tableName: 'paints', itemId: firstId),
      );
      final itemRepository = _FakeItemDetailsRepository(item);
      final movementRepository = _FakeMovementRepository(
        InventoryMovement.tryFromMovementViewRow(
          _movementRow(
            id: 'linked-history',
            tableName: 'paints',
            itemId: firstId,
          ),
        )!,
      );
      final appRouter = AppRouter(
        previewLoadDelay: Duration.zero,
        itemDetailsRepository: itemRepository,
        movementHistoryRepository: movementRepository,
      );
      addTearDown(appRouter.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pumpAndSettle();
      appRouter.router.go('/inventory/$firstRouteId');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('item-details-list')), findsOneWidget);
      expect(movementRepository.routeIds, [firstRouteId]);
      final detailsScrollable = find.descendant(
        of: find.byKey(const Key('item-details-list')),
        matching: find.byType(Scrollable),
      );
      final position = tester
          .state<ScrollableState>(detailsScrollable)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      final historyLink = find.byKey(const Key('open-movement-history'));
      await tester.ensureVisible(historyLink);
      await tester.tap(historyLink);
      await tester.pumpAndSettle();

      expect(itemRepository.routeIds, [firstRouteId]);
      expect(movementRepository.routeIds, [firstRouteId, firstRouteId]);
      expect(movementRepository.queries.map((query) => query.page.limit), [
        2,
        20,
      ]);
      expect(find.byKey(const Key('movement-history-list')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, dynamic> _movementRow({
  required String id,
  required String tableName,
  required String itemId,
  String operationType = 'issue',
  Object quantity = 3,
  Object before = 10,
  Object after = 7,
  String? supplier,
}) {
  return {
    'id': id,
    'table_name': tableName,
    'category_name': 'Category',
    'category_label': 'Category',
    'item_id': itemId,
    'item_name': 'Shared display item',
    'item_label': 'Shared display item',
    'project_name': 'Project A',
    'project': 'Project A',
    'operation_type': operationType,
    'quantity': quantity,
    'operation_date': '2026-10-13',
    'previous_balance': before,
    'new_balance': after,
    'supplier_name': supplier,
    'issued_to': 'Employee A',
    'received_by': 'Receiver A',
    'purchase_order_number': 'PO-1',
    'item_code': 'DUPLICATE-CODE',
    'notes': 'Read only',
    'created_at': '2026-10-13T12:00:00Z',
    'code_number': null,
    'internal_code': 'DUPLICATE-CODE',
  };
}

Map<String, dynamic> _itemRow({
  required String tableName,
  required String itemId,
}) {
  return {
    'table_name': tableName,
    'category_name': 'Category',
    'item_id': itemId,
    'item_key': 'item-key',
    'project_name': 'Project A',
    'item_name': 'Direct live item',
    'stock_balance': 7,
    'min_quantity': 2,
    'supplier_name': null,
    'expire_date': null,
    'notes': null,
    'updated_at': '2026-10-13T10:00:00Z',
    'code_number': null,
    'internal_code': 'DUPLICATE-CODE',
  };
}

class _FakeMovementSource implements MovementHistoryRemoteDataSource {
  _FakeMovementSource({this.rows = const {}, this.error});

  final Map<(String, String), List<Map<String, dynamic>>> rows;
  final Object? error;
  final List<MovementHistoryRemoteQuery> requests = [];

  @override
  Future<List<Map<String, dynamic>>> fetchMovements(
    MovementHistoryRemoteQuery query,
  ) async {
    requests.add(query);
    if (error case final error?) throw error;
    final matching =
        rows[(query.identity.tableName, query.identity.itemId)] ??
        const <Map<String, dynamic>>[];
    return matching
        .skip(query.offset)
        .take(query.fetchLimit)
        .toList(growable: false);
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

class _FakeMovementRepository implements MovementHistoryRepository {
  _FakeMovementRepository(this.movement);

  final InventoryMovement movement;
  final List<MovementHistoryQuery> queries = [];
  List<String> get routeIds =>
      queries.map((query) => query.itemRouteId).toList(growable: false);

  @override
  Future<DataResult<PageResult<InventoryMovement>>> fetchMovements(
    MovementHistoryQuery query,
  ) async {
    queries.add(query);
    return DataSuccess(PageResult(items: [movement]));
  }
}
