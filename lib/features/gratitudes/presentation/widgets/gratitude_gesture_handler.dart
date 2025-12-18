import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../camera_controller.dart';
import '../state/gratitude_provider.dart';

/// Gesture handler widget for pan, zoom, and tap interactions on the gratitude screen
class GratitudeGestureHandler extends StatefulWidget {
  final CameraController cameraController;
  final bool isAnimating;
  final Function(TapDownDetails) onStarTap;

  const GratitudeGestureHandler({
    super.key,
    required this.cameraController,
    required this.isAnimating,
    required this.onStarTap,
  });

  @override
  State<GratitudeGestureHandler> createState() =>
      _GratitudeGestureHandlerState();
}

class _GratitudeGestureHandlerState extends State<GratitudeGestureHandler> {
  bool _isMultiFingerGesture = false;
  DateTime? _lastScrollTime;

  void _handleScroll(PointerScrollEvent scrollEvent) {
    final provider = context.read<GratitudeProvider>();
    if (provider.mindfulnessMode) {
      provider.stopMindfulness();
    }

    final now = DateTime.now();
    if (_lastScrollTime != null &&
        now.difference(_lastScrollTime!).inMilliseconds < 16) {
      return;
    }
    _lastScrollTime = now;

    final delta = scrollEvent.scrollDelta.dy;
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );

    if (delta > 0) {
      widget.cameraController.zoomOut(1.1, screenCenter);
    } else {
      widget.cameraController.zoomIn(1.1, screenCenter);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (widget.isAnimating) return;

    final provider = context.read<GratitudeProvider>();
    if (provider.mindfulnessMode) {
      provider.stopMindfulness();
    }
    _isMultiFingerGesture = details.pointerCount > 1;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (widget.isAnimating) return;

    final provider = context.read<GratitudeProvider>();
    if (provider.mindfulnessMode) {
      provider.stopMindfulness();
    }

    if (details.scale != 1.0) {
      final scaleChange = (details.scale - 1.0).abs();
      if (scaleChange > 0.01) {
        const dampingFactor = 0.025;
        final dampenedScale =
            1.0 + ((details.scale - 1.0) * dampingFactor);
        final newScale = widget.cameraController.scale * dampenedScale;
        widget.cameraController.updateScale(
          newScale,
          details.focalPoint,
        );
      }
    }

    if (details.scale == 1.0) {
      widget.cameraController.updatePosition(
        details.focalPointDelta,
      );
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (widget.isAnimating) return;
    _isMultiFingerGesture = false;
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isAnimating) return;
    if (!_isMultiFingerGesture) {
      widget.onStarTap(details);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            _handleScroll(pointerSignal);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onScaleStart: widget.isAnimating ? null : _handleScaleStart,
          onScaleUpdate: widget.isAnimating ? null : _handleScaleUpdate,
          onScaleEnd: widget.isAnimating ? null : _handleScaleEnd,
          onTapDown: widget.isAnimating ? null : _handleTapDown,
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

