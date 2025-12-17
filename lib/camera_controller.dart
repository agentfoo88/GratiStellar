// Pure camera control system for GratiStellar - NO RENDERING LOGIC

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Vector4, Matrix4;
import 'core/accessibility/motion_helper.dart';
import 'storage.dart';
import 'core/utils/app_logger.dart';

class CameraController extends ChangeNotifier {
  // Camera state
  Offset _position = Offset.zero;
  Offset _parallaxPosition = Offset.zero; // Clean position for parallax layers
  double _scale = 1.0;
  double _maxPanDistance = 3000.0;

  // Stored for automatic bounds updates
  List<GratitudeStar> _stars = [];
  Size _screenSize = Size.zero;

  // Throttling for bounds updates during zoom (prevent crashes on low-end devices)
  DateTime? _lastBoundsUpdateTime;
  static const _boundsUpdateThrottleMs =
      500; // Only update bounds every 500ms during zoom

  // Constraints
  static const double minScale = 0.4;
  static const double maxScale = 5.0;
  static const double focusZoomLevel = 2.0;

  // ========================================
  // LAYER TRANSFORM CONFIGURATION
  // ========================================
  static const double backgroundParallax = 0.00;

  static const double nebulaParallax = 0.08;

  static const double vanGoghParallax = 0.1;

  // Animation
  AnimationController? _animationController;
  Animation<Offset>? _positionAnimation;
  Animation<double>? _scaleAnimation;
  TickerProvider? _vsync; // Store vsync for button-based zoom animations

  // Getters
  Offset get position => _position;
  double get scale => _scale;
  int get zoomPercentage => (_scale * 100).round();

  /// Set vsync provider for button-based zoom animations
  /// Should be called when controller is initialized with a TickerProvider
  void setVsync(TickerProvider vsync) {
    _vsync = vsync;
  }

  // Camera transform matrix
  Matrix4 get transform {
    return Matrix4.identity()
      ..translateByVector3(Vector3(_position.dx, _position.dy, 0.0))
      ..setDiagonal(Vector4(_scale, _scale, 1.0, 1.0));
  }

  // Transform caching to avoid redundant calculations
  Matrix4? _cachedNebulaTransform;
  Matrix4? _cachedVanGoghTransform;
  Offset _cachedTransformPosition = Offset.zero;

  // Layer-specific transforms with configurable parallax
  Matrix4 getBackgroundTransform() {
    return Matrix4.identity()..translateByVector3(
      Vector3(
        _parallaxPosition.dx *
            backgroundParallax, // Use _parallaxPosition instead
        _parallaxPosition.dy *
            backgroundParallax, // Use _parallaxPosition instead
        0.0,
      ),
    );
  }

  Matrix4 getNebulaTransform(Size screenSize) {
    // Cache check: only recalculate if scale, position, or screen size changed
    if (_cachedNebulaTransform != null &&
        _cachedTransformPosition == _parallaxPosition) {
      return _cachedNebulaTransform!;
    }

    // Fixed scale 1.0 - no zoom for background layers
    final transform = Matrix4.identity();
    transform.translateByVector3(
      Vector3(
        _parallaxPosition.dx * nebulaParallax,
        _parallaxPosition.dy * nebulaParallax,
        0.0,
      ),
    );

    // Update cache
    _cachedNebulaTransform = transform;
    _cachedTransformPosition = _parallaxPosition;

    return transform;
  }

  Matrix4 getVanGoghTransform(Size screenSize) {
    // Cache check: only recalculate if scale, position, or screen size changed
    if (_cachedVanGoghTransform != null &&
        _cachedTransformPosition == _parallaxPosition) {
      return _cachedVanGoghTransform!;
    }

    // Fixed scale 1.0 - no zoom for background layers
    final transform = Matrix4.identity();
    transform.translateByVector3(
      Vector3(
        _parallaxPosition.dx * vanGoghParallax,
        _parallaxPosition.dy * vanGoghParallax,
        0.0,
      ),
    );

    // Update cache
    _cachedVanGoghTransform = transform;
    _cachedTransformPosition = _parallaxPosition;

    return transform;
  }

  // Inverse transform for converting screen to world coordinates
  Offset screenToWorld(Offset screenPoint) {
    final adjustedPoint = screenPoint - _position;
    // Safety: ensure scale is never zero (should be clamped to minScale, but be defensive)
    if (_scale.abs() < 0.001) {
      AppLogger.warning(
        '⚠️ Very small scale detected in screenToWorld: $_scale, using minScale',
      );
      return adjustedPoint / minScale;
    }
    return adjustedPoint / _scale;
  }

  // Convert world to screen coordinates
  Offset worldToScreen(Offset worldPoint) {
    return (worldPoint * _scale) + _position;
  }

  // Calculate dynamic camera bounds based on star positions and zoom
  void updateBounds(List<GratitudeStar> stars, Size screenSize) {
    // Store for automatic updates
    _stars = stars;
    _screenSize = screenSize;

    if (stars.isEmpty) {
      _maxPanDistance = 2000.0;
      return;
    }

    // Find furthest star from origin in screen pixels
    // Optimized: use squared distance, only sqrt once at the end
    double maxDistanceSquared = 0.0;
    for (final star in stars) {
      final starWorldX = star.worldX * screenSize.width;
      final starWorldY = star.worldY * screenSize.height;
      final distanceSquared = starWorldX * starWorldX + starWorldY * starWorldY;
      maxDistanceSquared = math.max(maxDistanceSquared, distanceSquared);
    }
    final maxDistance = math.sqrt(maxDistanceSquared);

    // CRITICAL FIX: Padding must INCREASE with zoom level
    final double paddingFactor;
    if (_scale < 0.5) {
      paddingFactor = 0.6; // Zoomed way out: 60% padding
    } else if (_scale < 1.0) {
      paddingFactor = 1.0; // Medium zoom: 100% padding
    } else if (_scale < 2.0) {
      paddingFactor = 1.5; // Moderate zoom: 150% padding
    } else {
      // High zoom: Scale factor itself as padding
      // At 500% zoom, this gives 500% padding
      // Clamp to reasonable maximum to prevent overflow
      paddingFactor = math.min(_scale, 10.0);
    }

    _maxPanDistance = maxDistance + (maxDistance * paddingFactor);

    // Ensure minimum bounds and validate
    _maxPanDistance = math.max(_maxPanDistance, 2000.0);

    // Safety check: prevent extremely large values
    if (!_maxPanDistance.isFinite || _maxPanDistance > 100000.0) {
      _maxPanDistance = 100000.0;
    }

    AppLogger.info(
      '🎯 Pan distance at ${_scale.toStringAsFixed(1)}x zoom: ${_maxPanDistance.toStringAsFixed(0)}px (padding: ${(paddingFactor * 100).toStringAsFixed(0)}%)',
    );
  }

  /// Throttled bounds update - only recalculates if enough time has passed
  /// Prevents excessive calculations during continuous zoom gestures
  /// Uses adaptive throttling: longer delays at higher zoom levels
  void _updateBoundsThrottled() {
    if (_stars.isEmpty || _screenSize == Size.zero) return;

    final now = DateTime.now();
    if (_lastBoundsUpdateTime != null) {
      // Adaptive throttling: longer delays at higher zoom
      int throttleMs = _boundsUpdateThrottleMs;
      if (_scale > 3.0) {
        throttleMs = 800; // High zoom: 800ms
      } else if (_scale > 2.0) {
        throttleMs = 600; // Moderate zoom: 600ms
      }

      final timeSinceLastUpdate = now
          .difference(_lastBoundsUpdateTime!)
          .inMilliseconds;
      if (timeSinceLastUpdate < throttleMs) {
        // Too soon - skip this update
        return;
      }
    }

    // Enough time has passed - update bounds
    _lastBoundsUpdateTime = now;
    updateBounds(_stars, _screenSize);
  }

  // Update camera position during drag
  void updatePosition(Offset delta) {
    final newPosition = _position + delta;
    final newParallaxPosition = _parallaxPosition + delta;

    // Simple radial constraint
    final distance = math.sqrt(
      newPosition.dx * newPosition.dx + newPosition.dy * newPosition.dy,
    );

    final Offset constrainedPosition;
    final Offset constrainedParallaxPosition;

    if (distance > _maxPanDistance && distance > 0) {
      // Constrain to circle boundary (guard against division by zero)
      final factor = _maxPanDistance / distance;
      constrainedPosition = newPosition * factor;
      constrainedParallaxPosition = newParallaxPosition * factor;
    } else {
      constrainedPosition = newPosition;
      constrainedParallaxPosition = newParallaxPosition;
    }

    if (constrainedPosition != _position) {
      _position = constrainedPosition;
      _parallaxPosition = constrainedParallaxPosition;
      // Invalidate transform cache when position changes
      _cachedNebulaTransform = null;
      _cachedVanGoghTransform = null;
      notifyListeners();
    }
  }

  // Update camera scale with proper focal point handling
  void updateScale(double newScale, [Offset? focalPoint]) {
    // Safety check: ensure input is valid
    if (!newScale.isFinite || newScale <= 0) {
      AppLogger.warning('⚠️ Invalid scale value in updateScale: $newScale');
      return;
    }

    final constrainedScale = math.max(minScale, math.min(maxScale, newScale));

    // Prevent changes that are too small
    if ((constrainedScale - _scale).abs() < 0.001) {
      return;
    }

    // Add extra stability check for very low zoom levels
    if (constrainedScale < 0.4 && (constrainedScale - _scale).abs() < 0.01) {
      return;
    }

    if (constrainedScale != _scale) {
      // Cancel any existing animations first
      _animationController?.stop();

      if (focalPoint != null) {
        // For very small scales, use simpler calculation to avoid precision errors
        if (constrainedScale < 0.4) {
          _scale = constrainedScale;
          // Recalculate bounds (throttled to prevent crashes)
          _updateBoundsThrottled();
          notifyListeners();
        } else {
          // Normal focal point handling for higher zoom levels
          final worldFocus = screenToWorld(focalPoint);
          _scale = constrainedScale;

          // Recalculate bounds for new scale (throttled to prevent crashes)
          _updateBoundsThrottled();

          // Calculate the ideal new position based on focal point
          final newScreenFocus = worldToScreen(worldFocus);
          final adjustment = focalPoint - newScreenFocus;
          final idealNewPosition = _position + adjustment;
          // _parallaxPosition is NOT updated during zoom - stays locked

          // Apply radial constraint instead of asymmetric bounds
          final distance = math.sqrt(
            idealNewPosition.dx * idealNewPosition.dx +
                idealNewPosition.dy * idealNewPosition.dy,
          );

          if (distance > _maxPanDistance && distance > 0) {
            // Constrain to circle boundary (guard against division by zero)
            final factor = _maxPanDistance / distance;
            _position = idealNewPosition * factor;
            // _parallaxPosition stays unchanged during zoom
          } else {
            _position = idealNewPosition;
            // _parallaxPosition stays unchanged during zoom
          }

          notifyListeners();
        }
      } else {
        _scale = constrainedScale;
        // Recalculate bounds when scale changes (throttled to prevent crashes)
        _updateBoundsThrottled();
        notifyListeners();
      }
    }
  }

  // Zoom in by factor with optional focal point
  // Uses animation for smooth, crash-proof zoom on low-end devices
  void zoomIn([double factor = 1.5, Offset? focalPoint]) {
    if (_vsync == null) {
      // Fallback to direct update if vsync not available
      updateScale(_scale * factor, focalPoint);
      return;
    }

    final targetScale = (_scale * factor).clamp(minScale, maxScale);

    // Calculate target position based on focal point (screen center by default)
    // This ensures zoom happens around the focal point
    Offset? targetPosition;
    final focal =
        focalPoint ?? Offset(_screenSize.width / 2, _screenSize.height / 2);

    if (targetScale != _scale) {
      // Calculate world position of focal point at current scale
      final adjustedPoint = focal - _position;
      final worldFocus = adjustedPoint / _scale;

      // Calculate where that world point would be at target scale
      final newScreenFocus = (worldFocus * targetScale) + _position;

      // Adjust position to keep focal point in same screen location
      final adjustment = focal - newScreenFocus;
      final idealNewPosition = _position + adjustment;

      // Apply radial constraint
      final distance = math.sqrt(
        idealNewPosition.dx * idealNewPosition.dx +
            idealNewPosition.dy * idealNewPosition.dy,
      );

      if (distance > _maxPanDistance && distance > 0) {
        final constraintFactor = _maxPanDistance / distance;
        targetPosition = idealNewPosition * constraintFactor;
      } else {
        targetPosition = idealNewPosition;
      }
    }

    animateTo(
      targetPosition: targetPosition,
      targetScale: targetScale,
      duration: const Duration(milliseconds: 250), // Quick but smooth
      vsync: _vsync!,
    );
  }

  // Zoom out by factor with optional focal point
  // Uses animation for smooth, crash-proof zoom on low-end devices
  void zoomOut([double factor = 1.5, Offset? focalPoint]) {
    if (_vsync == null) {
      // Fallback to direct update if vsync not available
      updateScale(_scale / factor, focalPoint);
      return;
    }

    final targetScale = (_scale / factor).clamp(minScale, maxScale);

    // Calculate target position based on focal point (screen center by default)
    // This ensures zoom happens around the focal point
    Offset? targetPosition;
    final focal =
        focalPoint ?? Offset(_screenSize.width / 2, _screenSize.height / 2);

    if (targetScale != _scale) {
      // Calculate world position of focal point at current scale
      final adjustedPoint = focal - _position;
      final worldFocus = adjustedPoint / _scale;

      // Calculate where that world point would be at target scale
      final newScreenFocus = (worldFocus * targetScale) + _position;

      // Adjust position to keep focal point in same screen location
      final adjustment = focal - newScreenFocus;
      final idealNewPosition = _position + adjustment;

      // Apply radial constraint
      final distance = math.sqrt(
        idealNewPosition.dx * idealNewPosition.dx +
            idealNewPosition.dy * idealNewPosition.dy,
      );

      if (distance > _maxPanDistance && distance > 0) {
        final constraintFactor = _maxPanDistance / distance;
        targetPosition = idealNewPosition * constraintFactor;
      } else {
        targetPosition = idealNewPosition;
      }
    }

    animateTo(
      targetPosition: targetPosition,
      targetScale: targetScale,
      duration: const Duration(milliseconds: 250), // Quick but smooth
      vsync: _vsync!,
    );
  }

  // Zoom to exactly 100% (scale = 1.0)
  // Uses animation for smooth, crash-proof zoom on low-end devices
  void zoomTo100Percent([Offset? focalPoint]) {
    if (_vsync == null) {
      // Fallback to direct update if vsync not available
      updateScale(1.0, focalPoint);
      return;
    }

    // Calculate target position based on focal point (screen center by default)
    // This ensures zoom happens around the focal point
    Offset? targetPosition;
    final focal =
        focalPoint ?? Offset(_screenSize.width / 2, _screenSize.height / 2);

    if (_scale != 1.0) {
      // Calculate world position of focal point at current scale
      final adjustedPoint = focal - _position;
      final worldFocus = adjustedPoint / _scale;

      // Calculate where that world point would be at scale 1.0
      final newScreenFocus = (worldFocus * 1.0) + _position;

      // Adjust position to keep focal point in same screen location
      final adjustment = focal - newScreenFocus;
      final idealNewPosition = _position + adjustment;

      // Apply radial constraint
      final distance = math.sqrt(
        idealNewPosition.dx * idealNewPosition.dx +
            idealNewPosition.dy * idealNewPosition.dy,
      );

      if (distance > _maxPanDistance && distance > 0) {
        final constraintFactor = _maxPanDistance / distance;
        targetPosition = idealNewPosition * constraintFactor;
      } else {
        targetPosition = idealNewPosition;
      }
    }

    animateTo(
      targetPosition: targetPosition,
      targetScale: 1.0,
      duration: const Duration(milliseconds: 800), // Match Fit All animation
      curve: Curves.easeInOutCubic, // Match Fit All animation
      vsync: _vsync!,
    );
  }

  // Animate to specific position and scale
  void animateTo({
    Offset? targetPosition,
    double? targetScale,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeOutCubic,
    TickerProvider? vsync,
    BuildContext? context, // Added parameter
  }) {
    if (vsync == null) return;

    // Check for reduced motion
    final reduceMotion =
        context != null && MotionHelper.shouldReduceMotion(context);

    if (reduceMotion) {
      // Instant jump - no animation
      if (targetPosition != null) {
        _position = targetPosition;
        // _parallaxPosition stays unchanged
      }
      if (targetScale != null) {
        _scale = math.max(minScale, math.min(maxScale, targetScale));
      }
      notifyListeners();
      return;
    }

    // Normal animation code continues below
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: curve,
    );

    // Constrain target position to valid bounds if provided
    Offset? constrainedTargetPosition = targetPosition;
    if (targetPosition != null) {
      final distance = math.sqrt(
        targetPosition.dx * targetPosition.dx +
            targetPosition.dy * targetPosition.dy,
      );

      // Use bounds for target scale if animating scale, otherwise current bounds
      double boundsForTarget = _maxPanDistance;
      if (targetScale != null &&
          _stars.isNotEmpty &&
          _screenSize != Size.zero) {
        // Temporarily calculate what bounds would be at target scale
        final tempScale = _scale;
        _scale = math.max(minScale, math.min(maxScale, targetScale));
        updateBounds(_stars, _screenSize);
        boundsForTarget = _maxPanDistance;
        _scale = tempScale; // Restore current scale
        updateBounds(_stars, _screenSize); // Restore current bounds
      }

      // Safety: ensure boundsForTarget is always positive and finite
      boundsForTarget = math.max(boundsForTarget, 2000.0);
      if (!boundsForTarget.isFinite) {
        AppLogger.warning(
          '⚠️ Invalid boundsForTarget: $boundsForTarget, using default 2000.0',
        );
        boundsForTarget = 2000.0;
      }

      if (distance > boundsForTarget && distance > 0 && boundsForTarget > 0) {
        // Constrain target to valid bounds (guard against division by zero)
        final factor = boundsForTarget / distance;
        if (factor.isFinite) {
          constrainedTargetPosition = targetPosition * factor;
        } else {
          AppLogger.warning(
            '⚠️ Invalid factor calculated: $factor, using original position',
          );
          constrainedTargetPosition = targetPosition;
        }
      }
    }

    // No need to store delta - parallax position doesn't move during animations

    if (constrainedTargetPosition != null) {
      _positionAnimation = Tween<Offset>(
        begin: _position,
        end: constrainedTargetPosition,
      ).animate(curvedAnimation);
    }

    if (targetScale != null) {
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: math.max(minScale, math.min(maxScale, targetScale)),
      ).animate(curvedAnimation);
    }

    _animationController!.addListener(() {
      if (_positionAnimation != null) {
        _position = _positionAnimation!.value;
        // _parallaxPosition stays unchanged during animations
      }
      if (_scaleAnimation != null) {
        _scale = _scaleAnimation!.value;
        // Recalculate bounds when scale changes during animation (throttled to prevent crashes)
        _updateBoundsThrottled();
      }
      notifyListeners();
    });

    _animationController!.forward();
  }

  // Reset to home position
  void resetToHome(TickerProvider vsync) {
    animateTo(
      targetPosition: Offset.zero,
      targetScale: 1.0,
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );
  }

  // Fit all stars in view - Updated for normalized coordinates
  void fitAllStars(
    List<GratitudeStar> stars,
    Size screenSize,
    TickerProvider vsync,
  ) {
    if (stars.isEmpty) return;

    // Find bounds of all stars in world coordinates
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final star in stars) {
      final starX = star.worldX * screenSize.width;
      final starY = star.worldY * screenSize.height;

      minX = math.min(minX, starX);
      maxX = math.max(maxX, starX);
      minY = math.min(minY, starY);
      maxY = math.max(maxY, starY);
    }

    // Calculate center of all stars
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    // Calculate required scale to fit all stars with padding
    const padding = 100.0; // Padding in pixels
    final width = maxX - minX + padding * 2;
    final height = maxY - minY + padding * 2;

    final scaleX = screenSize.width / width;
    final scaleY = screenSize.height / height;
    final targetScale = math.min(scaleX, scaleY).clamp(minScale, maxScale);

    // Calculate camera position to center the bounds
    final targetPosition = Offset(
      screenSize.width / 2 - centerX * targetScale,
      screenSize.height / 2 - centerY * targetScale,
    );

    AppLogger.info(
      '📐 Fit all: bounds ($minX, $minY) to ($maxX, $maxY), scale: $targetScale',
    );

    animateTo(
      targetPosition: targetPosition,
      targetScale: targetScale,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      vsync: vsync,
    );
  }

  // Center camera on a specific world point (normalized coordinates)
  void centerOnPoint(Offset worldPoint, Size screenSize, TickerProvider vsync) {
    final targetScreenPos = Offset(screenSize.width / 2, screenSize.height / 2);
    final worldPosPixels = Offset(
      worldPoint.dx * screenSize.width,
      worldPoint.dy * screenSize.height,
    );

    // Use different calculation based on zoom level
    final Offset targetCameraPosition;
    if (_scale < 0.5) {
      // At low zoom, use current screen position + offset method
      // This avoids floating-point precision issues
      final currentScreenPos = worldToScreen(worldPosPixels);
      targetCameraPosition = _position + (targetScreenPos - currentScreenPos);
    } else {
      // Normal calculation for higher zoom levels
      targetCameraPosition = targetScreenPos - (worldPosPixels * _scale);
    }

    animateTo(
      targetPosition: targetCameraPosition,
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}
