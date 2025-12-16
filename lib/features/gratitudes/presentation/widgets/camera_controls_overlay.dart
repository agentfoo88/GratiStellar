import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../camera_controller.dart';
import '../../../../storage.dart';

/// Camera control UI overlay with zoom buttons
class CameraControlsOverlay extends StatelessWidget {
  final CameraController cameraController;
  final List<GratitudeStar> stars;
  final Size screenSize;
  final TickerProvider vsync;
  final EdgeInsets safeAreaPadding;
  final VoidCallback?
  onButtonZoom; // Callback to clear gesture state when buttons are used

  const CameraControlsOverlay({
    super.key,
    required this.cameraController,
    required this.stars,
    required this.screenSize,
    required this.vsync,
    required this.safeAreaPadding,
    this.onButtonZoom,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSize.width < 500;
    final isTablet = screenSize.width > 600;

    // Responsive sizing
    final controlSize = isMobile ? 48.0 : (isTablet ? 50.0 : 48.0);
    final fontSize = isMobile ? 12.0 : 14.0;
    final padding = isMobile ? 8.0 : 12.0;

    final rightMargin = isMobile
        ? math.min(8.0, screenSize.width * 0.02)
        : 16.0;
    final bottomMargin = (isMobile ? 80.0 : 120.0) + safeAreaPadding.bottom;

    final maxControlWidth = controlSize + padding * 2;
    final safeRightMargin = math.max(rightMargin, 4.0);
    final adjustedRightMargin =
        (rightMargin + maxControlWidth > screenSize.width * 0.25)
        ? screenSize.width * 0.02
        : safeRightMargin;

    return Positioned(
      bottom: bottomMargin,
      right: adjustedRightMargin,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: padding * 0.7,
                      ),
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
                                  borderRadius: BorderRadius.circular(
                                    controlSize / 2,
                                  ),
                                  onTap: () {
                                    // Clear any active gesture state before button zoom
                                    onButtonZoom?.call();
                                    final screenCenter = Offset(
                                      screenSize.width / 2,
                                      screenSize.height / 2,
                                    );
                                    cameraController.zoomIn(1.5, screenCenter);
                                  },
                                  child: Icon(
                                    Icons.zoom_in,
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
                                  borderRadius: BorderRadius.circular(
                                    controlSize / 2,
                                  ),
                                  onTap: () {
                                    // Clear any active gesture state before button zoom
                                    onButtonZoom?.call();
                                    final screenCenter = Offset(
                                      screenSize.width / 2,
                                      screenSize.height / 2,
                                    );
                                    cameraController.zoomOut(1.5, screenCenter);
                                  },
                                  child: Icon(
                                    Icons.zoom_out,
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
                            borderRadius: BorderRadius.circular(
                              controlSize / 2,
                            ),
                            onTap: () {
                              // Clear any active gesture state before button zoom
                              onButtonZoom?.call();
                              final screenCenter = Offset(
                                screenSize.width / 2,
                                screenSize.height / 2,
                              );
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
                            borderRadius: BorderRadius.circular(
                              controlSize / 2,
                            ),
                            onTap: () {
                              // Clear any active gesture state before button zoom
                              onButtonZoom?.call();
                              cameraController.fitAllStars(
                                stars,
                                screenSize,
                                vsync,
                              );
                            },
                            child: Icon(
                              Icons.fit_screen,
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
      ),
    );
  }
}
