import 'package:el_fateh/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard previews movements and opens reports', (tester) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    final dashboardList = find.byKey(const PageStorageKey('dashboard-list'));
    final dashboardScrollable = find
        .descendant(of: dashboardList, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.text('يحتاج انتباهك'),
      300,
      scrollable: dashboardScrollable,
    );
    expect(find.text('يحتاج انتباهك'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('أحدث حركات المخزون'),
      300,
      scrollable: dashboardScrollable,
    );
    expect(find.text('أحدث حركات المخزون'), findsOneWidget);

    final reportsButton = find.byKey(const Key('open-reports-from-dashboard'));
    await tester.scrollUntilVisible(
      reportsButton,
      300,
      scrollable: dashboardScrollable,
    );
    await tester.tap(reportsButton);
    await tester.pumpAndSettle();

    expect(find.text('التقارير'), findsWidgets);
  });
}
