import 'package:el_fateh/app.dart';
import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/theme/app_theme.dart';
import 'package:el_fateh/features/alerts/controller/alerts_controller.dart';
import 'package:el_fateh/features/alerts/view/alerts_view.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pumpAlerts(
  AlertsController controller, {
  ValueChanged<InventoryItem>? onOpen,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: AlertsView(controller: controller, onOpenItem: onOpen ?? (_) {}),
      ),
    ),
  );
}

void main() {
  testWidgets('alerts shows summary counts and attention list', (tester) async {
    final controller = AlertsController(PreviewData.alertItems);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpAlerts(controller));
    await tester.pumpAndSettle();

    expect(find.text('تنبيهات المخزون'), findsOneWidget);
    expect(find.text('مخزون منخفض'), findsOneWidget);
    expect(find.text('نفد المخزون'), findsOneWidget);
    expect(find.text('14'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('اسطوانة أكسجين صناعي'), findsOneWidget);
    expect(find.text('مسامير قلاووظ ٦ مم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alerts status filters narrow the list', (tester) async {
    final controller = AlertsController(PreviewData.alertItems);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpAlerts(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('alerts-status-نفد')));
    await tester.pumpAndSettle();
    expect(find.text('اسطوانة أكسجين صناعي'), findsOneWidget);
    expect(find.text('مسامير قلاووظ ٦ مم'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('alerts-status-منخفض')));
    await tester.pumpAndSettle();
    expect(find.text('مسامير قلاووظ ٦ مم'), findsOneWidget);
    expect(find.text('اسطوانة أكسجين صناعي'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('alerts-status-الكل')));
    await tester.pumpAndSettle();
    expect(find.text('اسطوانة أكسجين صناعي'), findsOneWidget);
    expect(find.text('مسامير قلاووظ ٦ مم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an alert item opens its details', (tester) async {
    final controller = AlertsController(PreviewData.alertItems);
    addTearDown(controller.dispose);

    InventoryItem? opened;
    await tester.pumpWidget(
      _pumpAlerts(controller, onOpen: (item) => opened = item),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('اسطوانة أكسجين صناعي'));
    await tester.pumpAndSettle();
    expect(opened?.code, 'GS-OX-004');
  });

  testWidgets('alerts item tap navigates to item details through go_router', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    expect(find.text('تنبيهات المخزون'), findsOneWidget);

    final alertsList = find.byKey(const PageStorageKey('alerts-list'));
    final target = find.descendant(
      of: alertsList,
      matching: find.text('اسطوانة أكسجين صناعي'),
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الصنف'), findsOneWidget);
    expect(find.text('الرصيد الحالي'), findsOneWidget);
  });

  testWidgets('alerts shows a friendly state when stock is healthy', (
    tester,
  ) async {
    final controller = AlertsController(const []);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpAlerts(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alerts-empty-state')), findsOneWidget);
    expect(find.text('المخزون بحالة جيدة'), findsOneWidget);
    expect(find.text('لا توجد أصناف تحتاج انتباهك حاليًا'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alerts shows a no-match state for an empty filter', (
    tester,
  ) async {
    final controller = AlertsController(
      PreviewData.alertItems
          .where((item) => item.status == StockStatus.low)
          .toList(growable: false),
    );
    addTearDown(controller.dispose);

    controller.selectStatus(StockStatus.outOfStock);
    await tester.pumpWidget(_pumpAlerts(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alerts-empty-state')), findsOneWidget);
    expect(find.text('لا توجد تنبيهات مطابقة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(392, 812), Size(600, 1024)]) {
    testWidgets('alerts remains responsive at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final controller = AlertsController(PreviewData.alertItems);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_pumpAlerts(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('تنبيهات المخزون'), findsOneWidget);

      final scrollable = find.descendant(
        of: find.byKey(const PageStorageKey('alerts-list')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
