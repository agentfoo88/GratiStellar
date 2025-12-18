import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/layer_cache_service.dart';
import '../../../../services/auth_service.dart';
import '../state/gratitude_provider.dart';
import '../../../../camera_controller.dart';
import '../../../../core/animation/animation_manager.dart';
import '../../../../starfield.dart';
import 'gratitude_screen_initializer.dart';

/// Controller for managing lifecycle events in GratitudeScreen
class GratitudeLifecycleController {
  final BuildContext context;
  final CameraController cameraController;
  final AnimationManager animationManager;
  final AuthService authService;
  final Future<void> Function() loadGratitudes;
  final void Function(VoidCallback) setState;
  final bool Function() mounted;

  // State tracking
  bool isAppInBackground = false;
  bool allowRegeneration = false;
  Size? lastKnownSize;
  Timer? resizeDebounceTimer;

  // Callbacks for state updates
  final void Function(bool) onLayerCacheInitializedChanged;
  final void Function(List<VanGoghStar>) onAllVanGoghStarsChanged;
  final void Function(List<VanGoghStar>) onAnimatedVanGoghStarsChanged;
  final void Function(bool) onIsRegeneratingChanged;

  GratitudeLifecycleController({
    required this.context,
    required this.cameraController,
    required this.animationManager,
    required this.authService,
    required this.loadGratitudes,
    required this.setState,
    required this.mounted,
    required this.onLayerCacheInitializedChanged,
    required this.onAllVanGoghStarsChanged,
    required this.onAnimatedVanGoghStarsChanged,
    required this.onIsRegeneratingChanged,
  });

  /// Handle app lifecycle state changes
  void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App going to background
        if (!isAppInBackground) {
          isAppInBackground = true;
          animationManager.pauseAll();

          // CRITICAL: Force immediate sync when app goes to background
          // This prevents data loss if app is killed by system
          final provider = context.read<GratitudeProvider>();
          if (provider.hasPendingChanges && authService.hasEmailAccount) {
            AppLogger.sync('📤 App backgrounding - forcing immediate sync');
            provider.forceSync().catchError((e) {
              AppLogger.sync('⚠️ Background sync failed: $e');
            });
          }
        }
        break;

      case AppLifecycleState.resumed:
        // App coming back to foreground
        if (isAppInBackground) {
          isAppInBackground = false;
          animationManager.resumeAll();

          // Reload gratitudes when app resumes (Provider handles sync)
          if (authService.hasEmailAccount) {
            loadGratitudes();
          }
        }
        break;

      case AppLifecycleState.hidden:
        // Do nothing for now
        break;
    }
  }

  /// Handle screen metrics changes (resize, rotation)
  void handleMetricsChange(bool layerCacheInitialized) {
    // Don't use MediaQuery during build - get size from window
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final currentSize = view.physicalSize / view.devicePixelRatio;

    // Update orientation lock based on new screen size
    GratitudeScreenInitializer.setOrientationForScreenSize(currentSize);

    // First time seeing the size - just store it, don't regenerate
    if (lastKnownSize == null) {
      lastKnownSize = currentSize;
      AppLogger.start('📐 Initial screen size detected: $currentSize');

      // Allow regeneration after 3 seconds (after splash/initialization)
      Future.delayed(Duration(seconds: 3), () {
        if (mounted()) {
          allowRegeneration = true;
          AppLogger.success('✅ Regeneration now allowed');
        }
      });
      return;
    }

    // Don't regenerate if not allowed yet (still initializing)
    if (!allowRegeneration) {
      AppLogger.start(
        '📐 Size changed but regeneration blocked (still initializing)',
      );
      lastKnownSize = currentSize;
      return;
    }

    // Check if size actually changed significantly (avoid pixel-level jitter)
    final widthDiff = (currentSize.width - lastKnownSize!.width).abs();
    final heightDiff = (currentSize.height - lastKnownSize!.height).abs();

    // Only regenerate if change is >50 pixels (avoid noise)
    if (widthDiff < 50 && heightDiff < 50) {
      return;
    }

    // Don't regenerate if cache isn't ready yet
    if (!layerCacheInitialized) {
      AppLogger.warning(
        '📐 Size changed but cache not ready, skipping regeneration',
      );
      lastKnownSize = currentSize;
      return;
    }

    AppLogger.info('📐 Screen size changed: $lastKnownSize → $currentSize');
    lastKnownSize = currentSize;

    // Cancel previous timer if exists
    resizeDebounceTimer?.cancel();

    // Wait 500ms after last resize before regenerating
    resizeDebounceTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted() && layerCacheInitialized && allowRegeneration) {
        regenerateLayersForNewSize(currentSize);
      }
    });
  }

  /// Regenerate layers for a new screen size
  Future<void> regenerateLayersForNewSize(Size newSize) async {
    if (!mounted()) return;

    onIsRegeneratingChanged(true);

    try {
      // CAPTURE context-dependent objects BEFORE async gaps
      final gratitudeProvider = context.read<GratitudeProvider>();
      final currentStars = gratitudeProvider.gratitudeStars;

      // Clear old cache
      await LayerCacheService().clearCache();

      // Regenerate for new size
      await LayerCacheService().initialize(newSize);
      onLayerCacheInitializedChanged(true);

      // Update camera bounds (safe because we captured stars earlier)
      cameraController.updateBounds(currentStars, newSize);

      // Regenerate Van Gogh stars for new size
      final vanGoghStars =
          GratitudeScreenInitializer.generateVanGoghStars(newSize);
      onAllVanGoghStarsChanged(vanGoghStars['all']!);
      onAnimatedVanGoghStarsChanged(vanGoghStars['animated']!);

      AppLogger.success('✅ Layers regenerated for new size: $newSize');
    } catch (e) {
      AppLogger.error('⚠️ Layer regeneration failed: $e');
    } finally {
      if (mounted()) {
        onIsRegeneratingChanged(false);
      }
    }
  }

  /// Cleanup lifecycle resources
  void dispose() {
    resizeDebounceTimer?.cancel();

    // Reset orientation to allow all when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

