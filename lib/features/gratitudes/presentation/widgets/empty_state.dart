// lib/features/gratitudes/presentation/widgets/empty_state.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';

/// Empty state widget displayed when user has no gratitudes yet
///
/// Shows encouraging message to create first star
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icon_star.svg',
              width: FontScaling.getResponsiveIconSize(context, 64) * UIConstants.universalUIScale,
              height: FontScaling.getResponsiveIconSize(context, 64) * UIConstants.universalUIScale,
              colorFilter: ColorFilter.mode(AppTheme.textPrimary.withValues(alpha: 0.3), BlendMode.srcIn),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 24) * UIConstants.universalUIScale),
            Text(
              AppLocalizations.of(context)!.emptyStateTitle,
              style: FontScaling.getEmptyStateTitle(context).copyWith(
                fontSize: FontScaling.getEmptyStateTitle(context).fontSize! * UIConstants.universalUIScale,
              ),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale),
            Text(
              AppLocalizations.of(context)!.emptyStateSubtitle,
              style: FontScaling.getEmptyStateSubtitle(context).copyWith(
                fontSize: FontScaling.getEmptyStateSubtitle(context).fontSize! * UIConstants.universalUIScale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

