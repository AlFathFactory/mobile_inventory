import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<void> removeLegacyInventoryCache({String? directoryPath}) async {
  try {
    final root = directoryPath == null
        ? await getApplicationDocumentsDirectory()
        : Directory(directoryPath);
    for (final box in ['cache_metadata_v1', 'inventory_snapshots_v1']) {
      for (final extension in ['hive', 'hivec', 'lock']) {
        final file = File(
          '${root.path}${Platform.pathSeparator}$box.$extension',
        );
        if (await file.exists()) await file.delete();
      }
    }
  } on FileSystemException catch (error) {
    debugPrint('Legacy inventory cache cleanup failed: $error');
  } on MissingPluginException catch (error) {
    debugPrint('Legacy inventory cache cleanup unavailable: $error');
  }
}
