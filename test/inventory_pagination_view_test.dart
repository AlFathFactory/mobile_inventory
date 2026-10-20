import 'package:el_fateh/app.dart';
import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/features/inventory/data/models/inventory_query.dart';
import 'package:el_fateh/features/inventory/data/repositories/inventory_repository.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a short first page does not automatically drain pagination', (
    tester,
  ) async {
    final repository = _PagedRepository();
    await tester.pumpWidget(
      MyApp(previewLoadDelay: Duration.zero, inventoryRepository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();

    expect(repository.requests, 1);
    expect(find.text('عرض المزيد'), findsOneWidget);
    await tester.drag(
      find.byKey(const PageStorageKey('inventory-list')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(repository.requests, 1);

    await tester.tap(find.text('عرض المزيد'));
    await tester.pumpAndSettle();
    expect(repository.requests, 2);
    expect(find.text('عرض المزيد'), findsNothing);
  });
}

class _PagedRepository implements InventoryRepository {
  int requests = 0;

  @override
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  ) async {
    requests++;
    return DataSuccess(
      PageResult(
        items: [PreviewData.catalogItems[query.page.cursor == null ? 0 : 1]],
        nextCursor: query.page.cursor == null ? '1' : null,
      ),
    );
  }

  @override
  Future<DataResult<List<String>>> fetchCategories() async =>
      const DataSuccess([]);
}
