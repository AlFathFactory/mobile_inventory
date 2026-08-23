import 'package:el_fateh/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard previews movements and opens reports', (tester) async {
    await tester.pumpWidget(const MyApp(previewLoadDelay: Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('أصناف تحتاج الانتباه'), findsNothing);
    expect(find.text('أحدث حركات المخزون'), findsOneWidget);

    final reportsButton = find.byKey(const Key('open-reports-from-dashboard'));
    await tester.scrollUntilVisible(
      reportsButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(reportsButton);
    await tester.pumpAndSettle();

    expect(find.text('إجمالي الحركات'), findsOneWidget);
  });
}
