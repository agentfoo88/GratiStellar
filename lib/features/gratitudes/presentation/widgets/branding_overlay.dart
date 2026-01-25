import 'package:flutter/material.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';

/// Splash screen branding overlay shown on app launch
class BrandingOverlayWidget extends StatelessWidget {
  final VoidCallback onSkip;

  const BrandingOverlayWidget({
    super.key,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        label: AppLocalizations.of(context)!.tapToSkipBranding,
        button: true,
        child: GestureDetector(
          onTap: onSkip,
          child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: FontScaling.getAppTitle(context).copyWith(
                    fontSize: FontScaling.getAppTitle(context).fontSize! *
                        UIConstants.universalUIScale,
                  ),
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 16) *
                      UIConstants.universalUIScale,
                ),
                Text(
                  AppLocalizations.of(context)!.appSubtitle,
                  style: FontScaling.getSubtitle(context).copyWith(
                    fontSize: FontScaling.getSubtitle(context).fontSize! *
                        UIConstants.universalUIScale,
                  ),
                ),
                SizedBox(
                  height: FontScaling.getResponsiveSpacing(context, 32) *
                      UIConstants.universalUIScale,
                ),
                Text(
                  AppLocalizations.of(context)!.tapToSkipBranding,
                  style: FontScaling.getCaption(context).copyWith(
                    color: AppTheme.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}