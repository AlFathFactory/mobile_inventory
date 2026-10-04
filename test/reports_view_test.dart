import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/theme/app_theme.dart';
import 'package:el_fateh/features/inventory/model/inventory_movement.dart';
import 'package:el_fateh/features/reports/controller/reports_controller.dart';
import 'package:el_fateh/features/reports/model/report_filter.dart';
import 'package:el_fateh/features/reports/view/reports_view.dart';
import 'package:el_fateh/features/reports/widgets/report_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pumpReports(ReportsController controller) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: ReportsView(controller: controller)),
    ),
  );
}

void main() {
  testWidgets('reports shows header, overview and movements', (tester) async {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpReports(controller));
    await tester.pumpAndSettle();

    expect(find.text('التقارير'), findsOneWidget);
    expect(find.byKey(const Key('reports-overview')), findsOneWidget);
    // Total appears once in the header badge and once in the overview.
    expect(find.text('128'), findsNWidgets(2));
    expect(find.text('هيمباريم 500 × 16 لتر رال 7032'), findsOneWidget);
    expect(find.text('سلك لحام ٣.٢ مم'), findsOneWidget);
    expect(find.text('كابل كهرباء ٢.٥ مم'), findsOneWidget);
    expect(find.text('3 من الحركات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports keeps item codes LTR', (tester) async {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpReports(controller));
    await tester.pumpAndSettle();

    final codeContext = tester.element(find.text('PA-GN-059'));
    expect(Directionality.of(codeContext), TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports movement type filter narrows the list', (tester) async {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpReports(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-more-report-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-movement-صرف')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('apply-report-filters')));
    await tester.pumpAndSettle();

    expect(find.text('هيمباريم 500 × 16 لتر رال 7032'), findsOneWidget);
    expect(find.text('سلك لحام ٣.٢ مم'), findsNothing);
    expect(find.text('1 من الحركات'), findsOneWidget);
    expect(find.byKey(const Key('clear-reports-inline')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports project and category filters narrow the list', (
    tester,
  ) async {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    controller.selectProject('AMSET 2');
    await tester.pumpWidget(_pumpReports(controller));
    await tester.pumpAndSettle();

    expect(find.text('كابل كهرباء ٢.٥ مم'), findsOneWidget);
    expect(find.text('سلك لحام ٣.٢ مم'), findsNothing);

    controller.selectProject(null);
    controller.selectCategory('مخزن اللحام');
    await tester.pumpAndSettle();

    expect(find.text('سلك لحام ٣.٢ مم'), findsOneWidget);
    expect(find.text('كابل كهرباء ٢.٥ مم'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports period selector switches preset periods', (
    tester,
  ) async {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpReports(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reports-period-آخر 30 يوم')));
    await tester.pumpAndSettle();
    expect(controller.period, ReportPeriod.last30Days);
    expect(find.text('سلك لحام ٣.٢ مم'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reports-period-الكل')));
    await tester.pumpAndSettle();
    expect(controller.period, ReportPeriod.all);
    expect(find.text('كابل كهرباء ٢.٥ مم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports custom period opens the date picker', (tester) async {
    // Phone-sized surface: the date dialog is designed for handset heights
    // (it also overflows by 3px on the 800x600 desktop test surface
    // without any redesign changes).
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(392, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_pumpReports(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reports-period-مخصص')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDateRangePicker), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports empty range shows a no-match state and clears', (
    tester,
  ) async {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    controller.selectDateRange(
      DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
    );
    await tester.pumpWidget(_pumpReports(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reports-empty-state')), findsOneWidget);
    expect(find.text('لا توجد حركات مطابقة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-reports-inline')));
    await tester.pumpAndSettle();

    expect(find.text('سلك لحام ٣.٢ مم'), findsOneWidget);
    expect(controller.hasActiveFilters, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports controller filters are covered without UI', (
    tester,
  ) async {
    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);

    controller.selectType(MovementType.returned);
    expect(controller.visibleMovements.single.itemCode, 'EL-CB-025');

    controller.selectType(null);
    expect(controller.visibleMovements, hasLength(3));
  });

  for (final size in const [Size(320, 568), Size(392, 812), Size(600, 1024)]) {
    testWidgets('reports remains responsive at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final controller = ReportsController(PreviewData.reportMovements);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_pumpReports(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('التقارير'), findsOneWidget);

      final scrollable = find.descendant(
        of: find.byKey(const PageStorageKey('reports-list')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
