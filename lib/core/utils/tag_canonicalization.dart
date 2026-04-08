import 'package:flutter/material.dart';

import '../../storage.dart';

/// Holds the Autocomplete [TextEditingController] for tag fields so callers can
/// [clear] after adding a tag (the dialog's separate [TextEditingController] is not wired to the field).
class TagFieldControllerRef {
  TextEditingController? controller;
}

/// Single place for "same tag?" comparisons. Today: trim + Unicode lower case.
String tagComparisonKey(String tag) => tag.trim().toLowerCase();

/// Whether two tag lists are identical (order-sensitive).
bool tagsListEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Oldest stars first; first spelling seen for each comparison key wins.
Map<String, String> buildCanonicalTagMap(Iterable<GratitudeStar> stars) {
  final sorted = stars.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final map = <String, String>{};
  for (final star in sorted) {
    for (final raw in star.tags) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      final key = tagComparisonKey(t);
      map.putIfAbsent(key, () => t);
    }
  }
  return map;
}

/// Maps tags to canonical spelling, then dedupes by [tagComparisonKey] (order preserved).
List<String> normalizeStarTags(List<String> tags, Map<String, String> canonicalByKey) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in tags) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final key = tagComparisonKey(trimmed);
    final canonical = canonicalByKey[key] ?? trimmed;
    final dedupeKey = tagComparisonKey(canonical);
    if (seen.add(dedupeKey)) {
      out.add(canonical);
    }
  }
  return out;
}

/// Unique canonical tag strings for autocomplete, excluding tags already on the star (by key).
List<String> availableCanonicalTagsForAutocomplete({
  required List<GratitudeStar> allStars,
  required List<String> editingTags,
}) {
  final canonicalMap = buildCanonicalTagMap(allStars);
  final editingKeys = editingTags.map(tagComparisonKey).toSet();
  final available = <String>[];
  for (final entry in canonicalMap.entries) {
    if (!editingKeys.contains(entry.key)) {
      available.add(entry.value);
    }
  }
  available.sort((a, b) => tagComparisonKey(a).compareTo(tagComparisonKey(b)));
  return available;
}
