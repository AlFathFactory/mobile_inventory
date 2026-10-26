import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/data_result.dart';
import 'supabase_bootstrap.dart';

abstract final class SupabaseFailureMapper {
  /// Set by the production app to cover every live repository with one overlay.
  static void Function()? onConnectionFailure;

  static DataFailure from(Object error) {
    if (error is SupabaseConfigurationException) {
      return const DataFailure(
        kind: DataFailureKind.unavailable,
        message: 'إعدادات خدمة البيانات غير مكتملة.',
      );
    }
    if (error is SupabaseConnectionException) {
      onConnectionFailure?.call();
      return const DataFailure(
        kind: DataFailureKind.offline,
        message: 'تعذر الاتصال بخدمة البيانات.',
      );
    }
    if (error is TimeoutException ||
        error is ClientException ||
        error is SocketException) {
      onConnectionFailure?.call();
      return const DataFailure(
        kind: DataFailureKind.offline,
        message: 'Unable to reach the data service.',
      );
    }

    if (error is AuthException) {
      return const DataFailure(
        kind: DataFailureKind.unavailable,
        message: 'The data service is unavailable for this application.',
      );
    }

    if (error is PostgrestException) {
      final code = error.code ?? '';
      final unavailable = code == '42501' || code.startsWith('PGRST3');
      return DataFailure(
        kind: unavailable
            ? DataFailureKind.unavailable
            : DataFailureKind.server,
        message: unavailable
            ? 'Inventory data is currently unavailable.'
            : 'The inventory service could not complete the request.',
      );
    }

    return const DataFailure(
      kind: DataFailureKind.unknown,
      message: 'Inventory data could not be loaded.',
    );
  }
}
