import 'package:flutter_test/flutter_test.dart';
import 'package:gratistellar/core/utils/tag_canonicalization.dart';
import 'package:gratistellar/storage.dart';

GratitudeStar _testStar({
  required String id,
  required DateTime createdAt,
  List<String> tags = const [],
}) {
  return GratitudeStar(
    text: 'hello',
    worldX: 0.5,
    worldY: 0.5,
    id: id,
    createdAt: createdAt,
    spinDirection: 0,
    spinRate: 1,
    pulseSpeedH: 1,
    pulseSpeedV: 1,
    pulsePhaseH: 0,
    pulsePhaseV: 0,
    pulseMinScaleH: 1,
    pulseMinScaleV: 1,
    tags: tags,
  );
}

void main() {
  group('tagComparisonKey', () {
    test('trims and lowercases', () {
      expect(tagComparisonKey('  Family  '), 'family');
    });
  });

  group('buildCanonicalTagMap', () {
    test('first seen by createdAt wins spelling', () {
      final older = _testStar(
        id: '1',
        createdAt: DateTime(2020, 1, 1),
        tags: ['Family'],
      );
      final newer = _testStar(
        id: '2',
        createdAt: DateTime(2021, 1, 1),
        tags: ['family'],
      );
      final map = buildCanonicalTagMap([newer, older]);
      expect(map['family'], 'Family');
    });

    test('empty tags contribute nothing', () {
      final map = buildCanonicalTagMap([
        _testStar(id: '1', createdAt: DateTime(2020), tags: []),
      ]);
      expect(map, isEmpty);
    });
  });

  group('normalizeStarTags', () {
    test('maps to canonical and dedupes by key', () {
      final map = {'family': 'Family'};
      expect(
        normalizeStarTags(['family', 'Family', ' work '], map),
        ['Family', 'work'],
      );
    });

    test('unknown tag passes through trimmed', () {
      final map = <String, String>{};
      expect(normalizeStarTags(['  NewTag  '], map), ['NewTag']);
    });
  });

  group('availableCanonicalTagsForAutocomplete', () {
    test('excludes tags already on star by comparison key', () {
      final stars = [
        _testStar(id: '1', createdAt: DateTime(2020), tags: ['Family', 'work']),
      ];
      final available = availableCanonicalTagsForAutocomplete(
        allStars: stars,
        editingTags: ['family'],
      );
      expect(available, ['work']);
    });
  });

  group('tagsListEquals', () {
    test('order sensitive', () {
      expect(tagsListEquals(['a', 'b'], ['a', 'b']), isTrue);
      expect(tagsListEquals(['a', 'b'], ['b', 'a']), isFalse);
    });
  });
}
