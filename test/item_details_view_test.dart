import 'package:el_fateh/core/data/preview_data.dart';
import 'package:el_fateh/core/theme/app_theme.dart';
import 'package:el_fateh/features/inventory/view/item_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [Size(320, 568), Size(392, 812), Size(600, 1024)]) {
    testWidgets(
      'item details remains responsive at ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final item = PreviewData.itemByCode('PA-GN-059');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: ItemDetailsView(
                item: item,
                movements: PreviewData.movementsFor(item.code),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(item.name), findsOneWidget);
        expect(find.text(item.supplier!), findsOneWidget);
        expect(find.text('الرصيد الحالي'), findsOneWidget);

        final codeContext = tester.element(find.text(item.code));
        expect(Directionality.of(codeContext), TextDirection.ltr);

        final scrollable = find.descendant(
          of: find.byKey(const Key('item-details-list')),
          matching: find.byType(Scrollable),
        );
        final position = tester.state<ScrollableState>(scrollable).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('item-notes-section')), findsOneWidget);
        expect(find.byKey(const Key('open-movement-history')), findsOneWidget);
      },
    );
  }

  testWidgets('item details hides notes and history entry when unavailable', (
    tester,
  ) async {
    final item = PreviewData.itemByCode('GS-OX-004');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ItemDetailsView(item: item, movements: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byKey(const Key('item-details-list')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    expect(find.byKey(const Key('item-notes-section')), findsNothing);
    expect(find.byKey(const Key('open-movement-history')), findsNothing);
    expect(find.text('لا توجد حركات مسجلة لهذا الصنف.'), findsOneWidget);
  });
}
