import 'package:flutter/material.dart';

import '../domain/models/release_note.dart';

/// Hardcoded list of release notes for the app.
/// Update this list with each new release.
class ReleaseNotesData {
  ReleaseNotesData._();

  /// All release notes, ordered from newest to oldest
  static final List<ReleaseNote> releaseNotes = [
    // Version 1.1.3 (Build 31)
    ReleaseNote(
      version: '1.1.3',
      buildNumber: 31,
      releaseDate: DateTime(2026, 4, 12),
      items: [
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewLargeGalaxyFixTitle,
          description: (l10n) => l10n.whatsNewLargeGalaxyFixDesc,
          icon: Icons.auto_awesome,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewTagNormalizationFixTitle,
          description: (l10n) => l10n.whatsNewTagNormalizationFixDesc,
          icon: Icons.label,
        ),
      ],
    ),
    // Version 1.1.2 (Build 30)
    ReleaseNote(
      version: '1.1.2',
      buildNumber: 30,
      releaseDate: DateTime(2026, 3, 13),
      items: [
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewReminderTimezoneFixTitle,
          description: (l10n) => l10n.whatsNewReminderTimezoneFixDesc,
          icon: Icons.notifications_active,
        ),
      ],
    ),
    // Version 1.1.1 (Build 29)
    ReleaseNote(
      version: '1.1.1',
      buildNumber: 29,
      releaseDate: DateTime(2026, 3, 5),
      items: [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewSortByTagTitle,
          description: (l10n) => l10n.whatsNewSortByTagDesc,
          icon: Icons.label_outline,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewBulkAddTagsTitle,
          description: (l10n) => l10n.whatsNewBulkAddTagsDesc,
          icon: Icons.label,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewTagSuggestionsFixTitle,
          description: (l10n) => l10n.whatsNewTagSuggestionsFixDesc,
          icon: Icons.label,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewScrollbarGutterFixTitle,
          description: (l10n) => l10n.whatsNewScrollbarGutterFixDesc,
          icon: Icons.linear_scale,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          title: (l10n) => l10n.whatsNewWiderDialogTitle,
          description: (l10n) => l10n.whatsNewWiderDialogDesc,
          icon: Icons.open_in_full,
        ),
      ],
    ),
    // Version 1.1.0 (Build 28)
    ReleaseNote(
      version: '1.1.0',
      buildNumber: 28,
      releaseDate: DateTime(2025, 2, 16),
      items: [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewSearchFunctionTitle,
          description: (l10n) => l10n.whatsNewSearchFunctionDesc,
          icon: Icons.search,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewTaggingStarsTitle,
          description: (l10n) => l10n.whatsNewTaggingStarsDesc,
          icon: Icons.label,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewMindfulnessDelayTitle,
          description: (l10n) => l10n.whatsNewMindfulnessDelayDesc,
          icon: Icons.self_improvement,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          title: (l10n) => l10n.whatsNewCreationSoundTitle,
          description: (l10n) => l10n.whatsNewCreationSoundDesc,
          icon: Icons.music_note,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewL10nAccessibilityFixTitle,
          description: (l10n) => l10n.whatsNewL10nAccessibilityFixDesc,
          icon: Icons.accessibility_new,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewBannersWrappingFixTitle,
          description: (l10n) => l10n.whatsNewBannersWrappingFixDesc,
          icon: Icons.wrap_text,
        ),
      ],
    ),
    // Version 1.0.10 (Build 24)
    ReleaseNote(
      version: '1.0.10',
      buildNumber: 24,
      releaseDate: DateTime(2025, 1, 31),
      items: [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewSoundSupportTitle,
          description: (l10n) => l10n.whatsNewSoundSupportDesc,
          icon: Icons.volume_up,
        ),
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewWhatsNewFeatureTitle,
          description: (l10n) => l10n.whatsNewWhatsNewFeatureDesc,
          icon: Icons.new_releases,
        ),
        ReleaseItem(
          type: ReleaseItemType.bugFix,
          title: (l10n) => l10n.whatsNewNotificationsFixTitle,
          description: (l10n) => l10n.whatsNewNotificationsFixDesc,
          icon: Icons.notifications,
        ),
      ],
    ),
    // Version 1.0.9 (Build 23)
    ReleaseNote(
      version: '1.0.9',
      buildNumber: 23,
      releaseDate: DateTime(2025, 1, 28),
      items: [
        ReleaseItem(
          type: ReleaseItemType.newFeature,
          title: (l10n) => l10n.whatsNewTutorialPromptsTitle,
          description: (l10n) => l10n.whatsNewTutorialPromptsDesc,
          icon: Icons.school,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          title: (l10n) => l10n.whatsNewColourSettingsTitle,
          description: (l10n) => l10n.whatsNewColourSettingsDesc,
          icon: Icons.palette,
        ),
        ReleaseItem(
          type: ReleaseItemType.improvement,
          title: (l10n) => l10n.whatsNewMenuReorderTitle,
          description: (l10n) => l10n.whatsNewMenuReorderDesc,
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
