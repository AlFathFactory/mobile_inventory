import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/theme/app_theme.dart';
import 'package:el_fateh/features/inventory/model/inventory_movement.dart';
import 'package:el_fateh/features/inventory/view/movement_history_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pumpHistory({
  String code = 'PA-GN-059',
  List<InventoryMovement>? movements,
}) {
  final item = PreviewData.itemByCode(code);
  return MaterialApp(
    theme: AppTheme.light,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: MovementHistoryView(
        item: item,
        movements: movements ?? PreviewData.movementsFor(item.code),
      ),
    ),
  );
}

void main() {
  testWidgets('history renders every movement type with balance', (
    tester,
  ) async {
    await tester.pumpWidget(_pumpHistory());
    await tester.pumpAndSettle();

    expect(find.text('سجل الحركات'), findsOneWidget);
    expect(find.text('هيمباريم 500 × 16 لتر رال 7032'), findsOneWidget);
    // Each type appears once in the summary pills and once in the timeline.
    for (final label in ['إضافة', 'صرف', 'مرتجع', 'تسوية']) {
      expect(find.text(label), findsNWidgets(2));
    }
    // Signed quantities and resulting balances.
    expect(find.text('+40'), findsOneWidget);
    expect(find.text('-10'), findsOneWidget);
    expect(find.text('الرصيد'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history shows metadata only when available', (tester) async {
    await tester.pumpWidget(_pumpHistory());
    await tester.pumpAndSettle();

    expect(find.textContaining('عمرو فايز'), findsOneWidget);
    expect(find.textContaining('PO-2231'), findsOneWidget);
    expect(find.textContaining('تصحيح بعد الجرد الدوري'), findsOneWidget);

    // A movement without optional fields renders no order/note rows.
    final bare = InventoryMovement(
      id: 'bare',
      itemCode: 'HW-SC-112',
      itemName: 'مسامير قلاووظ ٦ مم',
      category: 'مسامير',
      type: MovementType.issue,
      quantity: 2,
      before: 10,
      after: 8,
      date: DateTime(2026, 8, 1),
      project: 'مخزن عام',
    );
    await tester.pumpWidget(_pumpHistory(movements: [bare]));
    await tester.pumpAndSettle();

    expect(find.text('صرف'), findsNWidgets(2));
    expect(find.textContaining('أمر الشراء'), findsNothing);
    expect(find.byIcon(Icons.notes_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history keeps item code and order numbers LTR', (tester) async {
    await tester.pumpWidget(_pumpHistory());
    await tester.pumpAndSettle();

    final codeContext = tester.element(find.text('PA-GN-059'));
    expect(Directionality.of(codeContext), TextDirection.ltr);

    final orderContext = tester.element(find.textContaining('PO-2231'));
    expect(Directionality.of(orderContext), TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history shows a summary and an empty state', (tester) async {
    await tester.pumpWidget(_pumpHistory());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movement-history-summary')), findsOneWidget);
    expect(find.text('ملخص السجل'), findsOneWidget);

    await tester.pumpWidget(_pumpHistory(movements: const []));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد حركات مسجلة لهذا الصنف.'), findsOneWidget);
    expect(find.byKey(const Key('movement-history-summary')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(392, 812), Size(600, 1024)]) {
    testWidgets('history remains responsive at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_pumpHistory());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final scrollable = find.descendant(
        of: find.byKey(const Key('movement-history-list')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('تسوية'), findsWidgets);
    });
  }
}
