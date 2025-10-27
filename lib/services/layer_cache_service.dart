import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../background.dart';
import '../starfield.dart';
import 'crashlytics_service.dart';

/// Service for pre-rendering and caching static visual layers
class LayerCacheService {
  static final LayerCacheService _instance = LayerCacheService._internal();
  factory LayerCacheService() => _instance;
  LayerCacheService._internal();

  // Cached images
  ui.Image? _backgroundImage;
  ui.Image? _vanGoghBaseImage;
  ui.Image? _nebulaBaseImage;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  ui.Image? get backgroundImage => _backgroundImage;
  ui.Image? get vanGoghBaseImage => _vanGoghBaseImage;
  ui.Image? get nebulaBaseImage => _nebulaBaseImage;

  /// Initialize cached layers - call on first launch
  Future<void> initialize(Size screenSize) async {
    if (_initialized) return;

    final crashlytics = CrashlyticsService();
    crashlytics.log('Starting layer cache initialization');

    try {
      // Try to load from cache first
      final loaded = await _loadFromCache(screenSize);

      if (loaded) {
        crashlytics.log('Layers loaded from cache');
        _initialized = true;
        return;
      }

      // Cache doesn't exist or is invalid - generate new
      crashlytics.log('Generating new layer cache');
      await _generateAndCacheLayers(screenSize);

      _initialized = true;
      crashlytics.log('Layer cache initialization complete');
    } catch (e, stack) {
      crashlytics.recordError(e, stack, reason: 'Layer cache initialization failed');
      print('⚠️ Layer cache failed: $e');
      // Don't throw - app can work without cache (just slower)
    }
  }

  /// Generate and cache all static layers
  Future<void> _generateAndCacheLayers(Size screenSize) async {
    final crashlytics = CrashlyticsService();

    // Generate background layer
    crashlytics.log('Generating background layer');
    final staticStars = BackgroundService.generateStaticStars(screenSize);
    _backgroundImage = await _renderBackgroundToImage(staticStars, screenSize);
    crashlytics.log('Background layer generated: ${staticStars.length} stars');

    // Generate Van Gogh base layer (90% of stars static)
    crashlytics.log('Generating Van Gogh base layer');
    final vanGoghStars = VanGoghStarService.generateVanGoghStars(screenSize);
    final staticCount = (vanGoghStars.length * 0.9).round(); // 90% static
    final staticVanGoghStars = vanGoghStars.take(staticCount).toList();
    _vanGoghBaseImage = await _renderVanGoghToImage(staticVanGoghStars, screenSize);
    crashlytics.log('Van Gogh base layer generated: ${staticVanGoghStars.length} static stars');

    // Save to cache
    await _saveToCache(screenSize);
  }

  /// Render background stars to image
  Future<ui.Image> _renderBackgroundToImage(
      List<BackgroundStar> stars,
      Size size,
      ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Paint gradient background (matching original)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        BackgroundConfig.customTopColor,
        BackgroundConfig.customMidTopColor,
        BackgroundConfig.customMidBottomColor,
        BackgroundConfig.customBottomColor,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Paint stars with realistic brightness variation
    paint.shader = null;
    for (final star in stars) {
      // Use the star's brightness for opacity
      paint.color = Colors.white.withValues(alpha: star.brightness);

      // Convert normalized coordinates to screen coordinates
      final screenX = star.x * size.width;
      final screenY = star.y * size.height;

      canvas.drawCircle(
        Offset(screenX, screenY),
        star.size,
        paint,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// Render Van Gogh stars to image
  Future<ui.Image> _renderVanGoghToImage(
      List<VanGoghStar> stars,
      Size size,
      ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint();
    for (final star in stars) {
      // Convert world coordinates to screen coordinates
      final screenX = star.worldX * size.width;
      final screenY = star.worldY * size.height;

      paint.color = star.stellarColor;
      canvas.drawCircle(
        Offset(screenX, screenY),
        star.size,
        paint,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// Save cached images to disk
  Future<void> _saveToCache(Size screenSize) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/layer_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Save screen size for validation
      final sizeFile = File('${cacheDir.path}/screen_size.txt');
      await sizeFile.writeAsString('${screenSize.width}x${screenSize.height}');

      // Save background
      if (_backgroundImage != null) {
        final bgBytes = await _backgroundImage!.toByteData(format: ui.ImageByteFormat.png);
        await File('${cacheDir.path}/background.png').writeAsBytes(
          bgBytes!.buffer.asUint8List(),
        );
      }

      // Save Van Gogh
      if (_vanGoghBaseImage != null) {
        final vgBytes = await _vanGoghBaseImage!.toByteData(format: ui.ImageByteFormat.png);
        await File('${cacheDir.path}/vangogh.png').writeAsBytes(
          vgBytes!.buffer.asUint8List(),
        );
      }

      print('✅ Layers cached to disk');
    } catch (e) {
      print('⚠️ Failed to save layer cache: $e');
    }
  }

  /// Load cached images from disk
  Future<bool> _loadFromCache(Size screenSize) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/layer_cache');

      if (!await cacheDir.exists()) return false;

      // Validate screen size matches
      final sizeFile = File('${cacheDir.path}/screen_size.txt');
      if (!await sizeFile.exists()) return false;

      final cachedSize = await sizeFile.readAsString();
      final currentSize = '${screenSize.width}x${screenSize.height}';
      if (cachedSize != currentSize) {
        print('📐 Screen size changed, regenerating cache');
        return false;
      }

      // Load background
      final bgFile = File('${cacheDir.path}/background.png');
      if (await bgFile.exists()) {
        final bytes = await bgFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        _backgroundImage = frame.image;
      }

      // Load Van Gogh
      final vgFile = File('${cacheDir.path}/vangogh.png');
      if (await vgFile.exists()) {
        final bytes = await vgFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        _vanGoghBaseImage = frame.image;
      }

      return _backgroundImage != null && _vanGoghBaseImage != null && _nebulaBaseImage != null;
    } catch (e) {
      print('⚠️ Failed to load layer cache: $e');
      return false;
    }
  }

  /// Clear cache (for debugging or settings)
  Future<void> clearCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/layer_cache');

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('🗑️ Layer cache cleared');
      }

      _backgroundImage = null;
      _vanGoghBaseImage = null;
      _nebulaBaseImage = null;
      _initialized = false;
    } catch (e) {
      print('⚠️ Failed to clear cache: $e');
    }
  }
}