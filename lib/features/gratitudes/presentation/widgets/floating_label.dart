// lib/features/gratitudes/presentation/widgets/floating_label.dart

import 'package:flutter/material.dart';

import '../../../../core/config/constants.dart';
import '../../../../storage.dart';
import '../../../../font_scaling.dart';

// Floating label widget for displaying gratitude text
class FloatingGratitudeLabel extends StatelessWidget {
  final GratitudeStar star;
  final Size screenSize;
  final double cameraScale;
  final Offset cameraPosition;
  final double opacity;

  const FloatingGratitudeLabel({
    super.key,
    required this.star,
    required this.screenSize,
    required this.cameraScale,
    required this.cameraPosition,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Work in world coordinates
    final starX = star.worldX * screenSize.width;
    final starY = star.worldY * screenSize.height;

    // Adaptive width: longer text gets wider boxes
    final maxLabelWidth = star.text.length > 150
        ? screenSize.width * 0.5  // 50% width for long gratitudes
        : screenSize.width * 0.4; // 40% width for normal

    // Enhanced edge padding that accounts for zoom level
    final dynamicEdgePadding = 8.0 + (40.0 / cameraScale.clamp(0.5, 2.0));

// Convert star world position to screen position
    final starScreenX = (starX * cameraScale) + cameraPosition.dx;
    final starScreenY = (starY * cameraScale) + cameraPosition.dy;

// Apply fixed screen-space offset
    const fixedScreenOffset = 30.0;
    final labelScreenY = starScreenY + fixedScreenOffset;

// Hide label if star is off-screen
    if (starScreenX < -maxLabelWidth ||
        starScreenX > screenSize.width + maxLabelWidth ||
        starScreenY < -100 ||
        starScreenY > screenSize.height + 100) {
      return SizedBox.shrink();
    }

// Calculate desired centered position
    double horizontalTranslation = -0.5;

// Check if label would overflow left edge
    final labelLeftEdge = starScreenX - (maxLabelWidth / 2);
    if (labelLeftEdge < dynamicEdgePadding) {
      final shiftRight = dynamicEdgePadding - labelLeftEdge;
      horizontalTranslation = -0.5 + (shiftRight / maxLabelWidth);
    }

// Check if label would overflow right edge
    final labelRightEdge = starScreenX + (maxLabelWidth / 2);
    if (labelRightEdge > screenSize.width - dynamicEdgePadding) {
      final overhang = labelRightEdge - (screenSize.width - dynamicEdgePadding);
      horizontalTranslation = -0.5 - (overhang / maxLabelWidth);
    }

// Clamp translation to prevent over-shifting
    horizontalTranslation = horizontalTranslation.clamp(-0.9, -0.1);

    return Positioned(
      left: starScreenX,
      top: labelScreenY,
      child: FractionalTranslation(
        translation: Offset(horizontalTranslation, 0),
        child: Opacity(
          opacity: opacity,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxLabelWidth,
              maxHeight: 200.0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: FontScaling.getResponsiveSpacing(context, 12),
              vertical: FontScaling.getResponsiveSpacing(context, 8),
            ),
            decoration: BoxDecoration(
              color: Color(0xFF1A2238).withValues(alpha: UIConstants.labelBackgroundAlpha),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: star.color.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: star.color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxLabelWidth - FontScaling.getResponsiveSpacing(context, 24),
                ),
                child: Text(
                  star.text,
                  style: _getAdaptiveTextStyle(context, star.text).copyWith(  // ← This name
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: null,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  TextStyle _getAdaptiveTextStyle(BuildContext context, String text) {
    final charCount = text.length;

    if (charCount < 100) {
      // Short text: Use caption size (13-16px)
      return FontScaling.getCaption(context);
    } else if (charCount < 200) {
      // Medium text: Use smaller caption or body small
      return FontScaling.getBodySmall(context);
    } else {
      // Long text (200-300): Smallest readable size
      // Use the smallest available style, but ensure minimum 12px
      final bodySmall = FontScaling.getBodySmall(context);
      return bodySmall.copyWith(
        fontSize: (bodySmall.fontSize! * 0.85).clamp(12.0, bodySmall.fontSize!),
      );
    }
  }
}