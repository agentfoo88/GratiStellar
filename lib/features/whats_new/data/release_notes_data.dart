import 'package:flutter/material.dart';

import '../domain/models/release_note.dart';

/// Hardcoded list of release notes for the app.
/// Update this list with each new release.
class ReleaseNotesData {
  ReleaseNotesData._();

  /// All release notes, ordered from newest to oldest
  static final List<ReleaseNote> releaseNotes = [
    // Version 1.1.0 (Build 28)
    ReleaseNote(
      version: '1.1.0',
      buildNumber: 28,
      releaseDate: DateTime(2025, 2, 16),
      items: const [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewSearchTaggingTitle',
          descriptionKey: 'whatsNewSearchTaggingDesc',
          icon: Icons.search,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewStarCreationSoundTitle',
          descriptionKey: 'whatsNewStarCreationSoundDesc',
          icon: Icons.music_note,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          titleKey: 'whatsNewAccessibilityCleanupTitle',
          descriptionKey: 'whatsNewAccessibilityCleanupDesc',
          icon: Icons.accessibility_new,
        ),
      ],
    ),
    // Version 1.0.10 (Build 24)
    ReleaseNote(
      version: '1.0.10',
      buildNumber: 24,
      releaseDate: DateTime(2025, 1, 31),
      items: const [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewSoundSupportTitle',
          descriptionKey: 'whatsNewSoundSupportDesc',
          icon: Icons.volume_up,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewWhatsNewFeatureTitle',
          descriptionKey: 'whatsNewWhatsNewFeatureDesc',
          icon: Icons.new_releases,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          titleKey: 'whatsNewNotificationsFixTitle',
          descriptionKey: 'whatsNewNotificationsFixDesc',
          icon: Icons.notifications,
        ),
      ],
    ),
    // Version 1.0.9 (Build 23)
    ReleaseNote(
      version: '1.0.9',
      buildNumber: 23,
      releaseDate: DateTime(2025, 1, 28),
      items: const [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewTutorialPromptsTitle',
          descriptionKey: 'whatsNewTutorialPromptsDesc',
          icon: Icons.school,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          titleKey: 'whatsNewColourSettingsTitle',
          descriptionKey: 'whatsNewColourSettingsDesc',
          icon: Icons.palette,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          titleKey: 'whatsNewMenuReorderTitle',
          descriptionKey: 'whatsNewMenuReorderDesc',
          icon: Icons.menu,
        ),
      ],
    ),
  ];

  /// Get the latest release note
  static ReleaseNote get latestRelease => releaseNotes.first;

  /// Get the current build number (from latest release)
  static int get currentBuildNumber => latestRelease.buildNumber;
}
