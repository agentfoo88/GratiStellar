import 'package:flutter/material.dart';
import '../../../../camera_controller.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../storage.dart';

/// Controller for camera navigation operations specific to the gratitude screen
class CameraNavigationController {
  final CameraController cameraController;
  final TickerProvider vsync;
  final BuildContext context;

  CameraNavigationController({
    required this.cameraController,
    required this.vsync,
    required this.context,
  });

  /// Navigate to a star for mindfulness mode
  /// Positions the star at 40% from top, centered horizontally
  Future<void> navigateToMindfulnessStar(GratitudeStar star) async {
    final screenSize = MediaQuery.of(context).size;

    // Calculate world position in pixels
    final starWorldX = star.worldX * screenSize.width;
    final starWorldY = star.worldY * screenSize.height;
    final starWorldPos = Offset(starWorldX, starWorldY);

    AppLogger.info(
      '🧘 Navigating to mindfulness star at world: ($starWorldX, $starWorldY)',
    );

    // Calculate where we want the star to appear on screen (40% from top, centered horizontally)
    final desiredScreenPos = Offset(
      screenSize.width / 2,
      screenSize.height * AnimationConstants.mindfulnessVerticalPosition,
    );

    // Calculate the camera position needed to place the star at desiredScreenPos
    // At target zoom level (mindfulnessZoom), the camera position should be:
    // cameraPos = desiredScreenPos - (starWorldPos * targetZoom)
    final targetPosition = Offset(
      desiredScreenPos.dx - starWorldPos.dx * CameraConstants.mindfulnessZoom,
      desiredScreenPos.dy - starWorldPos.dy * CameraConstants.mindfulnessZoom,
    );

    // Safety check: ensure target position is reasonable (not NaN or infinite)
    if (!targetPosition.dx.isFinite || !targetPosition.dy.isFinite) {
      AppLogger.error('⚠️ Invalid target position calculated: $targetPosition');
      // Fallback: use simpler calculation
      final fallbackPosition = Offset(
        screenSize.width / 2 - starWorldX * CameraConstants.mindfulnessZoom,
        screenSize.height * AnimationConstants.mindfulnessVerticalPosition -
            starWorldY * CameraConstants.mindfulnessZoom,
      );
      if (fallbackPosition.dx.isFinite && fallbackPosition.dy.isFinite) {
        cameraController.animateTo(
          targetPosition: fallbackPosition,
          targetScale: CameraConstants.mindfulnessZoom,
          duration: AnimationConstants.mindfulnessTransition,
          curve: Curves.easeInOutCubic,
          vsync: vsync,
          context: context,
        );
      }
      return;
    }
    cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: CameraConstants.mindfulnessZoom,
      duration: AnimationConstants.mindfulnessTransition,
      curve: Curves.easeInOutCubic,
      vsync: vsync,
      context: context,
    );
  }

  /// Jump to a specific star, centering it on screen
  void jumpToStar(GratitudeStar star) {
    final screenSize = MediaQuery.of(context).size;

    // Convert star's normalized world coordinates to pixels
    final starWorldX = star.worldX * screenSize.width;
    final starWorldY = star.worldY * screenSize.height;

    // Calculate camera position to center the star at the new scale
    final targetPosition = Offset(
      screenSize.width / 2 - starWorldX * CameraConstants.jumpToStarZoom,
      screenSize.height / 2 - starWorldY * CameraConstants.jumpToStarZoom,
    );

    cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: CameraConstants.jumpToStarZoom,
      duration: AnimationConstants.jumpToStarAnimation,
      curve: Curves.easeInOutCubic,
      vsync: vsync,
      context: context,
    );
  }
}

