import 'package:flutter_test/flutter_test.dart';
import 'package:omisu/utils/fuzzy_match.dart';

void main() {
  group('normalizeForSearch', () {
    test('lowercases and strips punctuation', () {
      expect(normalizeForSearch('Super Mario Bros.'), 'super mario bros');
    });
  });

  group('fuzzyMatchesQuery', () {
    test('accepts substring matches', () {
      expect(fuzzyMatchesQuery('mar', 'Super Mario Bros'), isTrue);
    });

    test('accepts small typos', () {
      expect(fuzzyMatchesQuery('mrio', 'Super Mario Bros'), isTrue);
      expect(fuzzyMatchesQuery('sonc', 'Sonic the Hedgehog'), isTrue);
    });

    test('accepts multi-word queries when every token matches', () {
      expect(fuzzyMatchesQuery('supr mario', 'Super Mario Bros'), isTrue);
      expect(fuzzyMatchesQuery('hedge sonic', 'Sonic the Hedgehog'), isTrue);
    });

    test('rejects unrelated strings', () {
      expect(fuzzyMatchesQuery('doesnotexist', 'Super Mario Bros'), isFalse);
      expect(fuzzyMatchesQuery('zelda', 'Super Mario Bros'), isFalse);
    });
  });

  group('fuzzyMatchScore', () {
    test('ranks closer matches higher', () {
      final exact = fuzzyMatchScore('sonic', 'Sonic the Hedgehog')!;
      final typo = fuzzyMatchScore('sonc', 'Sonic the Hedgehog')!;
      expect(exact, greaterThan(typo));
    });

    test('ranks title-start matches above later substring matches', () {
      final titleMatch = fuzzyMatchScore('metroid', 'Metroid')!;
      final laterMatch = fuzzyMatchScore('metroid', 'Super Metroid')!;
      expect(titleMatch, greaterThan(laterMatch));
    });
  });
}
