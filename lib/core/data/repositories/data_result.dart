import 'package:flutter/foundation.dart';

enum DataFailureKind { offline, unavailable, server, unknown }

@immutable
class DataFailure {
  const DataFailure({required this.kind, required this.message, this.cause});

  final DataFailureKind kind;
  final String message;
  final Object? cause;
}

sealed class DataResult<T> {
  const DataResult();
}

final class DataSuccess<T> extends DataResult<T> {
  const DataSuccess(this.value);

  final T value;
}

final class DataError<T> extends DataResult<T> {
  const DataError(this.failure);

  final DataFailure failure;
}
