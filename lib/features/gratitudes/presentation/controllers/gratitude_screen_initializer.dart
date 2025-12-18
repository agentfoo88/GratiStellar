import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/crashlytics_service.dart';
import '../../../../services/layer_cache_service.dart';
import '../../../../starfield.dart';
import '../../../../gratitude_stars.dart';
import '../../../../background.dart';

/// Helper class for initializing GratitudeScreen components
class GratitudeScreenInitializer {
  /// Set device orientation based on screen size
  /// Locks to portrait on phones, allows rotation on tablets/desktop
  static void setOrientationForScreenSize(Size screenSize) {
    // Lock to portrait on phones (width < 600), allow rotation on tablets/desktop
    // Using the shorter dimension to handle both portrait and landscape
    final minDimension = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;

    if (minDimension < 600) {
      // Phone - lock to portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      AppLogger.info(
        '🔒 Locked to portrait mode (screen width: ${screenSize.width})',
      );
    } else {
      // Tablet/Desktop - allow all orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      AppLogger.info(
        '🔓 All orientations allowed (screen width: ${screenSize.width})',
      );
    }
  }

  /// Load nebula asset image from bundle
  static Future<ui.Image?> loadNebulaAsset() async {
    try {
      final ByteData data = await rootBundle.load(
        'assets/textures/background-01.png',
      );
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      AppLogger.success('✅ Nebula asset loaded');
      return frameInfo.image;
    } catch (e) {
      AppLogger.error('⚠️ Failed to load nebula asset: $e');
      return null;
    }
  }

  /// Initialize precomputed elements (glow patterns, background gradients)
  static Map<String, dynamic> initializePrecomputedElements() {
    AppLogger.start('🌟 Starting initialization...');

    final glowPatterns = GratitudeStarService.generateGlowPatterns();
    AppLogger.info('✨ Generated ${glowPatterns.length} glow patterns');

    final backgroundGradients =
        BackgroundService.generateBackgroundGradients();
    AppLogger.info(
      '🎨 Generated ${backgroundGradients.length} background gradients',
    );

    return {
      'glowPatterns': glowPatterns,
      'backgroundGradients': backgroundGradients,
    };
  }

  /// Initialize layer cache asynchronously
  static Future<bool> initializeLayerCache(Size screenSize) async {
    final crashlytics = CrashlyticsService();

    try {
      crashlytics.log('Initializing layer cache');
      await LayerCacheService().initialize(screenSize);

      crashlytics.log('Layer cache ready');
      AppLogger.success('✅ Layer cache initialized');
      return true;
    } catch (e, stack) {
      crashlytics.recordError(
        e,
        stack,
        reason: 'Layer cache initialization failed',
      );
      AppLogger.error('⚠️ Layer cache failed: $e');
      // App continues without cache (will be slower but still works)
      return false;
    }
  }

  /// Generate Van Gogh stars for the screen
  static Map<String, List<VanGoghStar>> generateVanGoghStars(Size screenSize) {
    final allVanGoghStars =
        VanGoghStarService.generateVanGoghStars(screenSize);
    final staticCount = (allVanGoghStars.length * 0.9).round(); // 90% static
    final animatedVanGoghStars = allVanGoghStars
        .skip(staticCount)
        .toList(); // Last 10% animate

    AppLogger.info(
      '📐 Screen: ${screenSize.width.round()}x${screenSize.height.round()}',
    );
    AppLogger.info(
      '   🎨 Using cached layers (background, $staticCount Van Gogh stars)',
    );
    AppLogger.info(
      '   ✨ Animating: ${animatedVanGoghStars.length} Van Gogh stars',
    );
    AppLogger.info(
      '   📍 Camera bounds: ${allVanGoghStars.length} Van Gogh stars (for reference only)',
    );

    return {
      'all': allVanGoghStars,
      'animated': animatedVanGoghStars,
    };
  }

  /// Set crashlytics custom keys for screen dimensions
  static void setCrashlyticsScreenKeys(Size screenSize) {
    final crashlytics = CrashlyticsService();
    crashlytics.setCustomKey('screen_width', screenSize.width.round());
    crashlytics.setCustomKey('screen_height', screenSize.height.round());
  }

  /// Get initial screen size from platform dispatcher
  static Size getInitialScreenSize() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }
}

