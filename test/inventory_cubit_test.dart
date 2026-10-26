import 'dart:async';

import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/features/inventory/cubit/inventory_cubit.dart';
import 'package:el_fateh/features/inventory/data/models/inventory_query.dart';
import 'package:el_fateh/features/inventory/data/repositories/inventory_repository.dart';
import 'package:el_fateh/features/inventory/data/repositories/preview_inventory_repository.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryCubit', () {
    test(
      'keeps typed text and deduplicates equivalent live searches',
      () async {
        final queries = <InventoryQuery>[];
        final cubit = InventoryCubit(
          items: const [],
          serverBacked: true,
          initiallyLoading: false,
          searchDebounce: const Duration(milliseconds: 1),
          repository: _FakeInventoryRepository((query) {
            queries.add(query);
            return DataSuccess(PageResult<InventoryItem>(items: []));
          }),
        );
        addTearDown(cubit.close);

        cubit.setQuery('\u0639\u0628\u0648\u0629 WD 40');
        cubit.setQuery('\u0639\u0628\u0648\u0629wd40');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(cubit.state.query, '\u0639\u0628\u0648\u0629wd40');
        expect(queries, hasLength(1));
        expect(queries.single.search, '\u0639\u0628\u0648\u0647wd40');
      },
    );

    test('loads the preview repository fallback', () async {
      final cubit = InventoryCubit(
        items: PreviewData.catalogItems,
        repository: const PreviewInventoryRepository(),
      );
      addTearDown(cubit.close);

      await cubit.loadPreviewData(delay: Duration.zero);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.visibleItems, hasLength(6));
    });

    test(
      'appends live pages and prevents concurrent load-more requests',
      () async {
        final nextPage = Completer<DataResult<PageResult<InventoryItem>>>();
        var requests = 0;
        final cubit = InventoryCubit(
          items: const [],
          serverBacked: true,
          initiallyLoading: false,
          repository: _FakeInventoryRepository((_) {
            requests++;
            return requests == 1
                ? DataSuccess(
                    PageResult(
                      items: [PreviewData.catalogItems[0]],
                      nextCursor: 'next',
                    ),
                  )
                : nextPage.future;
          }),
        );
        addTearDown(cubit.close);

        await cubit.reload();
        unawaited(cubit.loadNextPage());
        unawaited(cubit.loadNextPage());
        await Future<void>.delayed(Duration.zero);

        expect(requests, 2);
        expect(cubit.state.isLoadingMore, isTrue);
        nextPage.complete(
          DataSuccess(PageResult(items: [PreviewData.catalogItems[1]])),
        );
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.items, hasLength(2));
        expect(cubit.state.hasMore, isFalse);
        expect(cubit.state.isLoadingMore, isFalse);
      },
    );

    test('ignores a stale live response after filters change', () async {
      final first = Completer<DataResult<PageResult<InventoryItem>>>();
      var requests = 0;
      final cubit = InventoryCubit(
        items: const [],
        serverBacked: true,
        initiallyLoading: false,
        repository: _FakeInventoryRepository((_) {
          requests++;
          return requests == 1
              ? first.future
              : DataSuccess(PageResult(items: [PreviewData.catalogItems[1]]));
        }),
      );
      addTearDown(cubit.close);

      unawaited(cubit.reload());
      await Future<void>.delayed(Duration.zero);
      cubit.filterByCategory(PreviewData.catalogItems[1].category);
      await Future<void>.delayed(Duration.zero);
      first.complete(
        DataSuccess(PageResult(items: [PreviewData.catalogItems[0]])),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state.items.single.routeId,
        PreviewData.catalogItems[1].routeId,
      );
    });

    test('a failed next page keeps its cursor and can be retried', () async {
      final cursors = <String?>[];
      var attempts = 0;
      final cubit = InventoryCubit(
        serverBacked: true,
        initiallyLoading: false,
        repository: _FakeInventoryRepository((query) {
          cursors.add(query.page.cursor);
          if (query.page.cursor == null) {
            return DataSuccess(
              PageResult(items: [PreviewData.catalogItems[0]], nextCursor: '1'),
            );
          }
          attempts++;
          return attempts == 1
              ? const DataError(
                  DataFailure(
                    kind: DataFailureKind.offline,
                    message: 'offline',
                  ),
                )
              : DataSuccess(
                  PageResult(
                    items: [
                      PreviewData.catalogItems[0],
                      PreviewData.catalogItems[1],
                    ],
                  ),
                );
        }),
      );
      addTearDown(cubit.close);

      await cubit.reload();
      await cubit.loadNextPage();
      expect(cubit.state.loadMoreFailure, isNotNull);
      expect(cubit.state.nextCursor, '1');
      expect(cubit.state.items, hasLength(1));

      await cubit.loadNextPage();
      expect(cursors, [null, '1', '1']);
      expect(cubit.state.items, hasLength(2));
      expect(
        cubit.state.items.map((item) => item.routeId).toSet(),
        hasLength(2),
      );
      expect(cubit.state.hasMore, isFalse);
    });

    test('failed manual refresh preserves the visible list', () async {
      var requests = 0;
      final repository = _FakeInventoryRepository((_) {
        requests++;
        if (requests == 1) {
          return DataSuccess(PageResult(items: [PreviewData.catalogItems[0]]));
        }
        return const DataError(
          DataFailure(kind: DataFailureKind.offline, message: 'offline'),
        );
      });
      final cubit = InventoryCubit(
        serverBacked: true,
        initiallyLoading: false,
        repository: repository,
      );
      addTearDown(cubit.close);
      await cubit.reload();

      await cubit.refresh();
      expect(cubit.state.items, hasLength(1));

      expect(cubit.state.isRefreshing, isFalse);
      expect(cubit.state.refreshFailure?.kind, DataFailureKind.offline);
      expect(cubit.state.items, hasLength(1));
    });
  });
}

class _FakeInventoryRepository implements InventoryRepository {
  _FakeInventoryRepository(this._fetch);

  final FutureOr<DataResult<PageResult<InventoryItem>>> Function(InventoryQuery)
  _fetch;

  @override
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  ) async => _fetch(query);

  @override
  Future<DataResult<List<String>>> fetchCategories() async =>
      const DataSuccess([]);
}
