import 'package:el_fateh/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all primary screens support compact width and text scaling', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final destinationKey in const [
      Key('nav-inventory'),
      Key('nav-alerts'),
      Key('nav-reports'),
    ]) {
      await tester.tap(find.byKey(destinationKey));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'layout overflow after opening $destinationKey',
      );
    }
  });

  testWidgets('inventory item codes keep LTR direction inside Arabic UI', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();

    final codeContext = tester.element(find.text('PA-GN-059'));
    expect(Directionality.of(codeContext), TextDirection.ltr);
  });

  testWidgets('item details and history scale on a compact screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();

    final itemName = find.text('هيمباريم 500 × 16 لتر رال 7032').first;
    await tester.ensureVisible(itemName);
    await tester.pumpAndSettle();
    await tester.tap(itemName);
    await tester.pumpAndSettle();
    expect(find.text('تفاصيل الصنف'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final detailsList = find.byKey(const Key('item-details-list'));
    final detailsScrollable = find
        .descendant(of: detailsList, matching: find.byType(Scrollable))
        .first;
    final detailsPosition = tester
        .state<ScrollableState>(detailsScrollable)
        .position;
    detailsPosition.jumpTo(detailsPosition.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-movement-history')));
    await tester.pumpAndSettle();

    expect(find.text('سجل الحركات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
