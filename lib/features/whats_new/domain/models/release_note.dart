import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Type of release item change
enum ReleaseItemType {
  newFeature,
  improvement,
  bugFix,
}

/// Individual item within a release note
class ReleaseItem {
  final ReleaseItemType type;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) description;
  final IconData icon;

  const ReleaseItem({
    required this.type,
    required this.title,
    required this.description,
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
