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
