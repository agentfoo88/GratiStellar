import 'package:flutter/material.dart';

import '../domain/models/release_note.dart';

/// Hardcoded list of release notes for the app.
/// Update this list with each new release.
class ReleaseNotesData {
  ReleaseNotesData._();

  /// All release notes, ordered from newest to oldest
  static final List<ReleaseNote> releaseNotes = [
    // Version 1.1.2 (Build 30)
    ReleaseNote(
      version: '1.1.2',
      buildNumber: 30,
      releaseDate: DateTime(2026, 3, 13),
      items: const [
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          titleKey: 'whatsNewReminderTimezoneFixTitle',
          descriptionKey: 'whatsNewReminderTimezoneFixDesc',
          icon: Icons.notifications_active,
        ),
      ],
    ),
    // Version 1.1.1 (Build 29)
    ReleaseNote(
      version: '1.1.1',
      buildNumber: 29,
      releaseDate: DateTime(2026, 3, 5),
      items: const [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewSortByTagTitle',
          descriptionKey: 'whatsNewSortByTagDesc',
          icon: Icons.label_outline,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewBulkAddTagsTitle',
          descriptionKey: 'whatsNewBulkAddTagsDesc',
          icon: Icons.label,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          titleKey: 'whatsNewTagSuggestionsFixTitle',
          descriptionKey: 'whatsNewTagSuggestionsFixDesc',
          icon: Icons.label,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          titleKey: 'whatsNewScrollbarGutterFixTitle',
          descriptionKey: 'whatsNewScrollbarGutterFixDesc',
          icon: Icons.linear_scale,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          titleKey: 'whatsNewWiderDialogTitle',
          descriptionKey: 'whatsNewWiderDialogDesc',
          icon: Icons.open_in_full,
        ),
      ],
    ),
    // Version 1.1.0 (Build 28)
    ReleaseNote(
      version: '1.1.0',
      buildNumber: 28,
      releaseDate: DateTime(2025, 2, 16),
      items: const [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewSearchFunctionTitle',
          descriptionKey: 'whatsNewSearchFunctionDesc',
          icon: Icons.search,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewTaggingStarsTitle',
          descriptionKey: 'whatsNewTaggingStarsDesc',
          icon: Icons.label,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          titleKey: 'whatsNewMindfulnessDelayTitle',
          descriptionKey: 'whatsNewMindfulnessDelayDesc',
          icon: Icons.self_improvement,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          titleKey: 'whatsNewCreationSoundTitle',
          descriptionKey: 'whatsNewCreationSoundDesc',
          icon: Icons.music_note,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          titleKey: 'whatsNewL10nAccessibilityFixTitle',
          descriptionKey: 'whatsNewL10nAccessibilityFixDesc',
          icon: Icons.accessibility_new,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          titleKey: 'whatsNewBannersWrappingFixTitle',
          descriptionKey: 'whatsNewBannersWrappingFixDesc',
          icon: Icons.wrap_text,
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
