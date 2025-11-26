import 'package:flutter/material.dart';

import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/config/constants.dart';
import '../../../../font_scaling.dart';
import '../../../../galaxy_metadata.dart';
import '../../../../l10n/app_localizations.dart';

/// Individual galaxy list item widget
///
/// Shows galaxy name, star count, created date, and active badge
class GalaxyListItem extends StatelessWidget {
  final GalaxyMetadata galaxy;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const GalaxyListItem({
    super.key,
    required this.galaxy,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SemanticHelper.label(
      label: '${galaxy.name}, ${galaxy.starCount} stars',
      hint: isActive
          ? 'Currently active galaxy. Long press to rename.'
          : 'Tap to switch to this galaxy. Long press to rename.',
      isButton: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: FontScaling.getResponsiveSpacing(context, 16),
            vertical: FontScaling.getResponsiveSpacing(context, 12),
          ),
          decoration: BoxDecoration(
            color: isActive
                ? Color(0xFFFFE135).withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive
                    ? Color(0xFFFFE135)
                    : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              // Star icon
              Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFE135),
                size: FontScaling.getResponsiveIconSize(context, 32) *
                    UIConstants.universalUIScale,
              ),
              SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),

              // Galaxy info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            galaxy.name,
                            style: FontScaling.getBodyLarge(context).copyWith(
                              fontSize: FontScaling.getBodyLarge(context)
                                  .fontSize! *
                                  UIConstants.universalUIScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFE135),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.galaxyActiveBadge,
                              style: FontScaling.getCaption(context).copyWith(
                                color: Color(0xFF1A2238),
                                fontWeight: FontWeight.bold,
                                fontSize: FontScaling.mobileCaption * 0.75,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${galaxy.starCount} ${galaxy.starCount == 1 ? 'star' : 'stars'} • Created ${_formatDate(galaxy.createdAt)}',
                      style: FontScaling.getCaption(context).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: FontScaling.getResponsiveIconSize(context, 16) *
                    UIConstants.universalUIScale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return '${date.year}';
    }
  }
}