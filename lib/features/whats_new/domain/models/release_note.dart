import 'package:flutter/material.dart';

/// Type of release item change
enum ReleaseItemType {
  newFeature,
  improvement,
  bugFix,
}

/// Individual item within a release note
class ReleaseItem {
  final ReleaseItemType type;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;

  const ReleaseItem({
    required this.type,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
  });
}

/// A single release note containing version info and changes
class ReleaseNote {
  final String version;
  final int buildNumber;
  final DateTime releaseDate;
  final List<ReleaseItem> items;

  const ReleaseNote({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
    required this.items,
  });
}
