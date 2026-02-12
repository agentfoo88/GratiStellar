import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../camera_controller.dart';
import '../core/animation/animation_manager.dart';
import '../core/theme/app_theme.dart';
import '../features/gratitudes/presentation/widgets/camera_controls_overlay.dart';
import '../features/gratitudes/presentation/state/gratitude_provider.dart';
import '../features/gratitudes/presentation/widgets/account_dialog.dart';
import '../features/gratitudes/presentation/widgets/app_drawer.dart';
import '../features/gratitudes/presentation/widgets/bottom_controls.dart';
import '../features/gratitudes/presentation/widgets/branding_overlay.dart';
import '../features/gratitudes/presentation/widgets/empty_state.dart';
import '../features/gratitudes/presentation/widgets/feedback_dialog.dart';
import '../features/gratitudes/presentation/widgets/galaxy_list_dialog.dart';
import '../features/gratitudes/presentation/controllers/camera_navigation_controller.dart';
import '../features/gratitudes/presentation/controllers/gratitude_screen_initializer.dart';
import '../features/gratitudes/presentation/controllers/reminder_controller.dart';
import '../features/gratitudes/presentation/widgets/gratitude_gesture_handler.dart';
import '../features/gratitudes/presentation/widgets/loading_state.dart';
import '../features/gratitudes/presentation/widgets/stats_card.dart';
import '../features/gratitudes/presentation/widgets/sync_status_banner.dart';
import '../features/gratitudes/presentation/widgets/sign_in_prompt_banner.dart';
import '../features/gratitudes/presentation/widgets/season_drawer.dart';
import '../features/gratitudes/presentation/widgets/visual_layers_stack.dart';
import '../font_scaling.dart';
import '../gratitude_stars.dart';
import '../l10n/app_localizations.dart';
import '../list_view_screen.dart';
import '../modal_dialogs.dart';
import '../services/auth_service.dart';
import '../services/daily_reminder_service.dart';
import '../services/in_app_review_service.dart';
import '../services/layer_cache_service.dart';
import '../services/sound_service.dart';
import '../services/sync_status_service.dart';
import '../services/tutorial_service.dart';
import '../starfield.dart';
import '../storage.dart';
import 'trash_screen.dart';
import '../core/utils/app_logger.dart';
import '../features/gratitudes/presentation/widgets/tutorial_tooltip.dart';
import '../core/accessibility/motion_helper.dart';
import '../features/whats_new/presentation/services/whats_new_service.dart';
import '../features/whats_new/presentation/widgets/whats_new_bottom_sheet.dart';

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
  bool _layerCacheInitialized = false;
  ui.Image? _nebulaAssetImage;
  List<VanGoghStar> _animatedVanGoghStars = []; // The 12 twinkling stars
  List<VanGoghStar> _allVanGoghStars = [];
  late AnimationManager _animationManager;
  late CameraController _cameraController;
  bool _showBranding = false;
  bool _isAppInBackground = false;
  Color? _previewColor;
  GratitudeStar? _lastMindfulnessStar;
  Timer? _resizeDebounceTimer;
  Size? _lastKnownSize;
  bool _isRegeneratingLayers = false;
  bool _allowRegeneration = false;
  bool _hasCheckedStarButtonTutorial = false;
  bool _hasCheckedWhatsNew = false;

  // Birth animation completion handler (class-level method)
  void _completeBirthAnimation() async {
    final provider = context.read<GratitudeProvider>();

    if (provider.animatingStar != null) {
      HapticFeedback.mediumImpact();

      // Capture context-dependent values before async gap
      final reminderService = context.read<DailyReminderService>();
      final tutorialService = context.read<TutorialService>();
      final screenSize = MediaQuery.of(context).size;

      await provider.completeBirthAnimation();

      if (!mounted) return;

      // Reschedule reminder for tomorrow (prevents reminder from firing today)
      await reminderService.rescheduleForTomorrow();

      if (!mounted) return;

      // Update camera bounds for new star
      _cameraController.updateBounds(
        provider.gratitudeStars,
        screenSize,
      );

      _animationManager.resetBirthAnimation();

      // Check if we should show reminder prompt
      _checkAndShowReminderPrompt();

      // Check if we should show mindfulness tutorial (after 3 stars)
      tutorialService.checkMindfulnessTutorial(provider.gratitudeStars.length);
    }
  }

  // Check if we should show the reminder prompt
  void _checkAndShowReminderPrompt() async {
    final reminderController = ReminderController(
      context: context,
      mounted: () => mounted,
    );
    await reminderController.checkAndShowReminderPrompt();
  }

  // Check if we should show the star button tutorial
  void _checkAndShowStarButtonTutorial(int starCount) {
    if (starCount == 0) {
      final tutorialService = context.read<TutorialService>();
      final reduceMotion = MotionHelper.shouldReduceMotion(context);
      tutorialService.checkAndShowStarButtonTutorial(reduceMotion: reduceMotion);
    }
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
    _cameraController.setVsync(this); // Enable animation-based zoom

    // Initialize AnimationManager synchronously to avoid race condition
    // where build() tries to access _starController before initialization completes
    _animationManager = AnimationManager();
    _animationManager.initialize(
      this,
      _completeBirthAnimation,
      reduceMotion: false,
    );

    // Generate static universe based on full screen size
    final screenSize = GratitudeScreenInitializer.getInitialScreenSize();

    // Lock to portrait mode on small screens (tablets and desktops can rotate)
    GratitudeScreenInitializer.setOrientationForScreenSize(screenSize);

    // Log screen size for crash reports
    GratitudeScreenInitializer.setCrashlyticsScreenKeys(screenSize);

    // Initialize layer cache (async - happens in background)
    GratitudeScreenInitializer.initializeLayerCache(screenSize).then((success) {
      if (mounted) {
        setState(() {
          _layerCacheInitialized = success;
        });
      }
    });

    // Load nebula asset image
    GratitudeScreenInitializer.loadNebulaAsset().then((image) {
      if (mounted && image != null) {
        setState(() {
          _nebulaAssetImage = image;
        });
      }
    });

    // Generate all Van Gogh stars - needed for camera bounds calculation
    final vanGoghStars =
        GratitudeScreenInitializer.generateVanGoghStars(screenSize);
    _allVanGoghStars = vanGoghStars['all']!;
    _animatedVanGoghStars = vanGoghStars['animated']!;

    try {
      final precomputed =
          GratitudeScreenInitializer.initializePrecomputedElements();
      _glowPatterns = precomputed['glowPatterns'];
      // Background gradients are generated but not currently used
      AppLogger.success('✅ Precomputed elements initialized');
    } catch (e) {
      AppLogger.error('❌ Error in initialization: $e');
    }

    _loadFontScale();
    _startSplashTimer();

    // Consider asking for a store review after user has used the app (delayed so not on first paint)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        InAppReviewService.instance.maybeRequestReview();
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Don't use MediaQuery during build - get size from window
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final currentSize = view.physicalSize / view.devicePixelRatio;

    // Update orientation lock based on new screen size
    GratitudeScreenInitializer.setOrientationForScreenSize(currentSize);

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
      AppLogger.start(
        '📐 Size changed but regeneration blocked (still initializing)',
      );
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
      AppLogger.warning(
        '📐 Size changed but cache not ready, skipping regeneration',
      );
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

    // Reset orientation to allow all when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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

  void _addGratitude([int? colorIndex, Color? customColor, String? inspirationPrompt]) async {
    final provider = context.read<GratitudeProvider>();

    // Cancel modes via provider
    provider.cancelModes();

    final trimmedText = _gratitudeController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (trimmedText.isEmpty) return;

    final screenSize = MediaQuery.of(context).size;

    // Create star via provider - pass optional color parameters and inspiration prompt
    final newStar = await provider.createGratitude(
      trimmedText,
      screenSize,
      colorPresetIndex: colorIndex,
      customColor: customColor,
      inspirationPrompt: inspirationPrompt,
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
      screenSize.height * 0.4 -
          starWorldY * _cameraController.scale, // 40% from top
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
    final endWorld = Offset(
      newStar.worldX * screenSize.width,
      newStar.worldY * screenSize.height,
    );
    final endScreen = _cameraController.worldToScreen(endWorld);

    final distance = (endScreen - startScreen).distance;
    final duration = (distance / StarBirthConfig.travelBaseSpeed * 1000)
        .clamp(
          StarBirthConfig.travelDurationMin.toDouble(),
          StarBirthConfig.travelDurationMax.toDouble(),
        )
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
    // Use user's display name if available, otherwise fallback to localized default
    final userName =
        _authService.currentUser?.displayName ?? l10n.defaultUserNameFallback;
    final shareText = l10n.shareTemplate(userName, star.text);
    SharePlus.instance.share(ShareParams(text: shareText));
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
    // Play chime when navigating to new mindfulness star
    context.read<SoundService>().playChime();

    final navigationController = CameraNavigationController(
      cameraController: _cameraController,
      vsync: this,
      context: context,
    );
    await navigationController.navigateToMindfulnessStar(star);
  }

  // Toggle methods
  void _toggleShowAll() {
    context.read<GratitudeProvider>().toggleShowAll();
  }

  void _toggleMindfulness() {
    final provider = context.read<GratitudeProvider>();

    // Dismiss mindfulness tutorial when user taps the mindfulness button
    final tutorialService = context.read<TutorialService>();
    tutorialService.dismissMindfulnessTutorial();

    // Check if there are fewer than 2 stars before toggling
    if (provider.gratitudeStars.length < 2 && !provider.mindfulnessMode) {
      GratitudeDialogs.showMindfulnessNoStars(context);
      return;
    }

    provider.toggleMindfulness();
  }

  void _onMindfulnessIntervalChanged(double value) {
    context.read<GratitudeProvider>().setMindfulnessInterval(value.round());
  }

  void _jumpToStar(GratitudeStar star) {
    final navigationController = CameraNavigationController(
      cameraController: _cameraController,
      vsync: this,
      context: context,
    );
    navigationController.jumpToStar(star);
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

    // Dismiss star button tutorial when user taps the star button
    final tutorialService = context.read<TutorialService>();
    tutorialService.dismissStarButtonTutorial();

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
    final l10n = AppLocalizations.of(context)!;

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
        color = AppTheme.warning;
        tooltip = l10n.syncStatusPending;
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = l10n.syncStatusSyncing;
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off_outlined;
        color = Colors.grey;
        tooltip = 'Offline - will sync when connected';  // Keep existing for now
        break;
      case SyncStatus.error:
        icon = Icons.cloud_sync_outlined;
        color = AppTheme.error;
        tooltip = l10n.syncStatusError;
        break;
    }

    return Semantics(
      label: tooltip,
      button: syncStatus.status == SyncStatus.error,
      child: Container(
        width: 48,  // WCAG AA: 48dp minimum touch target
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
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

  void _showAccountDialog() {
    AccountDialog.show(
      context: context,
      authService: _authService,
      onSignOut: () async {
        // Check if user is anonymous
        final isAnonymous = !_authService.hasEmailAccount;
        
        final result = await GratitudeDialogs.showSignOutConfirmation(
          context: context,
          isAnonymous: isAnonymous,
          onConfirm: () {
            // This callback is called when user selects an option
            // The actual sign-out happens based on the result
          },
        );
        
        if (result != null && mounted) {
          // result is true for "keep data", false for "clear data", null for cancel
          if (isAnonymous) {
            if (result == true) {
              // Keep data - just sign out from Firebase
              await _authService.signOutKeepData();
            } else if (result == false) {
              // Clear data - full sign out
              await _authService.signOutClearData();
            }
            // If result is null, user cancelled
          } else {
            // Email user - always clear local data (cloud data remains)
            // result is true when user confirms sign-out
            await _authService.signOutClearData();
          }
        }
      },
    );
  }

  void _handleAccountTap() {
    Navigator.pop(context); // Close drawer
    // Show account dialog for both anonymous and email users
    _showAccountDialog();
  }

  void _showFeedbackDialog() async {
    if (kDebugMode) {
      AppLogger.info('📤 DEBUG: Opening feedback dialog');
    }

    final result = await FeedbackDialog.show(
      context: context,
      authService: _authService,
    );

    if (kDebugMode) {
      AppLogger.info('📤 DEBUG: Feedback dialog returned with result: $result');
      AppLogger.info('📤 DEBUG: mounted=$mounted');
    }

    // Show SnackBar if dialog returned a result
    if (result != null && mounted) {
      if (kDebugMode) {
        AppLogger.info('📤 DEBUG: About to show SnackBar for result: $result');
      }

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ? l10n.feedbackSuccess : l10n.feedbackError,
            style: FontScaling.getBodyMedium(context),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: result ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );

      if (kDebugMode) {
        AppLogger.info('📤 DEBUG: SnackBar shown successfully');
      }
    } else {
      if (kDebugMode) {
        AppLogger.info('📤 DEBUG: NOT showing SnackBar - result=$result, mounted=$mounted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GratitudeProvider>();
    final tutorialService = context.watch<TutorialService>();
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

    AppLogger.data(
      '🏗️ Building GratitudeScreen, isLoading: $isLoading, stars: ${gratitudeStars.length}',
    );

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
          _cameraController.updateBounds(
            gratitudeStars,
            MediaQuery.of(context).size,
          );
        }
      });
    }

    // Check for star button tutorial when loading completes with empty stars
    // Only check once to prevent infinite loop from notifyListeners()
    if (!isLoading && 
        gratitudeStars.isEmpty && 
        tutorialService.isInitialized && 
        !_hasCheckedStarButtonTutorial) {
      _hasCheckedStarButtonTutorial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAndShowStarButtonTutorial(gratitudeStars.length);
        }
      });
    }
    
    // Reset flag if stars are added (so tutorial can show again if stars are deleted)
    if (gratitudeStars.isNotEmpty && _hasCheckedStarButtonTutorial) {
      _hasCheckedStarButtonTutorial = false;
    }

    // Check for What's New auto-show after loading completes
    if (!isLoading && !_hasCheckedWhatsNew) {
      _hasCheckedWhatsNew = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final whatsNewService = context.read<WhatsNewService>();
          if (whatsNewService.shouldAutoShow) {
            whatsNewService.clearAutoShow();
            WhatsNewBottomSheet.show(context);
            whatsNewService.markAsSeen();
          }
        }
      });
    }

    final currentSize = MediaQuery.of(context).size;

    if (isLoading) {
      return LoadingStateWidget(previewColor: _previewColor);
    }

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_fontScale)),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawerWidget(
          authService: _authService,
          onAccountTap: _handleAccountTap,
          onListViewTap: () {
            _navigateToListView();
          },
          onGalaxiesTap: () {
            Navigator.pop(context); // Close drawer first
            _showGalaxiesDialog();
          },
          onFeedbackTap: () {
            _showFeedbackDialog();
          },
          onTrashTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TrashScreen()),
            );
          },
          onExitTap: () {
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
              GratitudeGestureHandler(
                cameraController: _cameraController,
                isAnimating: isAnimating,
                onStarTap: _handleStarTap,
              ),

              // Branding overlay
              if (_showBranding) BrandingOverlayWidget(onSkip: _skipSplash),

              // Sync status banner (at top, below safe area)
              // Only shows when user is signed in with email account
              if (!_showBranding)
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Consumer<SyncStatusService>(
                    builder: (context, syncStatusService, child) {
                      return SyncStatusBanner(
                        syncStatusService: syncStatusService,
                        authService: _authService,
                        onRetry: () {
                          final gratitudeProvider = context.read<GratitudeProvider>();
                          gratitudeProvider.forceSync();
                        },
                      );
                    },
                  ),
                ),

              // Sign-in prompt banner (for anonymous users)
              // Shows below sync banner or at top if no sync banner
              if (!_showBranding)
                Consumer<GratitudeProvider>(
                  builder: (context, gratitudeProvider, child) {
                    return Positioned(
                      top: MediaQuery.of(context).padding.top + 
                           (_authService.hasEmailAccount && 
                            gratitudeProvider.syncStatus.status != SyncStatus.synced ? 60 : 0),
                      left: 0,
                      right: 0,
                      child: SignInPromptBanner(
                        gratitudeProvider: gratitudeProvider,
                        authService: _authService,
                      ),
                    );
                  },
                ),

              // Stats card - positioned at top center, below banners
              if (!_showBranding)
                Consumer<GratitudeProvider>(
                  builder: (context, gratitudeProvider, child) {
                    // Calculate top position based on banners
                    // Stats card should be at top, accounting for safe area and banners
                    double topOffset = MediaQuery.of(context).padding.top + 16;
                    if (_authService.hasEmailAccount && 
                        gratitudeProvider.syncStatus.status != SyncStatus.synced) {
                      topOffset += 60; // Sync banner height
                    }
                    // Check if sign-in prompt is showing
                    return FutureBuilder<bool>(
                      future: gratitudeProvider.shouldShowSignInPrompt(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data! && !_authService.hasEmailAccount) {
                          topOffset += 60; // Sign-in prompt banner height
                        }
                        // Stats card at top center - season drawer is at top-right, so no overlap
                        return Positioned(
                          top: topOffset,
                          left: 0,
                          right: 0,
                          child: Center(child: StatsCardWidget(stars: gratitudeStars)),
                        );
                      },
                    );
                  },
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

              // Sync status indicator (top-right, below season drawer)
              if (!_showBranding)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16 + 60, // Position below season drawer
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
                      shouldPulse: tutorialService.showingStarButtonPulse,
                      onToggleShowAll: _toggleShowAll,
                      onToggleMindfulness: _toggleMindfulness,
                      onAddStar: _showAddGratitudeModal,
                      onMindfulnessIntervalChanged:
                          _onMindfulnessIntervalChanged,
                    ),
                  ),
                ),

              // Tutorial: Star button tooltip
              if (!_showBranding && tutorialService.showingStarButtonTooltip)
                StarButtonTutorialTooltip(
                  message: l10n.tutorialTapToCreateStar,
                  onDismiss: () => tutorialService.dismissStarButtonTutorial(),
                ),

              // Tutorial: Mindfulness button tooltip
              if (!_showBranding && tutorialService.showingMindfulnessTooltip)
                MindfulnessTutorialTooltip(
                  message: l10n.tutorialMindfulnessPrompt,
                  onDismiss: () => tutorialService.dismissMindfulnessTutorial(),
                ),

              // Empty state message
              if (!_showBranding && gratitudeStars.isEmpty) EmptyStateWidget(),

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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            l10n.adjustingStarFieldMessage,
                            style: FontScaling.getBodyMedium(
                              context,
                            ).copyWith(color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Season drawer (top-right) - must be last to ensure it's on top
              if (!_showBranding) const SeasonDrawer(),
            ],
          ),
        ),
      ),
    );
  }
}
