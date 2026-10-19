import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/theme/app_theme.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:el_fateh/features/inventory/view/item_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(320, 568), Size(392, 812), Size(600, 1024)]) {
    testWidgets(
      'item details remains responsive at ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final item = PreviewData.itemByCode('PA-GN-059');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: ItemDetailsView(
                item: item,
                movements: PreviewData.movementsFor(item.code),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(item.name), findsOneWidget);
        expect(find.text(item.supplier!), findsOneWidget);
        expect(find.text('الرصيد الحالي'), findsOneWidget);

        final codeContext = tester.element(find.text(item.code));
        expect(Directionality.of(codeContext), TextDirection.ltr);

        final scrollable = find.descendant(
          of: find.byKey(const Key('item-details-list')),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(scrollable).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('item-notes-section')), findsOneWidget);
        expect(find.byKey(const Key('open-movement-history')), findsOneWidget);
      },
    );
  }

  testWidgets('item details hides notes and history entry when unavailable', (
    tester,
  ) async {
    final item = PreviewData.itemByCode('GS-OX-004');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ItemDetailsView(item: item, movements: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byKey(const Key('item-details-list')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    expect(find.byKey(const Key('item-notes-section')), findsNothing);
    expect(find.byKey(const Key('open-movement-history')), findsNothing);
    expect(find.text('لا توجد حركات مسجلة لهذا الصنف.'), findsOneWidget);
  });

  testWidgets('shows only populated category-specific attributes', (
    tester,
  ) async {
    const item = InventoryItem(
      code: 'RAW-1',
      name: 'Raw material',
      category: 'خامات',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'raw_materials',
      weight: '0',
      length: '2470',
      width: '380',
      thickness: '5',
      materialSource: 'Mill',
      codeNumber: 'D147',
      dimensionText: '2470 × 380 × 5',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ItemDetailsView(item: item, movements: []),
        ),
      ),
    );

    final attributes = find.byKey(
      const Key('item-category-attributes'),
      skipOffstage: false,
    );
    expect(attributes, findsOneWidget);
    expect(
      find.descendant(
        of: attributes,
        matching: find.text('0', skipOffstage: false),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: attributes,
        matching: find.text('D147', skipOffstage: false),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: attributes,
        matching: find.text('DIN', skipOffstage: false),
      ),
      findsNothing,
    );
  });

  testWidgets('does not show legacy attributes for dynamic items', (
    tester,
  ) async {
    const item = InventoryItem(
      code: 'DYNAMIC-1',
      name: 'Dynamic item',
      category: 'Dynamic',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'inventory_items',
      codeNumber: 'should-not-render',
      din: 'DIN 933',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ItemDetailsView(item: item, movements: []),
        ),
      ),
    );

    expect(find.byKey(const Key('item-category-attributes')), findsNothing);
    expect(find.text('should-not-render'), findsNothing);
    expect(find.text('DIN 933'), findsNothing);
  });

  test('maps category-specific fields only for their supported tables', () {
    const paints = InventoryItem(
      code: 'PAINT-1',
      name: 'Paint',
      category: 'الدهانات',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'paints',
      productionDate: '2026-10-05',
      expiry: '2027-10-05',
    );
    const screws = InventoryItem(
      code: 'SCREW-1',
      name: 'Screw',
      category: 'مسامير',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'screws',
      din: 'DIN 933',
      codeNumber: 'A123',
    );
    const stockScrews = InventoryItem(
      code: 'STOCK-SCREW-1',
      name: 'Stock screw',
      category: 'مسامير استوك',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'stock_screws',
      din: 'DIN 7991',
      codeNumber: 'B456',
    );
    const consumables = InventoryItem(
      code: 'CONSUMABLE-1',
      name: 'Consumable',
      category: 'مستهلكات',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'consumables',
      din: 'must not render',
      codeNumber: 'must not render',
    );
    const rawMaterial = InventoryItem(
      code: 'RAW-2',
      name: 'Raw material with DIN',
      category: 'Raw',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'raw_materials',
      weight: '0',
      length: '2470',
      width: '380',
      thickness: '5',
      materialSource: 'Mill',
      codeNumber: 'D147',
      dimensionText: '2470 x 380 x 5',
      din: 'DIN 100',
    );
    const paintWithoutDates = InventoryItem(
      code: 'PAINT-2',
      name: 'Paint without dates',
      category: 'Paint',
      project: 'Project',
      quantity: 1,
      minimum: 0,
      tableName: 'paints',
      productionDate: ' ',
      expiry: '',
    );

    expect(
      paints.categorySpecificAttributes.map((attribute) => attribute.value),
      ['2026-10-05', '2027-10-05'],
    );
    expect(
      screws.categorySpecificAttributes.map((attribute) => attribute.value),
      ['DIN 933', 'A123'],
    );
    expect(
      stockScrews.categorySpecificAttributes.map(
        (attribute) => attribute.value,
      ),
      ['DIN 7991', 'B456'],
    );
    expect(
      rawMaterial.categorySpecificAttributes.map(
        (attribute) => attribute.value,
      ),
      ['0', '2470', '380', '5', 'Mill', 'D147', '2470 x 380 x 5', 'DIN 100'],
    );
    expect(paintWithoutDates.categorySpecificAttributes, isEmpty);
    expect(consumables.categorySpecificAttributes, isEmpty);
  });
}
