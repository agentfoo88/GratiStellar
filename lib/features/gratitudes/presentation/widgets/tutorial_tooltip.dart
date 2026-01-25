import 'package:flutter/material.dart';

import '../../../../core/accessibility/semantic_helper.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../font_scaling.dart';

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
    return SemanticHelper.label(
      label: message,
      hint: 'Tap to dismiss',
      isButton: true,
      onTap: onDismiss,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 280 * UIConstants.universalUIScale,
            minHeight: 48 * UIConstants.universalUIScale, // WCAG min touch target
          ),
          padding: EdgeInsets.symmetric(
            horizontal: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale,
            vertical: FontScaling.getResponsiveSpacing(context, 14) * UIConstants.universalUIScale,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(20 * UIConstants.universalUIScale),
            border: Border.all(
              color: AppTheme.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
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
  final double bottomOffset;

  const StarButtonTutorialTooltip({
    super.key,
    required this.message,
    required this.onDismiss,
    this.bottomOffset = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + bottomOffset * UIConstants.universalUIScale,
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
              size: Size(20 * UIConstants.universalUIScale, 10 * UIConstants.universalUIScale),
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
  final double bottomOffset;

  const MindfulnessTutorialTooltip({
    super.key,
    required this.message,
    required this.onDismiss,
    this.bottomOffset = 140,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate position to be above the mindfulness button (right side)
    final buttonSize = FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale;
    final spacing = FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale;
    final addStarSize = FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale;

    // Calculate offset from center to mindfulness button center
    final mindfulnessButtonOffset = (addStarSize / 2) + spacing + (buttonSize / 2);

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + bottomOffset * UIConstants.universalUIScale,
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
                  size: Size(20 * UIConstants.universalUIScale, 10 * UIConstants.universalUIScale),
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
