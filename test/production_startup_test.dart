import 'dart:async';

import 'package:el_fateh/features/inventory/data/local/inventory_local_data_source.dart';
import 'package:el_fateh/core/data/local/cache_metadata.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:el_fateh/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final initializedClient = SupabaseClient(
    'https://example.supabase.co',
    'sb_publishable_example',
    httpClient: MockClient((request) async => http.Response('[]', 200)),
  );
  initializedClient.auth.stopAutoRefresh();

  testWidgets('successful Supabase initialization keeps the shell available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProductionStartup(
        localInitializer: () async => _EmptyLocal(),
        clientInitializer: () async => initializedClient,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('nav-inventory')), findsOneWidget);
  });

  testWidgets('the shell renders while Supabase initialization is pending', (
    tester,
  ) async {
    final connection = Completer<SupabaseClient?>();
    await tester.pumpWidget(
      ProductionStartup(
        localInitializer: () async => _EmptyLocal(),
        clientInitializer: () => connection.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('nav-inventory')), findsOneWidget);
    expect(connection.isCompleted, isFalse);
    connection.complete(null);
    await tester.pump();
  });

  testWidgets('a Supabase initialization error leaves a usable shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProductionStartup(
        localInitializer: () async => _EmptyLocal(),
        clientInitializer: () async => throw const SocketExceptionForTest(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('nav-inventory')), findsOneWidget);
  });

  testWidgets('a local initialization error has an in-app retry', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProductionStartup(
        localInitializer: () async {
          attempts++;
          if (attempts == 1) throw StateError('cache open failed');
          return _EmptyLocal();
        },
        clientInitializer: () async => null,
      ),
    );
    await tester.pump();
    expect(find.text('تعذر فتح بيانات المخزون المحفوظة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(find.byKey(const Key('nav-inventory')), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('no cache and no service displays offline recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProductionStartup(
        localInitializer: () async => _EmptyLocal(),
        clientInitializer: () async => null,
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pump();
    await tester.pump();
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('retry reconnects without clearing app data or restarting', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProductionStartup(
        localInitializer: () async => _EmptyLocal(),
        clientInitializer: () async {
          attempts++;
          return attempts <= 2 ? null : initializedClient;
        },
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pump();
    await tester.pump();
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    await tester.pump();
    expect(attempts, greaterThanOrEqualTo(3));
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsNothing);
    expect(find.byKey(const Key('nav-inventory')), findsOneWidget);
  });

  testWidgets('saved inventory remains browsable while offline', (
    tester,
  ) async {
    final saved = InventoryCacheSnapshot(
      metadata: CacheMetadata(
        dataset: inventoryDatasetName,
        schemaVersion: inventoryCacheSchemaVersion,
        generation: 1,
        isComplete: true,
        syncInProgress: false,
        lastSuccessfulSync: DateTime.now(),
      ),
      items: [
        const InventoryItem(
          code: 'SAVED-1',
          name: 'صنف محفوظ',
          category: 'General',
          project: 'Project',
          quantity: 3,
          minimum: 1,
          tableName: 'inventory_items',
          itemId: '00000000-0000-0000-0000-000000000001',
        ),
      ],
    );
    await tester.pumpWidget(
      ProductionStartup(
        localInitializer: () async => _EmptyLocal(saved),
        clientInitializer: () async => null,
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('nav-inventory')));
    await tester.pump();
    expect(find.text('صنف محفوظ'), findsOneWidget);
    expect(
      find.textContaining('تُعرض بيانات المخزون المحفوظة'),
      findsOneWidget,
    );
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsNothing);
  });
}

class SocketExceptionForTest implements Exception {
  const SocketExceptionForTest();
}

class _EmptyLocal implements InventoryLocalDataSource {
  _EmptyLocal([this.snapshot]);

  final InventoryCacheSnapshot? snapshot;

  @override
  Future<InventoryCacheSnapshot?> readSnapshot() async => snapshot;

  @override
  Future<void> recoverInterruptedSync() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
