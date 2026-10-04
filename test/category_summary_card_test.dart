import 'package:el_fateh/features/dashboard/model/dashboard_models.dart';
import 'package:el_fateh/features/dashboard/widgets/category_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category summary card fits its compact dashboard grid cell', (
    tester,
  ) async {
    const summary = CategorySummary(
      name: 'الدهانات والمواد الكيميائية',
      itemCount: 24,
      attentionCount: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 122,
                child: CategorySummaryCard(summary: summary, onTap: () {}),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(summary.name), findsOneWidget);
    expect(find.text('${summary.itemCount} صنف'), findsOneWidget);
  });
}
