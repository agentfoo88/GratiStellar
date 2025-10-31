import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../cached_painters.dart';
import '../../../../camera_controller.dart';
import '../../../../core/animation/animation_manager.dart';
import '../../../../gratitude_stars.dart';
import '../../../../services/layer_cache_service.dart';
import '../../../../starfield.dart';
import '../../../../storage.dart';
import 'floating_label.dart';

/// All visual rendering layers for the gratitude visualization
///
/// Includes: background, nebula, Van Gogh stars, starfield, floating labels,
/// birth animation, and gesture detection layer
class VisualLayersStack extends StatelessWidget {
  final bool layerCacheInitialized;
  final ui.Image? nebulaAssetImage;
  final List<VanGoghStar> animatedVanGoghStars;
  final List<GratitudeStar> gratitudeStars;
  final bool showAllGratitudes;
  final bool mindfulnessMode;
  final GratitudeStar? activeMindfulnessStar;
  final bool isAnimating;
  final GratitudeStar? animatingStar;
  final List<Paint> glowPatterns;
  final CameraController cameraController;
  final AnimationManager animationManager;
  final Size currentSize;

  const VisualLayersStack({
    super.key,
    required this.layerCacheInitialized,
    required this.nebulaAssetImage,
    required this.animatedVanGoghStars,
    required this.gratitudeStars,
    required this.showAllGratitudes,
    required this.mindfulnessMode,
    required this.activeMindfulnessStar,
    required this.isAnimating,
    required this.animatingStar,
    required this.glowPatterns,
    required this.cameraController,
    required this.animationManager,
    required this.currentSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Cached background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: cameraController,
            builder: (context, child) {
              return Transform(
                transform: cameraController.getBackgroundTransform(),
                child: CustomPaint(
                  painter: CachedBackgroundPainter(
                    layerCacheInitialized
                        ? LayerCacheService().backgroundImage
                        : null,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),

        // Layer 2: Nebula Asset (pre-made image)
        if (nebulaAssetImage != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [animationManager.background, cameraController]),
              builder: (context, child) {
                return Transform(
                  transform: cameraController.getNebulaTransform(currentSize),
                  child: CustomPaint(
                    painter: AssetNebulaPainter(
                      nebulaAssetImage,
                      animationManager.background.value,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),

        // Layer 2.5: Cached Van Gogh base + animated twinklers
        Positioned.fill(
          child: AnimatedBuilder(
            animation: cameraController,
            builder: (context, child) {
              return Transform(
                transform: cameraController.getVanGoghTransform(currentSize),
                child: CustomPaint(
                  painter: CachedVanGoghPainter(
                    layerCacheInitialized
                        ? LayerCacheService().vanGoghBaseImage
                        : null,
                    animatedVanGoghStars,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),

        // Layer 3: Visual starfield (rendering only, no gestures)
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: cameraController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Stars layer
                    Transform(
                      transform: cameraController.transform,
                      child: StarfieldCanvas(
                        stars: gratitudeStars,
                        animationController: animationManager.star,
                        glowPatterns: glowPatterns,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Layer 3.5: Floating labels (NO TRANSFORM - window level)
        if (showAllGratitudes || mindfulnessMode)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: cameraController,
                builder: (context, child) {
                  final starsToShow =
                  mindfulnessMode && activeMindfulnessStar != null
                      ? [activeMindfulnessStar!]
                      : gratitudeStars;

                  // Viewport culling: filter out off-screen stars
                  final visibleStars = starsToShow.where((star) {
                    final starX = star.worldX * currentSize.width;
                    final starY = star.worldY * currentSize.height;
                    final starScreenX =
                        (starX * cameraController.scale) +
                            cameraController.position.dx;
                    final starScreenY =
                        (starY * cameraController.scale) +
                            cameraController.position.dy;

                    // Check if star is within viewport + margin
                    const margin = 300.0; // Extra margin for labels
                    return starScreenX > -margin &&
                        starScreenX < currentSize.width + margin &&
                        starScreenY > -margin &&
                        starScreenY < currentSize.height + margin;
                  }).toList();

                  return Stack(
                    children: visibleStars.map((star) {
                      // In mindfulness mode, animate opacity
                      if (mindfulnessMode) {
                        return TweenAnimationBuilder<double>(
                          key: Key(star.id), // ← star.id should be unique
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 1000),
                          builder: (context, opacity, child) {
                            return FloatingGratitudeLabel(
                              star: star,
                              screenSize: currentSize,
                              cameraScale: cameraController.scale,
                              cameraPosition: cameraController.position,
                              opacity: opacity,
                            );
                          },
                        );
                      }

                      // Normal mode - no opacity animation
                      return FloatingGratitudeLabel(
                        key: Key(star.id), // ← star.id should be unique
                        star: star,
                        screenSize: currentSize,
                        cameraScale: cameraController.scale,
                        cameraPosition: cameraController.position,
                        opacity: 1.0,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

        // Animated star birth layer
        if (isAnimating && animatingStar != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [animationManager.birth!, cameraController]),
              builder: (context, child) {
                return Transform(
                  transform: cameraController.transform,
                  child: AnimatedStarBirth(
                    star: animatingStar!,
                    animation: animationManager.birth!,
                    cameraController: cameraController,
                    screenSize: currentSize,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}