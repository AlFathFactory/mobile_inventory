import 'package:el_fateh/app.dart';
import 'package:el_fateh/features/inventory/widgets/inventory_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets('renders Arabic RTL dashboard and navigates across all tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    final titleContext = tester.element(find.text('نظرة عامة').first);
    expect(Directionality.of(titleContext), TextDirection.rtl);
    expect(find.text('إجمالي الأصناف'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();
    expect(find.text('ابحث باسم الصنف أو الكود'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    expect(find.text('تنبيهات المخزون'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    expect(find.text('إجمالي الحركات'), findsOneWidget);
  });

  testWidgets('preserves inventory search while switching tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory-search')),
      'GS-OX-004',
    );
    await tester.pump();
    expect(find.text('اسطوانة أكسجين صناعي'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();

    final search = tester.widget<TextField>(
      find.byKey(const Key('inventory-search')),
    );
    expect(search.controller?.text, 'GS-OX-004');
  });

  testWidgets('applies the out-of-stock inventory filter sheet', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-inventory-filters')));
    await tester.pumpAndSettle();
    final sheet = find.byType(InventoryFilterSheet);
    expect(sheet, findsOneWidget);

    await tester.tap(
      find.descendant(of: sheet, matching: find.text('نفد')).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('apply-inventory-filters')));
    await tester.pumpAndSettle();

    expect(find.text('اسطوانة أكسجين صناعي'), findsOneWidget);
    expect(find.text('هيمباريم 500 × 16 لتر رال 7032'), findsNothing);
  });

  testWidgets('opens item details and history through go_router', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('هيمباريم 500 × 16 لتر رال 7032').first);
    await tester.pumpAndSettle();
    expect(find.text('تفاصيل الصنف'), findsOneWidget);
    expect(find.text('شركة يوتن مصر'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('open-movement-history')),
      280,
      scrollable: find.descendant(
        of: find.byKey(const Key('item-details-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('open-movement-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movement-history-list')), findsOneWidget);
    expect(find.text('صرف'), findsOneWidget);
  });

  testWidgets('enables the app-level skeleton before preview data loads', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Skeletonizer && widget.enabled,
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Skeletonizer && widget.enabled,
      ),
      findsNothing,
    );
  });

  for (final size in const [Size(320, 568), Size(392, 812), Size(600, 1024)]) {
    testWidgets('has no layout exceptions at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final destinationKey in [
        const Key('nav-inventory'),
        const Key('nav-alerts'),
        const Key('nav-reports'),
      ]) {
        await tester.tap(find.byKey(destinationKey));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
