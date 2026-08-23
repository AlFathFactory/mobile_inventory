import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:el_fateh/features/inventory/widgets/inventory_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact inventory card shows only essential item data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const item = InventoryItem(
      code: 'PA-GN-059-LONG',
      name: 'هيمباريم 500 × 16 لتر رال 7032 للاستخدام الصناعي',
      category: 'الدهانات والمواد الكيميائية',
      project: 'AMSET 4 - المخزن الرئيسي',
      quantity: 8,
      minimum: 20,
      supplier: 'شركة يوتن مصر لمواد الطلاء الصناعي',
      expiry: 'مارس 2027',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: InventoryItemCard(item: item),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(item.name), findsOneWidget);
    expect(find.text(item.code), findsOneWidget);
    expect(find.text('${item.quantity}'), findsOneWidget);
    expect(find.text(item.category), findsNothing);
    expect(find.text(item.project), findsNothing);
    expect(find.text(item.supplier!), findsNothing);
    expect(find.text(item.expiry!), findsNothing);
  });
}
