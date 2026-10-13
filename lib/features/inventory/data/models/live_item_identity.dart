import 'package:flutter/foundation.dart';

@immutable
class LiveItemIdentity {
  const LiveItemIdentity({required this.tableName, required this.itemId});

  static final _tableNamePattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static LiveItemIdentity? tryParse(String routeId) {
    final separator = routeId.indexOf('::');
    if (separator <= 0 || separator != routeId.lastIndexOf('::')) return null;

    final tableName = routeId.substring(0, separator);
    final itemId = routeId.substring(separator + 2);
    if (!_tableNamePattern.hasMatch(tableName) ||
        !_uuidPattern.hasMatch(itemId)) {
      return null;
    }
    return LiveItemIdentity(tableName: tableName, itemId: itemId);
  }

  final String tableName;
  final String itemId;

  String get routeId => '$tableName::$itemId';
}
