import 'package:el_fateh/app.dart';
import 'package:el_fateh/core/router/app_router.dart';
import 'package:el_fateh/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inventory context survives detail and history back navigation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('inventory-search')),
      'PA-GN-059',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('هيمباريم 500 × 16 لتر رال 7032'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-details-list')), findsOneWidget);

    final details = find.descendant(
      of: find.byKey(const Key('item-details-list')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(details).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    final historyLink = find.byKey(const Key('open-movement-history'));
    await tester.ensureVisible(historyLink);
    await tester.pumpAndSettle();
    await tester.tap(historyLink);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movement-history-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('movement-history-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-details-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('item-details-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inventory-search')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('inventory-search')))
          .controller
          ?.text,
      'PA-GN-059',
    );
  });

  testWidgets('system back returns to filtered alerts', (tester) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-alerts')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('alerts-status-نفد')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اسطوانة أكسجين صناعي'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-details-list')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const PageStorageKey('alerts-list')), findsOneWidget);
    expect(find.text('مسامير قلاووظ ٦ مم'), findsNothing);
  });

  testWidgets('invalid item routes provide a safe route back to dashboard', (
    tester,
  ) async {
    final appRouter = AppRouter(previewLoadDelay: Duration.zero);
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter.router));
    await tester.pumpAndSettle();

    appRouter.router.go('/inventory/missing-item');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('not-found-dashboard')), findsOneWidget);

    await tester.tap(find.byKey(const Key('not-found-dashboard')));
    await tester.pumpAndSettle();
    expect(
      appRouter.router.routeInformationProvider.value.uri.path,
      AppRoutePaths.dashboard,
    );
  });

  testWidgets('rapid item taps add only one detail page', (tester) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();

    final item = find.text('هيمباريم 500 × 16 لتر رال 7032');
    await tester.tap(item);
    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('item-details-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('item-details-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inventory-search')), findsOneWidget);
  });

  testWidgets('report filters persist while another tab is opened', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-more-report-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-movement-صرف')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('apply-report-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clear-reports-inline')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-dashboard')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clear-reports-inline')), findsOneWidget);
  });
}
