import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

Future<void> removeLegacyInventoryCache({String? directoryPath}) async {
  // Hive CE stored each uncollected box in its own IndexedDB database.
  for (final name in ['cache_metadata_v1', 'inventory_snapshots_v1']) {
    final request = window.indexedDB.deleteDatabase(name);
    final finished = Completer<void>();
    void complete(Event _) {
      if (!finished.isCompleted) finished.complete();
    }

    request.onsuccess = complete.toJS;
    request.onerror = complete.toJS;
    request.onblocked = complete.toJS;
    await finished.future.timeout(const Duration(seconds: 2), onTimeout: () {});
  }
}
