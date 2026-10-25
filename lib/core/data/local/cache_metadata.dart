import 'package:flutter/foundation.dart';

/// Describes the atomically committed snapshot for one locally cached dataset.
@immutable
class CacheMetadata {
  const CacheMetadata({
    required this.dataset,
    required this.schemaVersion,
    required this.generation,
    required this.isComplete,
    required this.syncInProgress,
    this.lastSuccessfulSync,
    this.lastFailure,
  });

  final String dataset;
  final int schemaVersion;
  final int generation;

  /// The active generation is readable. Inventory coverage may still be partial.
  final bool isComplete;
  final bool syncInProgress;
  final DateTime? lastSuccessfulSync;
  final String? lastFailure;

  bool isFresh(Duration maxAge, DateTime now) {
    final synchronizedAt = lastSuccessfulSync;
    return isComplete &&
        synchronizedAt != null &&
        now.difference(synchronizedAt) <= maxAge;
  }

  CacheMetadata copyWith({
    int? schemaVersion,
    int? generation,
    bool? isComplete,
    bool? syncInProgress,
    DateTime? lastSuccessfulSync,
    bool clearLastSuccessfulSync = false,
    String? lastFailure,
    bool clearLastFailure = false,
  }) => CacheMetadata(
    dataset: dataset,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    generation: generation ?? this.generation,
    isComplete: isComplete ?? this.isComplete,
    syncInProgress: syncInProgress ?? this.syncInProgress,
    lastSuccessfulSync: clearLastSuccessfulSync
        ? null
        : (lastSuccessfulSync ?? this.lastSuccessfulSync),
    lastFailure: clearLastFailure ? null : (lastFailure ?? this.lastFailure),
  );
}
