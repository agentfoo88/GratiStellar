// camera_controller.dart
// Pure camera control system for GratiStellar - NO RENDERING LOGIC
// Updated to work with normalized coordinate system

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Vector4, Matrix4;

import 'storage.dart'; // Import for GratitudeStar

class CameraController extends ChangeNotifier {
  // Camera state
  Offset _position = Offset.zero;
  Offset _parallaxPosition = Offset.zero;  // NEW: Clean position for parallax layers
  double _scale = 1.0;
  double _maxPanDistance = 3000.0;

  // Constraints
  static const double minScale = 0.4;
  static const double maxScale = 5.0;
  static const double focusZoomLevel = 2.0;

// ========================================
// LAYER TRANSFORM CONFIGURATION
// ========================================
  static const double backgroundParallax = 0.00;
  static const double backgroundZoom = 0.0;

  static const double nebulaParallax = 0.08;
  static const double nebulaZoom = 0.05;

  static const double vanGoghParallax = 0.1;
  static const double vanGoghZoom = 0.05;

  // Animation
  AnimationController? _animationController;
  Animation<Offset>? _positionAnimation;
  Animation<double>? _scaleAnimation;

  // Getters
  Offset get position => _position;
  double get scale => _scale;
  int get zoomPercentage => (_scale * 100).round();

  // Camera transform matrix
  Matrix4 get transform {
    return Matrix4.identity()
      ..translateByVector3(Vector3(_position.dx, _position.dy, 0.0))
      ..setDiagonal(Vector4(_scale, _scale, 1.0, 1.0));
  }
// Layer-specific transforms with configurable parallax
  Matrix4 getBackgroundTransform() {
    return Matrix4.identity()
      ..translateByVector3(Vector3(
          _parallaxPosition.dx * backgroundParallax,  // Use _parallaxPosition instead
          _parallaxPosition.dy * backgroundParallax,  // Use _parallaxPosition instead
          0.0
      ));
  }

  Matrix4 getNebulaTransform(Size screenSize) {
    final minimalZoom = 1.0 + ((_scale - 1.0) * nebulaZoom);
    final transform = Matrix4.identity();
    transform.translateByVector3(Vector3(screenSize.width / 2, screenSize.height / 2, 0.0));
    transform.setDiagonal(Vector4(minimalZoom, minimalZoom, 1.0, 1.0));
    transform.translateByVector3(Vector3(-screenSize.width / 2, -screenSize.height / 2, 0.0));
    transform.translateByVector3(Vector3(
        _parallaxPosition.dx * nebulaParallax,
        _parallaxPosition.dy * nebulaParallax,
        0.0
    ));
    return transform;
  }

  Matrix4 getVanGoghTransform(Size screenSize) {
    final minimalZoom = 1.0 + ((_scale - 1.0) * vanGoghZoom);
    final transform = Matrix4.identity();
    transform.translateByVector3(Vector3(screenSize.width / 2, screenSize.height / 2, 0.0));
    transform.setDiagonal(Vector4(minimalZoom, minimalZoom, 1.0, 1.0));
    transform.translateByVector3(Vector3(-screenSize.width / 2, -screenSize.height / 2, 0.0));
    transform.translateByVector3(Vector3(
        _parallaxPosition.dx * vanGoghParallax,
        _parallaxPosition.dy * vanGoghParallax,
        0.0
    ));
    return transform;
  }

  // Inverse transform for converting screen to world coordinates
  Offset screenToWorld(Offset screenPoint) {
    final adjustedPoint = screenPoint - _position;
    return adjustedPoint / _scale;
  }

  // Convert world to screen coordinates
  Offset worldToScreen(Offset worldPoint) {
    return (worldPoint * _scale) + _position;
  }

  // Calculate dynamic camera bounds based on star positions and zoom
  void updateBounds(List<GratitudeStar> stars, Size screenSize) {
    if (stars.isEmpty) {
      _maxPanDistance = 2000.0;
      return;
    }

    // Find furthest star from origin
    double maxDistance = 0.0;
    for (final star in stars) {
      final starWorldX = star.worldX * screenSize.width;
      final starWorldY = star.worldY * screenSize.height;
      final distance = math.sqrt(starWorldX * starWorldX + starWorldY * starWorldY);
      maxDistance = math.max(maxDistance, distance);
    }

    // Calculate padding based on zoom level
    final paddingFactor = _scale < 0.5 ? 0.5   // Zoomed out: 50% padding
        : _scale < 1.0 ? 0.3   // Medium: 30% padding
        : 0.2;                 // Zoomed in: 20% padding

    _maxPanDistance = maxDistance + (maxDistance * paddingFactor);

    // Ensure minimum bounds
    _maxPanDistance = math.max(_maxPanDistance, 2000.0);
  }

  // Update camera position during drag
  void updatePosition(Offset delta) {
    print('Before update: _parallaxPosition = $_parallaxPosition, delta = $delta'); // DEBUG

    final newPosition = _position + delta;
    final newParallaxPosition = _parallaxPosition + delta;

    // Apply boundary constraints
    final constrainedPosition = Offset(
      math.max(-_maxPanDistance, math.min(_maxPanDistance, newPosition.dx)),
      math.max(-_maxPanDistance, math.min(_maxPanDistance, newPosition.dy)),
    );

    final constrainedParallaxPosition = Offset(
      math.max(-_maxPanDistance, math.min(_maxPanDistance, newParallaxPosition.dx)),
      math.max(-_maxPanDistance, math.min(_maxPanDistance, newParallaxPosition.dy)),
    );

    if (constrainedPosition != _position) {
      _position = constrainedPosition;
      _parallaxPosition = constrainedParallaxPosition;
      print('After update: _parallaxPosition = $_parallaxPosition'); // DEBUG
      notifyListeners();
    }
  }

  // Update camera scale with proper focal point handling
  void updateScale(double newScale, [Offset? focalPoint]) {
    final constrainedScale = math.max(minScale, math.min(maxScale, newScale));

    // Prevent changes that are too small OR when scale gets too extreme
    if ((constrainedScale - _scale).abs() < 0.001) return;

    // Add extra stability check for very low zoom levels
    if (constrainedScale < 0.4 && (constrainedScale - _scale).abs() < 0.01) return;

    if (constrainedScale != _scale) {
      // Cancel any existing animations first
      _animationController?.stop();

      if (focalPoint != null) {
        // For very small scales, use simpler calculation to avoid precision errors
        if (constrainedScale < 0.4) {
          _scale = constrainedScale;
          notifyListeners();
        } else {
          // Normal focal point handling for higher zoom levels
          final worldFocus = screenToWorld(focalPoint);
          _scale = constrainedScale;
          final newScreenFocus = worldToScreen(worldFocus);
          final adjustment = focalPoint - newScreenFocus;
          _position = _position + adjustment;
          notifyListeners();
        }
      } else {
        _scale = constrainedScale;
        notifyListeners();
      }
    }
  }

  // Zoom in by factor with optional focal point
  void zoomIn([double factor = 1.5, Offset? focalPoint]) {
    updateScale(_scale * factor, focalPoint);
  }

  // Zoom out by factor with optional focal point
  void zoomOut([double factor = 1.5, Offset? focalPoint]) {
    updateScale(_scale / factor, focalPoint);
  }

  // Zoom to exactly 100% (scale = 1.0)
  void zoomTo100Percent([Offset? focalPoint]) {
    updateScale(1.0, focalPoint);
  }

  // Animate to specific position and scale
  void animateTo({
    Offset? targetPosition,
    double? targetScale,
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeOutCubic,
    TickerProvider? vsync,
  }) {
    if (vsync == null) return;

    _animationController?.dispose();
    _animationController = AnimationController(duration: duration, vsync: vsync);

    final curvedAnimation = CurvedAnimation(parent: _animationController!, curve: curve);

    if (targetPosition != null) {
      _positionAnimation = Tween<Offset>(
        begin: _position,
        end: targetPosition,
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
      }
      if (_scaleAnimation != null) {
        _scale = _scaleAnimation!.value;
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
  void fitAllStars(List<GratitudeStar> stars, Size screenSize, TickerProvider vsync) {
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

    print('📐 Fit all: bounds ($minX, $minY) to ($maxX, $maxY), scale: $targetScale');

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
    final worldPosPixels = Offset(worldPoint.dx * screenSize.width, worldPoint.dy * screenSize.height);

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

// Helper widget for camera control UI with proper tap isolation
class CameraControlsOverlay extends StatelessWidget {
  final CameraController cameraController;
  final List<GratitudeStar> stars;
  final Size screenSize;
  final TickerProvider vsync;
  final EdgeInsets safeAreaPadding;

  const CameraControlsOverlay({
    super.key,
    required this.cameraController,
    required this.stars,
    required this.screenSize,
    required this.vsync,
    required this.safeAreaPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSize.width < 500;
    final isTablet = screenSize.width > 600;

    // Responsive sizing
    final controlSize = isMobile ? 48.0 : (isTablet ? 50.0 : 48.0);
    final fontSize = isMobile ? 12.0 : 14.0;
    final padding = isMobile ? 8.0 : 12.0;

    final rightMargin = isMobile ? math.min(8.0, screenSize.width * 0.02) : 16.0;
    final bottomMargin = (isMobile ? 80.0 : 120.0) + safeAreaPadding.bottom;

    final maxControlWidth = controlSize + padding * 2;
    final safeRightMargin = math.max(rightMargin, 4.0);
    final adjustedRightMargin = (rightMargin + maxControlWidth > screenSize.width * 0.25)
        ? screenSize.width * 0.02
        : safeRightMargin;

    return Positioned(
      bottom: bottomMargin,
      right: adjustedRightMargin,
      // child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: cameraController,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: false,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Zoom percentage indicator
                    Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2238).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${cameraController.zoomPercentage}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            // letterSpacing: 0.5, // Add letter spacing
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: padding),

                    // Zoom controls
                    Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2238).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(controlSize / 2),
                          border: Border.all(
                            color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Zoom In
                              SizedBox(
                                width: controlSize,
                                height: controlSize,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(controlSize / 2),
                                    onTap: () {
                                      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
                                      cameraController.zoomIn(1.5, screenCenter);
                                    },
                                    child: Icon(Icons.zoom_in,
                                      color: Colors.white,
                                      size: controlSize * 0.5,
                                    ),
                                  ),
                                ),
                              ),

                              // Zoom Out
                              SizedBox(
                                width: controlSize,
                                height: controlSize,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(controlSize / 2),
                                    onTap: () {
                                      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
                                      cameraController.zoomOut(1.5, screenCenter);
                                    },
                                    child: Icon(Icons.zoom_out,
                                      color: Colors.white,
                                      size: controlSize * 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: padding),

                    // 100% Zoom button
                    Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2238).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(controlSize / 2),
                          border: Border.all(
                            color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: SizedBox(
                          width: controlSize,
                          height: controlSize,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(controlSize / 2),
                              onTap: () {
                                final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
                                cameraController.zoomTo100Percent(screenCenter);
                              },
                              child: Center(
                                child: Text(
                                  '100%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize * 0.75,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: padding),

                    // Fit All button
                    Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2238).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(controlSize / 2),
                          border: Border.all(
                            color: const Color(0xFFFFE135).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: SizedBox(
                          width: controlSize,
                          height: controlSize,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(controlSize / 2),
                              onTap: () {
                                cameraController.fitAllStars(stars, screenSize, vsync);
                              },
                              child: Icon(Icons.fit_screen,
                                color: Colors.white,
                                size: controlSize * 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
      //  ),
      ),
    );
  }
}