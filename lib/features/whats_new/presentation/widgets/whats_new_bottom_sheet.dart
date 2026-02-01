import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/url_launch_service.dart';
import '../../data/release_notes_data.dart';
import 'release_card.dart';

/// Modal bottom sheet showing release notes
class WhatsNewBottomSheet extends StatelessWidget {
  const WhatsNewBottomSheet({super.key});

  /// Show the What's New bottom sheet
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WhatsNewBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDarker,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(
              top: FontScaling.getResponsiveSpacing(context, 12),
            ),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(
              FontScaling.getResponsiveSpacing(context, 16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.new_releases,
                  color: AppTheme.primary,
                  size: FontScaling.getResponsiveIconSize(context, 28) *
                      UIConstants.universalUIScale,
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
                Expanded(
                  child: Text(
                    l10n.whatsNewTitle,
                    style: FontScaling.getHeadingMedium(context).copyWith(
                      fontSize: FontScaling.getHeadingMedium(context).fontSize! *
                          UIConstants.universalUIScale,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                SemanticHelper.label(
                  label: l10n.closeButton,
                  isButton: true,
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                      size: FontScaling.getResponsiveIconSize(context, 24) *
                          UIConstants.universalUIScale,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            color: AppTheme.borderSubtle.withValues(alpha: 0.3),
            height: 1,
          ),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                FontScaling.getResponsiveSpacing(context, 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Release cards
                  ...ReleaseNotesData.releaseNotes.asMap().entries.map(
                    (entry) => ReleaseCard(
                      release: entry.value,
                      isLatest: entry.key == 0,
                    ),
                  ),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 8),
                  ),
                  // Website link button
                  _WebsiteLinkButton(),
                  SizedBox(
                    height: FontScaling.getResponsiveSpacing(context, 16) +
                        mediaQuery.padding.bottom,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent button to visit GratiStellar website
class _WebsiteLinkButton extends StatelessWidget {
  static const String _websiteUrl = 'https://gratistellar.com';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SemanticHelper.label(
      label: l10n.whatsNewVisitWebsite,
      hint: l10n.whatsNewVisitWebsiteHint,
      isButton: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.selectionClick();
            try {
              await UrlLaunchService.launchUrlSafely(_websiteUrl);
            } catch (e) {
              AppLogger.error('Failed to open website: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.errorOpenUrl('GratiStellar.com'),
                      style: FontScaling.getBodyMedium(context),
                    ),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: FontScaling.getResponsiveSpacing(context, 20),
              vertical: FontScaling.getResponsiveSpacing(context, 14),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.language,
                  color: AppTheme.primary,
                  size: FontScaling.getResponsiveIconSize(context, 20) *
                      UIConstants.universalUIScale,
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                Text(
                  l10n.whatsNewVisitWebsite,
                  style: FontScaling.getButtonText(context).copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontScaling.mediumWeight,
                  ),
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 4)),
                Icon(
                  Icons.open_in_new,
                  color: AppTheme.primary.withValues(alpha: 0.7),
                  size: FontScaling.getResponsiveIconSize(context, 16) *
                      UIConstants.universalUIScale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
