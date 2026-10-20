import 'package:el_fateh/core/utils/search_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes spaces, Arabic letters, marks, digits and Latin text', () {
    expect(
      normalizeSearchTerm(
        '\u062d\u062c\u0631 \u0642\u0637\u0639\u064a\u0647 5 \u0628\u0648\u0635\u0629',
      ),
      '\u062d\u062c\u0631\u0642\u0637\u0639\u064a\u06475\u0628\u0648\u0635\u0647',
    );
    for (final alef in ['\u0623', '\u0625', '\u0622', '\u0671']) {
      expect(normalizeSearchTerm(alef), '\u0627');
    }
    expect(
      normalizeSearchTerm('\u0639\u0628\u0648\u0629'),
      '\u0639\u0628\u0648\u0647',
    );
    expect(
      normalizeSearchTerm('\u0632\u0648\u062c\u0649'),
      '\u0632\u0648\u062c\u064a',
    );
    expect(
      normalizeSearchTerm('\u062d\u064e\u062c\u064e\u0631'),
      '\u062d\u062c\u0631',
    );
    expect(
      normalizeSearchTerm('\u062d\u062c\u0640\u0640\u0640\u0640\u0631'),
      '\u062d\u062c\u0631',
    );
    expect(normalizeSearchTerm('\u0665\u0660'), '50');
    expect(normalizeSearchTerm('\u06f5\u06f0'), '50');
    expect(normalizeSearchTerm('WD 40'), 'wd40');
    expect(
      normalizeSearchTerm('\u0639\u0628\u0648\u0629 WD 40'),
      '\u0639\u0628\u0648\u0647wd40',
    );
    expect(normalizeSearchTerm('M 12 * 40 A 4'), 'm12*40a4');
    expect(normalizeSearchTerm('\ufefb'), '\u0644\u0627');
  });

  test('matches normalized terms across item properties', () {
    expect(
      includesSearchTerm(
        '\u062d\u062c\u0631 \u0642\u0637\u0639\u064a\u0647 5 \u0628\u0648\u0635\u0629',
        normalizeSearchTerm(
          '\u062d\u062c\u0631\u0642\u0637\u0639\u064a\u06475\u0628\u0648\u0635\u0647',
        ),
      ),
      isTrue,
    );
    expect(
      includesSearchTerm(
        '\u0639\u0628\u0648\u0629 WD 40',
        normalizeSearchTerm('\u0639\u0628\u0648\u0629wd40'),
      ),
      isTrue,
    );
    expect(
      matchesAnySearchValue([
        null,
        'Project A',
        '\u0665\u0660 DIN',
      ], normalizeSearchTerm('50din')),
      isTrue,
    );
    expect(matchesAnySearchValue([null, 'Project A'], 'missing'), isFalse);
  });

  test('remote pattern matches spaced, marked and alternate Arabic text', () {
    final stonePattern = searchPatternForNormalizedTerm(
      normalizeSearchTerm(
        '\u062d\u062c\u0631\u0642\u0637\u0639\u064a\u06475\u0628\u0648\u0635\u0647',
      ),
    );
    expect(
      RegExp(stonePattern, caseSensitive: false).hasMatch(
        '\u062d\u064e\u062c\u064e\u0631 \u0642\u064e\u0637\u0652\u0639\u0650\u064a\u064e\u0651\u0629 \u0665 \u0628\u0648\u0635\u0629',
      ),
      isTrue,
    );
    final bottlePattern = searchPatternForNormalizedTerm(
      normalizeSearchTerm('\u0639\u0628\u0648\u0629wd40'),
    );
    expect(
      RegExp(
        bottlePattern,
        caseSensitive: false,
      ).hasMatch('\u0639\u0628\u0648\u0629 WD 40'),
      isTrue,
    );
  });
}
