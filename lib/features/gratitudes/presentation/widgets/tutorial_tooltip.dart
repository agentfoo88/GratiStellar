import 'package:flutter/material.dart';

import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';
import '../../../../l10n/app_localizations.dart';

/// Positioned tooltip widget for onboarding tutorials
///
/// Displays a styled tooltip with dark background and yellow border
/// that matches the app's design language.
class TutorialTooltip extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final Alignment alignment;

  const TutorialTooltip({
    super.key,
    required this.message,
    required this.onDismiss,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SemanticHelper.label(
      label: message,
      hint: l10n.tapToDismiss,
      isButton: true,
      onTap: onDismiss,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: TooltipConstants.maxWidth * UIConstants.universalUIScale,
            minHeight: TooltipConstants.minHeight * UIConstants.universalUIScale,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: FontScaling.getResponsiveSpacing(context, TooltipConstants.paddingHorizontal) * UIConstants.universalUIScale,
            vertical: FontScaling.getResponsiveSpacing(context, TooltipConstants.paddingVertical) * UIConstants.universalUIScale,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(AppTheme.standardBorderRadius * UIConstants.universalUIScale),
            border: Border.all(
              color: AppTheme.primary,
              width: AppTheme.standardBorderWidth,
            ),
            boxShadow: [AppTheme.glowPrimary, AppTheme.shadowStandard],
          ),
          child: Text(
            message,
            style: FontScaling.getBodyMedium(context).copyWith(
              color: AppTheme.textPrimary,
              fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Star button tutorial tooltip positioned above the button
class StarButtonTutorialTooltip extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final double? bottomOffset;

  const StarButtonTutorialTooltip({
    super.key,
    required this.message,
    required this.onDismiss,
    this.bottomOffset,
  });

  @override
  Widget build(BuildContext context) {
    final offset = bottomOffset ?? TooltipConstants.bottomOffset;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + offset * UIConstants.universalUIScale,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TutorialTooltip(
              message: message,
              onDismiss: onDismiss,
            ),
            // Arrow pointing down to button
            CustomPaint(
              size: Size(
                TooltipConstants.arrowWidth * UIConstants.universalUIScale,
                TooltipConstants.arrowHeight * UIConstants.universalUIScale,
              ),
              painter: _TooltipArrowPainter(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mindfulness button tutorial tooltip positioned above the right button
class MindfulnessTutorialTooltip extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final double? bottomOffset;

  const MindfulnessTutorialTooltip({
    super.key,
    required this.message,
    required this.onDismiss,
    this.bottomOffset,
  });

  @override
  Widget build(BuildContext context) {
    final offset = bottomOffset ?? TooltipConstants.bottomOffset;

    // Calculate position to be above the mindfulness button (right side)
    final buttonSize = FontScaling.getResponsiveSpacing(context, BottomControlsConstants.actionButtonSize) * UIConstants.universalUIScale;
    final spacing = FontScaling.getResponsiveSpacing(context, BottomControlsConstants.buttonSpacing) * UIConstants.universalUIScale;
    final addStarSize = FontScaling.getResponsiveSpacing(context, BottomControlsConstants.addStarButtonSize) * UIConstants.universalUIScale;

    // Calculate offset from center to mindfulness button center
    final mindfulnessButtonOffset = (addStarSize / 2) + spacing + (buttonSize / 2);

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + offset * UIConstants.universalUIScale,
      left: 0,
      right: 0,
      child: Center(
        child: Transform.translate(
          // Shift right toward mindfulness button, but not completely (to keep tooltip readable)
          offset: Offset(mindfulnessButtonOffset * 0.4, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TutorialTooltip(
                message: message,
                onDismiss: onDismiss,
              ),
              // Arrow pointing down to mindfulness button
              Transform.translate(
                offset: Offset(mindfulnessButtonOffset * 0.4, 0),
                child: CustomPaint(
                  size: Size(
                    TooltipConstants.arrowWidth * UIConstants.universalUIScale,
                    TooltipConstants.arrowHeight * UIConstants.universalUIScale,
                  ),
                  painter: _TooltipArrowPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for tooltip arrow pointing down
class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
