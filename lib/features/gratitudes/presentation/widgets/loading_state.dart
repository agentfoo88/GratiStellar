import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';

/// Loading state screen shown while gratitudes are being loaded
class LoadingStateWidget extends StatelessWidget {
  final Color? previewColor;

  const LoadingStateWidget({
    super.key,
    this.previewColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFF4A6FA5),
              Color(0xFF166088),
              Color(0xFF0B1426),
              Color(0xFF2C3E50),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icon_star.svg',
                width: FontScaling.getResponsiveIconSize(context, 64),
                height: FontScaling.getResponsiveIconSize(context, 64),
                colorFilter: ColorFilter.mode(
                  previewColor ?? AppTheme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: FontScaling.getResponsiveSpacing(context, 20)),
              Text(
                AppLocalizations.of(context)!.loadingMessage,
                style: FontScaling.getBodyMedium(context).copyWith(
                  color: AppTheme.textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}