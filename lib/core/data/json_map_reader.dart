abstract final class JsonMapReader {
  static String string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();
    throw FormatException('Expected a non-empty string for "$key".');
  }

  static String? nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value;
    if (value is num) return value.toString();
    throw FormatException('Expected a string or null for "$key".');
  }

  static int integer(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed.toInt();
    }
    throw FormatException('Expected a number for "$key".');
  }

  static num number(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected a number for "$key".');
  }

  static DateTime dateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected an ISO-8601 date for "$key".');
  }

  static DateTime? nullableDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    throw FormatException('Expected an ISO-8601 date or null for "$key".');
  }
}
