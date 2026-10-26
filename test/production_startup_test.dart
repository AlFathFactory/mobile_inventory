import 'dart:async';
import 'dart:io';

import 'package:el_fateh/core/data/services/supabase_failure_mapper.dart';
import 'package:el_fateh/core/widgets/app_bottom_navigation.dart';
import 'package:el_fateh/main.dart';
import 'package:el_fateh/startup/remove_legacy_inventory_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final initializedClient = SupabaseClient(
    'https://example.supabase.co',
    'sb_publishable_example',
    httpClient: MockClient(
      (request) async => http.Response(
        '[]',
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      ),
    ),
  );
  initializedClient.auth.stopAutoRefresh();

  testWidgets('the app shell renders while Supabase initializes', (
    tester,
  ) async {
    final connection = Completer<SupabaseClient?>();
    await tester.pumpWidget(
      ProductionStartup(clientInitializer: () => connection.future),
    );
    await tester.pump();
    expect(find.byKey(const Key('nav-inventory')), findsOneWidget);
    expect(find.byKey(const Key('connection-overlay')), findsNothing);
    connection.complete(initializedClient);
    await tester.pump();
  });

  testWidgets('a connection failure blocks the whole app with retry', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProductionStartup(
        clientInitializer: () async {
          attempts++;
          if (attempts == 1) throw const SocketException('offline');
          return initializedClient;
        },
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('connection-overlay')), findsOneWidget);
    expect(find.byKey(const Key('no-wifi-image')), findsOneWidget);
    expect(find.byKey(const Key('retry-connection')), findsOneWidget);
    final title = tester.widget<Text>(find.text('تعذر الاتصال'));
    expect(title.style?.fontFamily, 'IBMPlexSansArabic');
    expect(title.style?.decoration, TextDecoration.none);

    await tester.tap(find.byKey(const Key('retry-connection')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(attempts, 2);
    expect(find.byKey(const Key('connection-overlay')), findsNothing);
    expect(find.byKey(const Key('nav-inventory')), findsOneWidget);
  });

  testWidgets('a later feature connection failure shows the same overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProductionStartup(clientInitializer: () async => initializedClient),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
          .selectedIndex,
      1,
    );
    SupabaseFailureMapper.from(const SocketException('offline'));
    await tester.pump();
    expect(find.byKey(const Key('connection-overlay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-connection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('connection-overlay')), findsNothing);
    expect(
      tester
          .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
          .selectedIndex,
      1,
    );
  });

  test('upgrade cleanup removes only the retired inventory boxes', () async {
    final root = await Directory.systemTemp.createTemp('inventory-cleanup-');
    addTearDown(() => root.delete(recursive: true));
    for (final name in [
      'cache_metadata_v1.hive',
      'cache_metadata_v1.lock',
      'inventory_snapshots_v1.hive',
      'inventory_snapshots_v1.hivec',
      'other_data.hive',
    ]) {
      await File(
        '${root.path}${Platform.pathSeparator}$name',
      ).writeAsString('x');
    }
    await removeLegacyInventoryCache(directoryPath: root.path);
    expect(
      root.listSync().whereType<File>().map(
        (file) => file.uri.pathSegments.last,
      ),
      ['other_data.hive'],
    );
  });
}
