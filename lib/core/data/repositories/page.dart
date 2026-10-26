import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class PageRequest {
  const PageRequest({this.limit = 20, this.cursor})
    : assert(limit > 0 && limit <= 100);

  final int limit;

  /// Opaque to callers. Live and preview repositories choose their own token.
  final String? cursor;
}

@immutable
class PageResult<T> {
  PageResult({required List<T> items, this.nextCursor})
    : items = List.unmodifiable(items);

  final List<T> items;
  final String? nextCursor;

  bool get isEmpty => items.isEmpty;
  bool get hasMore => nextCursor != null;
}

/// Offset cursors are sufficient for deterministic PreviewData.
/// Supabase implementations can replace this with keyset pagination
/// without changing repository consumers.
PageResult<T> paginatePreview<T>(List<T> values, PageRequest request) {
  final parsedOffset = int.tryParse(request.cursor ?? '') ?? 0;
  final offset = math.min(math.max(parsedOffset, 0), values.length);
  final end = math.min(offset + request.limit, values.length);
  return PageResult<T>(
    items: values.sublist(offset, end),
    nextCursor: end < values.length ? '$end' : null,
  );
}
