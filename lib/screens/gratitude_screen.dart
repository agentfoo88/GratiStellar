import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../background.dart';
import '../camera_controller.dart';
import '../core/animation/animation_manager.dart';
import '../core/config/constants.dart';
import '../features/gratitudes/presentation/state/gratitude_provider.dart';
import '../features/gratitudes/presentation/widgets/app_drawer.dart';
import '../features/gratitudes/presentation/widgets/bottom_controls.dart';
import '../features/gratitudes/presentation/widgets/branding_overlay.dart';
import '../features/gratitudes/presentation/widgets/empty_state.dart';
import '../features/gratitudes/presentation/widgets/galaxy_list_dialog.dart';
import '../features/gratitudes/presentation/widgets/loading_state.dart';
import '../features/gratitudes/presentation/widgets/stats_card.dart';
import '../features/gratitudes/presentation/widgets/visual_layers_stack.dart';
import '../font_scaling.dart';
import '../gratitude_stars.dart';
import '../l10n/app_localizations.dart';
import '../list_view_screen.dart';
import '../modal_dialogs.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/daily_reminder_service.dart';
import '../services/feedback_service.dart';
import '../services/layer_cache_service.dart';
import '../services/sync_status_service.dart';
import '../starfield.dart';
import '../storage.dart';
import '../widgets/app_dialog.dart';
import '../widgets/reminder_prompt_bottom_sheet.dart';
import 'sign_in_screen.dart';
import 'trash_screen.dart';
import '../core/utils/app_logger.dart';

class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _gratitudeController = TextEditingController();
  final AuthService _authService = AuthService();
  double _fontScale = 1.0; // User's preferred font scale
  List<Paint> _glowPatterns = [];
  List<Paint> _backgroundGradients = [];
  bool _layerCacheInitialized = false;
  ui.Image? _nebulaAssetImage;
  List<VanGoghStar> _animatedVanGoghStars = []; // The 12 twinkling stars
  List<VanGoghStar> _allVanGoghStars = [];
  // List<OrganicNebulaRegion> _organicNebulaRegions = []; // ADD THIS
  late AnimationManager _animationManager;
  late CameraController _cameraController;
  bool _showBranding = false; // Disabled - using enhanced splash screen instead
  bool _isAppInBackground = false;
  bool _isMultiFingerGesture = false;
  DateTime? _lastScrollTime;
  final String _userName = "A friend";
  Color? _previewColor;
  GratitudeStar? _lastMindfulnessStar;
  Timer? _resizeDebounceTimer;
  Size? _lastKnownSize;
  bool _isRegeneratingLayers = false;
  bool _allowRegeneration = false;

  // Birth animation completion handler (class-level method)
  void _completeBirthAnimation() async {
    final provider = context.read<GratitudeProvider>();

    if (provider.animatingStar != null) {
      HapticFeedback.mediumImpact();

      await provider.completeBirthAnimation();

      if (!mounted) return;

      // Update camera bounds for new star
      _cameraController.updateBounds(provider.gratitudeStars, MediaQuery.of(context).size);

      _animationManager.resetBirthAnimation();

      // Check if we should show reminder prompt
      _checkAndShowReminderPrompt();
    }
  }

  // Check if we should show the reminder prompt
  void _checkAndShowReminderPrompt() async {
    final reminderService = context.read<DailyReminderService>();

    // Don't show if already shown OR if reminder is already enabled
    if (reminderService.hasShownPrompt || reminderService.isEnabled) return;

    // Wait 2 seconds after birth animation completes
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Show bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const ReminderPromptBottomSheet(),
    );
  }

  Future<void> _regenerateLayersForNewSize(Size newSize) async {
    setState(() {
      _isRegeneratingLayers = true;
    });

    AppLogger.info('🔄 Regenerating layers for size: $newSize');

    try {
      // CAPTURE context-dependent objects BEFORE async gaps
      final gratitudeProvider = context.read<GratitudeProvider>();
      final currentStars = gratitudeProvider.gratitudeStars;

      // Clear old cache
      await LayerCacheService().clearCache();

      // Regenerate for new size
      await LayerCacheService().initialize(newSize);

      // Update camera bounds (safe because we captured stars earlier)
      _cameraController.updateBounds(currentStars, newSize);

      // Regenerate Van Gogh stars for new size
      _allVanGoghStars = VanGoghStarService.generateVanGoghStars(newSize);
      _animatedVanGoghStars = _allVanGoghStars
          .skip((_allVanGoghStars.length * 0.9).round())
          .toList();

      AppLogger.success('✅ Layers regenerated successfully');

    } catch (e) {
      AppLogger.error('⚠️ Layer regeneration failed: $e');

    } finally {
      if (mounted) {
        setState(() {
          _isRegeneratingLayers = false;
          _layerCacheInitialized = true;
        });
      }
    }
  }

  @override
  void initState() {
    AppLogger.start('🎬 GratitudeScreen initState starting...');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = CameraController();

    // Initialize AnimationManager synchronously to avoid race condition
    // where build() tries to access _starController before initialization completes
    _animationManager = AnimationManager();
    _animationManager.initialize(this, _completeBirthAnimation, reduceMotion: false);

    // Generate static universe based on full screen size
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenSize = view.physicalSize / view.devicePixelRatio;

    // Log screen size for crash reports
    final crashlytics = CrashlyticsService();
    crashlytics.setCustomKey('screen_width', screenSize.width.round());
    crashlytics.setCustomKey('screen_height', screenSize.height.round());

    // Initialize layer cache (async - happens in background)
    _initializeLayerCache(screenSize);

    // Load nebula asset image
    _loadNebulaAsset();

    // Generate all Van Gogh stars - needed for camera bounds calculation
    _allVanGoghStars = VanGoghStarService.generateVanGoghStars(screenSize);
    final staticCount = (_allVanGoghStars.length * 0.9).round(); // 90% static
    _animatedVanGoghStars = _allVanGoghStars.skip(staticCount).toList(); // Last 10% animate

    AppLogger.info('📐 Screen: ${screenSize.width.round()}x${screenSize.height.round()}');
    AppLogger.info('   🎨 Using cached layers (background, $staticCount Van Gogh stars)');
    AppLogger.info('   ✨ Animating: ${_animatedVanGoghStars.length} Van Gogh stars');
    AppLogger.info('   📍 Camera bounds: ${_allVanGoghStars.length} Van Gogh stars (for reference only)');

    try {
      _initializePrecomputedElements();
      AppLogger.success('✅ Precomputed elements initialized');
    } catch (e) {
      AppLogger.error('❌ Error in initialization: $e');
    }

    _loadFontScale();
    _startSplashTimer();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Don't use MediaQuery during build - get size from window
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final currentSize = view.physicalSize / view.devicePixelRatio;

    // First time seeing the size - just store it, don't regenerate
    if (_lastKnownSize == null) {
      _lastKnownSize = currentSize;
      AppLogger.start('📐 Initial screen size detected: $currentSize');

      // Allow regeneration after 3 seconds (after splash/initialization)
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          _allowRegeneration = true;
          AppLogger.success('✅ Regeneration now allowed');
        }
      });
      return;
    }

    // Don't regenerate if not allowed yet (still initializing)
    if (!_allowRegeneration) {
      AppLogger.start('📐 Size changed but regeneration blocked (still initializing)');
      _lastKnownSize = currentSize;
      return;
    }

    // Check if size actually changed significantly (avoid pixel-level jitter)
    final widthDiff = (currentSize.width - _lastKnownSize!.width).abs();
    final heightDiff = (currentSize.height - _lastKnownSize!.height).abs();

    // Only regenerate if change is >50 pixels (avoid noise)
    if (widthDiff < 50 && heightDiff < 50) {
      return;
    }

    // Don't regenerate if cache isn't ready yet
    if (!_layerCacheInitialized) {
      AppLogger.warning('📐 Size changed but cache not ready, skipping regeneration');
      _lastKnownSize = currentSize;
      return;
    }

    AppLogger.info('📐 Screen size changed: $_lastKnownSize → $currentSize');
    _lastKnownSize = currentSize;

    // Cancel previous timer if exists
    _resizeDebounceTimer?.cancel();

    // Wait 500ms after last resize before regenerating
    _resizeDebounceTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted && _layerCacheInitialized && _allowRegeneration) {
        _regenerateLayersForNewSize(currentSize);
      }
    });
  }

  Future<void> _loadFontScale() async {
    final scale = await StorageService.getFontScale();
    if (mounted) {
      setState(() {
        _fontScale = scale;
      });
    }
  }

  Future<void> _loadNebulaAsset() async {
    try {
      final ByteData data = await rootBundle.load('assets/textures/background-01.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _nebulaAssetImage = frameInfo.image;
        });
      }
      AppLogger.success('✅ Nebula asset loaded');
    } catch (e) {
      AppLogger.error('⚠️ Failed to load nebula asset: $e');
    }
  }

  void _initializePrecomputedElements() {
    AppLogger.start('🌟 Starting initialization...');

    _glowPatterns = GratitudeStarService.generateGlowPatterns();
    AppLogger.info('✨ Generated ${_glowPatterns.length} glow patterns');

    _backgroundGradients = BackgroundService.generateBackgroundGradients();
    AppLogger.info('🎨 Generated ${_backgroundGradients.length} background gradients');
  }

  Future<void> _initializeLayerCache(Size screenSize) async {
    final crashlytics = CrashlyticsService();

    try {
      crashlytics.log('Initializing layer cache');
      await LayerCacheService().initialize(screenSize);

      if (mounted) {
        setState(() {
          _layerCacheInitialized = true;
        });
      }

      crashlytics.log('Layer cache ready');
      AppLogger.success('✅ Layer cache initialized');
    } catch (e, stack) {
      crashlytics.recordError(e, stack, reason: 'Layer cache initialization failed');
      AppLogger.error('⚠️ Layer cache failed: $e');
      // App continues without cache (will be slower but still works)
    }
  }

  void _startSplashTimer() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _showBranding) {
        setState(() {
          _showBranding = false;
        });
      }
    });
  }

  void _skipSplash() {
    if (_showBranding) {
      setState(() {
        _showBranding = false;
      });
    }
  }

  Future<void> _loadGratitudes() async {
    final provider = context.read<GratitudeProvider>();
    await provider.loadGratitudes();
    // Provider notifies listeners, UI updates automatically
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resizeDebounceTimer?.cancel();
    _cameraController.dispose();
    _animationManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      // App going to background
        if (!_isAppInBackground) {
          _isAppInBackground = true;
          _animationManager.pauseAll();
          
          // CRITICAL: Force immediate sync when app goes to background
          // This prevents data loss if app is killed by system
          final provider = context.read<GratitudeProvider>();
          if (provider.hasPendingChanges && _authService.hasEmailAccount) {
            AppLogger.sync('📤 App backgrounding - forcing immediate sync');
            provider.forceSync().catchError((e) {
              AppLogger.sync('⚠️ Background sync failed: $e');
            });
          }
        }
        break;

      case AppLifecycleState.resumed:
      // App coming back to foreground
        if (_isAppInBackground) {
          _isAppInBackground = false;
          _animationManager.resumeAll();

          // Reload gratitudes when app resumes (Provider handles sync)
          if (_authService.hasEmailAccount) {
            _loadGratitudes();
          }
        }
        break;

      case AppLifecycleState.hidden:
      // Do nothing for now
        break;
    }
  }

  void _addGratitude([int? colorIndex, Color? customColor]) async {
    final provider = context.read<GratitudeProvider>();

    // Cancel modes via provider
    provider.cancelModes();

    final trimmedText = _gratitudeController.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    if (trimmedText.isEmpty) return;

    final screenSize = MediaQuery.of(context).size;

    // Create star via provider - pass optional color parameters
    final newStar = await provider.createGratitude(
      trimmedText,
      screenSize,
      colorPresetIndex: colorIndex,
      customColor: customColor,
    );

    if (!mounted) return;

    _gratitudeController.clear();

    // Start animation via provider
    provider.startBirthAnimation(newStar);

    // Calculate camera position so star appears at 40% from top
    // (prevents text input modal from obscuring the star)
    final starWorldX = newStar.worldX * screenSize.width;
    final starWorldY = newStar.worldY * screenSize.height;

    final targetPosition = Offset(
      screenSize.width / 2 - starWorldX * _cameraController.scale,
      screenSize.height * 0.4 - starWorldY * _cameraController.scale, // 40% from top
    );

    _cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: _cameraController.scale, // Keep current scale
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      vsync: this,
      context: context,
    );
    await Future.delayed(Duration(milliseconds: 400));

    final startScreen = Offset(screenSize.width / 2, screenSize.height);
    final endWorld = Offset(newStar.worldX * screenSize.width, newStar.worldY * screenSize.height);
    final endScreen = _cameraController.worldToScreen(endWorld);

    final distance = (endScreen - startScreen).distance;
    final duration = (distance / StarBirthConfig.travelBaseSpeed * 1000)
        .clamp(StarBirthConfig.travelDurationMin.toDouble(),
        StarBirthConfig.travelDurationMax.toDouble())
        .toInt();

    _animationManager.startBirthAnimation(Duration(milliseconds: duration));
  }

  /// Shows the edit dialog for a star (delegates to modal_dialogs.dart)
  void _showStarDetails(
      GratitudeStar star, {
        VoidCallback? onJumpToStar,
        VoidCallback? onAfterSave,
        VoidCallback? onAfterDelete,
      }) {
    final provider = context.read<GratitudeProvider>();

    GratitudeDialogs.showEditStar(
      context: context,
      star: star,
      allStars: provider.gratitudeStars,
      onSave: _saveStarEdits,
      onDelete: _deleteStar,
      onShare: _shareStar,
      onJumpToStar: onJumpToStar,
      onAfterSave: onAfterSave,
      onAfterDelete: onAfterDelete,
    );
  }

  void _shareStar(GratitudeStar star) {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final shareText = l10n.shareTemplate(_userName, star.text);
    SharePlus.instance.share(
        ShareParams(text: shareText)
    );
  }

  void _saveStarEdits(GratitudeStar updatedStar) async {
    HapticFeedback.mediumImpact();
    await context.read<GratitudeProvider>().updateGratitude(updatedStar);
  }

  void _deleteStar(GratitudeStar star) async {
    HapticFeedback.heavyImpact();

    final provider = context.read<GratitudeProvider>();
    await provider.deleteGratitude(star);
  }

  void _handleStarTap(TapDownDetails details) {
    final provider = context.read<GratitudeProvider>();
    final screenSize = MediaQuery.of(context).size;

    final tappedStar = StarHitTester.findStarAtScreenPosition(
      details.localPosition,
      provider.gratitudeStars,
      screenSize,
      cameraPosition: _cameraController.position,
      cameraScale: _cameraController.scale,
    );

    if (tappedStar != null) {
      HapticFeedback.lightImpact();
      _showStarDetails(tappedStar);
    }
  }

  Future<void> _navigateToMindfulnessStar(GratitudeStar star) async {
    const double mindfulnessZoom = 2.0;  // Define target zoom as constant

    final screenSize = MediaQuery.of(context).size;

    // Calculate world position in pixels
    final starWorldX = star.worldX * screenSize.width;
    final starWorldY = star.worldY * screenSize.height;
    final starWorldPos = Offset(starWorldX, starWorldY);

    AppLogger.info('🧘 Navigating to mindfulness star at world: ($starWorldX, $starWorldY)');

    // Calculate where we want the star to appear on screen (40% from top, centered horizontally)
    final desiredScreenPos = Offset(
      screenSize.width / 2,
      screenSize.height * 0.4, // 40% from top
    );

    // Calculate the camera position needed to place the star at desiredScreenPos
    // At target zoom level (mindfulnessZoom), the camera position should be:
    // cameraPos = desiredScreenPos - (starWorldPos * targetZoom)
    final targetPosition = Offset(
      desiredScreenPos.dx - starWorldPos.dx * mindfulnessZoom,
      desiredScreenPos.dy - starWorldPos.dy * mindfulnessZoom,
    );

    // Safety check: ensure target position is reasonable (not NaN or infinite)
    if (!targetPosition.dx.isFinite || !targetPosition.dy.isFinite) {
      AppLogger.error('⚠️ Invalid target position calculated: $targetPosition');
      // Fallback: use simpler calculation
      final fallbackPosition = Offset(
        screenSize.width / 2 - starWorldX * mindfulnessZoom,
        screenSize.height * 0.4 - starWorldY * mindfulnessZoom,
      );
      if (fallbackPosition.dx.isFinite && fallbackPosition.dy.isFinite) {
        _cameraController.animateTo(
          targetPosition: fallbackPosition,
          targetScale: mindfulnessZoom,
          duration: Duration(milliseconds: 2000),
          curve: Curves.easeInOutCubic,
          vsync: this,
          context: context,
        );
      }
      return;
    }
    _cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: mindfulnessZoom,  // Use same constant for consistency
      duration: Duration(milliseconds: 2000), // 2 seconds - slow and graceful
      curve: Curves.easeInOutCubic,
      vsync: this,
      context: context,
    );
  }

  // Toggle methods
  void _toggleShowAll() {
    context.read<GratitudeProvider>().toggleShowAll();
  }

  void _toggleMindfulness() {
    final provider = context.read<GratitudeProvider>();

    // Check if there are stars before toggling
    if (provider.gratitudeStars.isEmpty && !provider.mindfulnessMode) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mindfulnessNoStarsMessage, style: FontScaling.getBodyMedium(context)),
          backgroundColor: Color(0xFF1A2238),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    provider.toggleMindfulness();
  }

  void _onMindfulnessIntervalChanged(double value) {
    context.read<GratitudeProvider>().setMindfulnessInterval(value.round());
  }

  void _jumpToStar(GratitudeStar star) {
    final screenSize = MediaQuery.of(context).size;

    // Convert star's normalized world coordinates to pixels
    final starWorldX = star.worldX * screenSize.width;
    final starWorldY = star.worldY * screenSize.height;

    // Calculate camera position to center the star at the new scale
    final targetPosition = Offset(
      screenSize.width / 2 - starWorldX * CameraConstants.jumpToStarZoom,
      screenSize.height / 2 - starWorldY * CameraConstants.jumpToStarZoom,
    );

    _cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: CameraConstants.jumpToStarZoom,
      duration: Duration(milliseconds: 1500),
      curve: Curves.easeInOutCubic,
      vsync: this,
      context: context,
    );
  }

  void _showStarDetailsFromList(GratitudeStar star) {
    _showStarDetails(
      star,
      onJumpToStar: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _jumpToStar(star);
      },
      // No need for onAfterSave/onAfterDelete callbacks
      // Provider.notifyListeners() will auto-update the Consumer
    );
  }

  void _showAddGratitudeModal() {
    final provider = context.read<GratitudeProvider>();

    GratitudeDialogs.showAddGratitude(
      context: context,
      controller: _gratitudeController,
      onAdd: _addGratitude,
      isAnimating: provider.isAnimating,
    );
  }

  void _navigateToListView() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListViewScreen(
          onStarTap: _showStarDetailsFromList,
          onJumpToStar: (star) {},
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator(SyncStatusService syncStatus) {
    // Hide when fully synced
    if (syncStatus.status == SyncStatus.synced) {
      return SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String tooltip;

    switch (syncStatus.status) {
      case SyncStatus.synced:
        return SizedBox.shrink();
      case SyncStatus.pending:
        icon = Icons.cloud_upload_outlined;
        color = Colors.orange;
        tooltip = 'Changes pending sync';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = 'Syncing...';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_outlined;
        color = Colors.grey;
        tooltip = 'Offline - will sync when connected';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_sync_outlined;
        color = Colors.red;
        tooltip = 'Sync failed - tap to retry';
        break;
    }

    return Semantics(
      label: tooltip,
      button: syncStatus.status == SyncStatus.error,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: syncStatus.status == SyncStatus.syncing
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
              : Icon(icon, color: color, size: 20),
          tooltip: tooltip,
          onPressed: syncStatus.status == SyncStatus.error
              ? () {
            final provider = context.read<GratitudeProvider>();
            provider.forceSync();
          }
              : null,
        ),
      ),
    );
  }

  void _showGalaxiesDialog() {
    showDialog(
      context: context,
      builder: (context) => const GalaxyListDialog(),
    );
  }

  void _showSignOutConfirmation() {
    final l10n = AppLocalizations.of(context)!;

    AppDialog.showConfirmation(
      context: context,
      title: l10n.signOutTitle,
      message: l10n.signOutMessage,
      icon: Icons.logout,
      iconColor: Colors.red.withValues(alpha: 0.8),
      confirmText: l10n.signOutButton,
      cancelText: l10n.cancelButton,
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        await _authService.signOut();
      }
    });
  }

  void _showAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    final displayNameController = TextEditingController(
      text: _authService.currentUser?.displayName ?? l10n.defaultUserName,
    );

    AppDialog.show(
      context: context,
      title: l10n.accountTitle,
      icon: Icons.account_circle,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account Name and Icon
              Container(
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Avatar placeholder (for future)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFFFE135).withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFFFE135),
                      ),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                    // Display name field
                    TextField(
                      controller: displayNameController,
                      textCapitalization: TextCapitalization.sentences,
                      style: FontScaling.getInputText(context),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: l10n.displayNameLabel,
                        labelStyle: FontScaling.getBodySmall(context),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                    // Update button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = displayNameController.text.trim();
                          if (newName.isNotEmpty && newName != _authService.currentUser?.displayName) {
                            await _authService.updateDisplayName(newName);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          l10n.displayNameUpdated,
                                          style: FontScaling.getBodySmall(context).copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF4CAF50),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: EdgeInsets.all(16),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              // Refresh the UI
                              setState(() {});
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFE135),
                          padding: EdgeInsets.symmetric(
                            vertical: FontScaling.getResponsiveSpacing(context, 12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          l10n.updateButton,
                          style: FontScaling.getButtonText(context).copyWith(
                            color: Color(0xFF1A2238),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

              // Email (read-only)
              Container(
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 12)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Color(0xFFFFE135),
                      size: FontScaling.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _authService.currentUser?.email ?? '',
                        style: FontScaling.getBodySmall(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Show "Sign in with Email" for anonymous users
        if (!_authService.hasEmailAccount)
          AppDialogAction(
            text: l10n.signInWithEmailMenuItem,
            onPressed: () {
              Navigator.pop(context); // Close account dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignInScreen(),
                ),
              );
            },
          ),
        // Show "Sign Out" for email users
        if (_authService.hasEmailAccount)
          AppDialogAction(
            text: l10n.signOutButton,
            isDestructive: true,
            onPressed: () {
              Navigator.pop(context); // Close account dialog
              _showSignOutConfirmation();
            },
          ),
        AppDialogAction(
          text: l10n.closeButton,
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _handleAccountTap() {
    Navigator.pop(context); // Close drawer
    // Show account dialog for both anonymous and email users
    _showAccountDialog();
  }

  void _showFeedbackDialog() {
    final l10n = AppLocalizations.of(context)!;
    String selectedType = 'bug';
    String message = '';
    String contactEmail = '';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: Color(0xFF1A2238).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color(0xFFFFE135).withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      l10n.feedbackDialogTitle,
                      style: FontScaling.getModalTitle(context).copyWith(
                        color: Color(0xFFFFE135),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 20)),

                    // Type dropdown
                    Text(
                      l10n.feedbackTypeLabel,
                      style: FontScaling.getBodyMedium(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      dropdownColor: Color(0xFF1A2238),
                      style: FontScaling.getInputText(context),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135),
                            width: 2,
                          ),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'bug',
                          child: Text(
                            l10n.feedbackTypeBug,
                            style: FontScaling.getBodyMedium(context),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'feature',
                          child: Text(
                            l10n.feedbackTypeFeature,
                            style: FontScaling.getBodyMedium(context),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'general',
                          child: Text(
                            l10n.feedbackTypeGeneral,
                            style: FontScaling.getBodyMedium(context),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedType = value!);
                      },
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                    // Message field
                    Text(
                      l10n.feedbackMessageLabel,
                      style: FontScaling.getBodyMedium(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      style: FontScaling.getInputText(context),
                      decoration: InputDecoration(
                        hintText: l10n.feedbackMessageHint,
                        hintStyle: FontScaling.getInputText(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFFFE135),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        counterStyle: FontScaling.getCaption(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      maxLines: 5,
                      maxLength: 1000,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.feedbackMessageRequired;
                        }
                        return null;
                      },
                      onChanged: (value) => message = value,
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                    // Optional email (only show if anonymous)
                    if (_authService.currentUser?.isAnonymous ?? false) ...[
                      Text(
                        l10n.feedbackEmailLabel,
                        style: FontScaling.getBodyMedium(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 8)),
                      TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        style: FontScaling.getInputText(context),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: l10n.feedbackEmailHint,
                          hintStyle: FontScaling.getInputText(context).copyWith(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFFFE135).withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFFFE135).withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFFFE135),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return l10n.feedbackEmailInvalid;
                            }
                          }
                          return null;
                        },
                        onChanged: (value) => contactEmail = value,
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                    ],

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancelButton,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);

                              final feedbackService = FeedbackService();
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final textStyle = FontScaling.getBodyMedium(context);

                              final success = await feedbackService.submitFeedback(
                                type: selectedType,
                                message: message,
                                contactEmail: contactEmail.isNotEmpty ? contactEmail : null,
                              );

                              if (mounted) {
                                scaffoldMessenger.showSnackBar(  // ← Use captured reference
                                  SnackBar(
                                    content: Text(
                                        success ? l10n.feedbackSuccess : l10n.feedbackError,
                                        style: textStyle,
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFFE135),
                            foregroundColor: Color(0xFF1A2238),
                            padding: EdgeInsets.symmetric(
                              horizontal: FontScaling.getResponsiveSpacing(context, 24),
                              vertical: FontScaling.getResponsiveSpacing(context, 12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            l10n.feedbackSubmit,
                            style: FontScaling.getButtonText(context).copyWith(
                              color: Color(0xFF1A2238),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GratitudeProvider>();
    final l10n = AppLocalizations.of(context)!;

    // Get all state from provider
    final gratitudeStars = provider.gratitudeStars;
    final isLoading = provider.isLoading;
    final showAllGratitudes = provider.showAllGratitudes;
    final mindfulnessMode = provider.mindfulnessMode;
    final isAnimating = provider.isAnimating;
    final animatingStar = provider.animatingStar;
    final activeMindfulnessStar = provider.activeMindfulnessStar;
    final mindfulnessInterval = provider.mindfulnessInterval;

    AppLogger.data('🏗️ Building GratitudeScreen, isLoading: $isLoading, stars: ${gratitudeStars.length}');

    // Navigate to mindfulness star when it changes (with deduplication)
    if (mindfulnessMode && activeMindfulnessStar != null) {
      // Only navigate if star changed
      if (_lastMindfulnessStar?.id != activeMindfulnessStar.id) {
        _lastMindfulnessStar = activeMindfulnessStar;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToMindfulnessStar(activeMindfulnessStar);
          }
        });
      }
    }

    // Update camera bounds when stars change
    if (!isLoading && gratitudeStars.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _cameraController.updateBounds(gratitudeStars, MediaQuery.of(context).size);
        }
      });
    }

    final currentSize = MediaQuery.of(context).size;

    if (isLoading) {
      return LoadingStateWidget(previewColor: _previewColor);
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawerWidget(
          authService: _authService,
          onAccountTap: _handleAccountTap,
          onListViewTap: () {
            Navigator.pop(context);
            _navigateToListView();
          },
          onGalaxiesTap: () {
            Navigator.pop(context);
            _showGalaxiesDialog();
          },
          onFeedbackTap: () {
            Navigator.pop(context);
            _showFeedbackDialog();
          },
          onTrashTap: () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TrashScreen()),
            );
          },
          onExitTap: () {
            Navigator.pop(context);
            GratitudeDialogs.showQuitConfirmation(context);
          },
          onFontScaleChanged: _loadFontScale,
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // All visual rendering layers
              VisualLayersStack(
                layerCacheInitialized: _layerCacheInitialized,
                nebulaAssetImage: _nebulaAssetImage,
                animatedVanGoghStars: _animatedVanGoghStars,
                gratitudeStars: gratitudeStars,
                showAllGratitudes: showAllGratitudes,
                mindfulnessMode: mindfulnessMode,
                activeMindfulnessStar: activeMindfulnessStar,
                isAnimating: isAnimating,
                animatingStar: animatingStar,
                glowPatterns: _glowPatterns,
                cameraController: _cameraController,
                animationManager: _animationManager,
                currentSize: currentSize,
              ),

              // Gesture detection for pan/zoom/tap
              Positioned.fill(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final provider = context.read<GratitudeProvider>();
                      if (provider.mindfulnessMode) {
                        provider.stopMindfulness();
                      }

                      final now = DateTime.now();
                      if (_lastScrollTime != null && now.difference(_lastScrollTime!).inMilliseconds < 16) {
                        return;
                      }
                      _lastScrollTime = now;

                      final scrollEvent = pointerSignal;
                      final delta = scrollEvent.scrollDelta.dy;
                      final screenSize = MediaQuery.of(context).size;
                      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

                      if (delta > 0) {
                        _cameraController.zoomOut(1.1, screenCenter);
                      } else {
                        _cameraController.zoomIn(1.1, screenCenter);
                      }
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onScaleStart: isAnimating ? null : (details) {
                      final provider = context.read<GratitudeProvider>();
                      if (provider.mindfulnessMode) {
                        provider.stopMindfulness();
                      }
                      _isMultiFingerGesture = details.pointerCount > 1;
                    },
                    onScaleUpdate: isAnimating ? null : (details) {
                      final provider = context.read<GratitudeProvider>();
                      if (provider.mindfulnessMode) {
                        provider.stopMindfulness();
                      }

                      if (details.scale != 1.0) {
                        final scaleChange = (details.scale - 1.0).abs();
                        if (scaleChange > 0.01) {
                          final dampingFactor = 0.025;
                          final dampenedScale = 1.0 + ((details.scale - 1.0) * dampingFactor);
                          final newScale = _cameraController.scale * dampenedScale;
                          _cameraController.updateScale(newScale, details.focalPoint);
                        }
                      }

                      if (details.scale == 1.0) {
                        _cameraController.updatePosition(details.focalPointDelta);
                      }
                    },
                    onScaleEnd: isAnimating ? null : (details) {
                      _isMultiFingerGesture = false;
                    },
                    onTapDown: isAnimating ? null : (details) {
                      if (!_isMultiFingerGesture) {
                        _handleStarTap(details);
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              // Branding overlay
              if (_showBranding)
                BrandingOverlayWidget(onSkip: _skipSplash),

              // Stats card
              if (!_showBranding)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: StatsCardWidget(stars: gratitudeStars),
                  ),
                ),

              // Hamburger menu button (top-left)
              if (!_showBranding)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: HamburgerButton(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),

              // Sync status indicator (top-right)
              if (!_showBranding)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: Consumer<SyncStatusService>(
                    builder: (context, syncStatus, child) {
                      return _buildSyncStatusIndicator(syncStatus);
                    },
                  ),
                ),

              // Bottom button row with slider integrated
              if (!_showBranding)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: BottomControlsWidget(
                      showAllGratitudes: showAllGratitudes,
                      mindfulnessMode: mindfulnessMode,
                      isAnimating: isAnimating,
                      mindfulnessInterval: mindfulnessInterval,
                      onToggleShowAll: _toggleShowAll,
                      onToggleMindfulness: _toggleMindfulness,
                      onAddStar: _showAddGratitudeModal,
                      onMindfulnessIntervalChanged: _onMindfulnessIntervalChanged,
                    ),
                  ),
                ),

              // Empty state message
              if (!_showBranding && gratitudeStars.isEmpty)
                EmptyStateWidget(),

              // Camera controls overlay1
              if (!_showBranding)
                CameraControlsOverlay(
                  cameraController: _cameraController,
                  stars: gratitudeStars,
                  screenSize: MediaQuery.of(context).size,
                  vsync: this,
                  safeAreaPadding: MediaQuery.of(context).padding,
                ),
              // Regeneration overlay
              if (_isRegeneratingLayers)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFE135)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            l10n.adjustingStarFieldMessage,
                            style: FontScaling.getBodyMedium(context).copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}