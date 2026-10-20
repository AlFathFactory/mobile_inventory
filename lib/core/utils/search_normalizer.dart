import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Produces the same compact search token used by the Web inventory search.
String normalizeSearchTerm(String value) {
  final decomposed = unorm.nfkd(value.trim().toLowerCase());
  return decomposed
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp(r'[\u0623\u0625\u0622\u0671]'), '\u0627')
      .replaceAll('\u0629', '\u0647')
      .replaceAll('\u0649', '\u064A')
      .replaceAll('\u0640', '')
      .replaceAllMapped(
        RegExp(r'[\u0660-\u0669]'),
        (match) => '${match[0]!.codeUnitAt(0) - 0x0660}',
      )
      .replaceAllMapped(
        RegExp(r'[\u06F0-\u06F9]'),
        (match) => '${match[0]!.codeUnitAt(0) - 0x06F0}',
      )
      .replaceAll(RegExp(r'\s+'), '');
}

bool includesSearchTerm(Object? value, String normalizedSearchTerm) =>
    normalizedSearchTerm.isEmpty ||
    (value != null &&
        normalizeSearchTerm(value.toString()).contains(normalizedSearchTerm));

bool matchesAnySearchValue(
  Iterable<Object?> values,
  String normalizedSearchTerm,
) =>
    normalizedSearchTerm.isEmpty ||
    values.any((value) => includesSearchTerm(value, normalizedSearchTerm));

/// Matches a normalized token against unnormalized text in the existing views.
/// The views do not expose a normalized search column, so PostgREST's `imatch`
/// operator needs to allow the same Arabic variants, digits and separators.
String searchPatternForNormalizedTerm(String normalizedSearchTerm) {
  const gap = '[\\s\u064B-\u065F\u0670\u0640*]*';
  final parts = <String>[];
  for (final rune in normalizedSearchTerm.runes) {
    final character = String.fromCharCode(rune);
    if (RegExp(r'\s').hasMatch(character) || character == '*') continue;
    parts.add(switch (character) {
      '\u0627' => '[\u0627\u0623\u0625\u0622\u0671]',
      '\u0647' => '[\u0647\u0629]',
      '\u064a' => '[\u064a\u0649]',
      '-' => '[-]',
      _ when rune >= 0x30 && rune <= 0x39 =>
        '[$character${String.fromCharCode(rune + 0x0630)}${String.fromCharCode(rune + 0x06C0)}]',
      _ => RegExp.escape(character),
    });
  }
  return parts.join(gap);
}
