import 'remove_legacy_inventory_cache_stub.dart'
    if (dart.library.io) 'remove_legacy_inventory_cache_io.dart'
    if (dart.library.js_interop) 'remove_legacy_inventory_cache_web.dart'
    as platform;

/// Remove only data created by the retired inventory offline feature.
Future<void> removeLegacyInventoryCache({String? directoryPath}) =>
    platform.removeLegacyInventoryCache(directoryPath: directoryPath);
