import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/features/reports/controller/reports_controller.dart';
import 'package:el_fateh/features/reports/model/report_filter.dart';
import 'package:el_fateh/features/reports/widgets/report_date_range_picker.dart';
import 'package:el_fateh/features/reports/widgets/report_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reports date range filter works on a narrow screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = ReportsController(PreviewData.reportMovements);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, child) =>
                  ReportFilters(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('report-date-filter')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDateRangePicker), findsOneWidget);
    expect(tester.takeException(), isNull);

    final month = DateTime.now();
    await tester.tap(
      find.byKey(ValueKey('report-date-${month.year}-${month.month}-13')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(ValueKey('report-date-${month.year}-${month.month}-15')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-report-date-range')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportDateRangePicker), findsNothing);
    expect(controller.period, ReportPeriod.custom);
    expect(tester.takeException(), isNull);
  });
}
