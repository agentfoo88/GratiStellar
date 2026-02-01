import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/release_note.dart';

/// Card widget displaying a single release note version
class ReleaseCard extends StatelessWidget {
  final ReleaseNote release;
  final bool isLatest;

  const ReleaseCard({
    super.key,
    required this.release,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

    return Container(
      margin: EdgeInsets.only(
        bottom: FontScaling.getResponsiveSpacing(context, 16),
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? AppTheme.primary.withValues(alpha: 0.5)
              : AppTheme.borderSubtle.withValues(alpha: 0.3),
          width: isLatest ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          FontScaling.getResponsiveSpacing(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version header with date and optional "Latest" badge
            Row(
              children: [
                Text(
                  'v${release.version}',
                  style: FontScaling.getHeadingSmall(context).copyWith(
                    fontSize: FontScaling.getHeadingSmall(context).fontSize! *
                        UIConstants.universalUIScale,
                    color: AppTheme.primary,
                    fontWeight: FontScaling.mediumWeight,
                  ),
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                Text(
                  dateFormat.format(release.releaseDate),
                  style: FontScaling.getCaption(context).copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                const Spacer(),
                if (isLatest)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 8),
                      vertical: FontScaling.getResponsiveSpacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.whatsNewLatestBadge,
                      style: FontScaling.getCaption(context).copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontScaling.mediumWeight,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
            // Release items
            ...release.items.map(
              (item) => _ReleaseItemRow(item: item),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row widget for a single release item
class _ReleaseItemRow extends StatelessWidget {
  final ReleaseItem item;

  const _ReleaseItemRow({required this.item});

  Color _getTypeColor() {
    switch (item.type) {
      case ReleaseItemType.newFeature:
        return AppTheme.success;
      case ReleaseItemType.improvement:
        return AppTheme.info;
      case ReleaseItemType.bugFix:
        return AppTheme.warning;
    }
  }

  String _getTypeLabel(AppLocalizations l10n) {
    switch (item.type) {
      case ReleaseItemType.newFeature:
        return l10n.whatsNewNewFeature;
      case ReleaseItemType.improvement:
        return l10n.whatsNewImprovement;
      case ReleaseItemType.bugFix:
        return l10n.whatsNewBugFix;
    }
  }

  String _getLocalizedTitle(AppLocalizations l10n) {
    // Map titleKey to localized string
    switch (item.titleKey) {
      case 'whatsNewSoundSupportTitle':
        return l10n.whatsNewSoundSupportTitle;
      case 'whatsNewWhatsNewFeatureTitle':
        return l10n.whatsNewWhatsNewFeatureTitle;
      case 'whatsNewNotificationsFixTitle':
        return l10n.whatsNewNotificationsFixTitle;
      case 'whatsNewTutorialPromptsTitle':
        return l10n.whatsNewTutorialPromptsTitle;
      case 'whatsNewColourSettingsTitle':
        return l10n.whatsNewColourSettingsTitle;
      case 'whatsNewMenuReorderTitle':
        return l10n.whatsNewMenuReorderTitle;
      default:
        return item.titleKey;
    }
  }

  String _getLocalizedDescription(AppLocalizations l10n) {
    // Map descriptionKey to localized string
    switch (item.descriptionKey) {
      case 'whatsNewSoundSupportDesc':
        return l10n.whatsNewSoundSupportDesc;
      case 'whatsNewWhatsNewFeatureDesc':
        return l10n.whatsNewWhatsNewFeatureDesc;
      case 'whatsNewNotificationsFixDesc':
        return l10n.whatsNewNotificationsFixDesc;
      case 'whatsNewTutorialPromptsDesc':
        return l10n.whatsNewTutorialPromptsDesc;
      case 'whatsNewColourSettingsDesc':
        return l10n.whatsNewColourSettingsDesc;
      case 'whatsNewMenuReorderDesc':
        return l10n.whatsNewMenuReorderDesc;
      default:
        return item.descriptionKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeColor = _getTypeColor();

    return Padding(
      padding: EdgeInsets.only(
        bottom: FontScaling.getResponsiveSpacing(context, 12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with colored background
          Container(
            width: FontScaling.getResponsiveIconSize(context, 32) *
                UIConstants.universalUIScale,
            height: FontScaling.getResponsiveIconSize(context, 32) *
                UIConstants.universalUIScale,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              color: typeColor,
              size: FontScaling.getResponsiveIconSize(context, 18) *
                  UIConstants.universalUIScale,
            ),
          ),
          SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            FontScaling.getResponsiveSpacing(context, 6),
                        vertical: FontScaling.getResponsiveSpacing(context, 2),
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getTypeLabel(l10n),
                        style: FontScaling.getCaption(context).copyWith(
                          color: typeColor,
                          fontWeight: FontScaling.mediumWeight,
                          fontSize:
                              (FontScaling.getCaption(context).fontSize ?? 12) *
                                  0.85,
                        ),
                      ),
                    ),
                    SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                    // Title
                    Expanded(
                      child: Text(
                        _getLocalizedTitle(l10n),
                        style: FontScaling.getBodyMedium(context).copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontScaling.mediumWeight,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
                // Description
                Text(
                  _getLocalizedDescription(l10n),
                  style: FontScaling.getBodySmall(context).copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
