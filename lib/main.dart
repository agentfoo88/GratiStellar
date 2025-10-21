import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background.dart';
import 'camera_controller.dart';
import 'core/config/constants.dart';
import 'features/gratitudes/presentation/widgets/floating_label.dart';
import 'features/gratitudes/presentation/widgets/empty_state.dart';
import 'firebase_options.dart';
import 'font_scaling.dart';
import 'gratitude_stars.dart';
import 'l10n/app_localizations.dart';
import 'list_view_screen.dart';
import 'modal_dialogs.dart';
import 'nebula_regions.dart';
import 'screens/sign_in_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'services/feedback_service.dart';
import 'services/firestore_service.dart';
import 'starfield.dart';
import 'storage.dart';
import 'widgets/app_dialog.dart';

// UI SCALE and ANIMATION CONFIGURATION found in constants.dart

void main() async {
  print('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('📦 Loading textures...');
  await BackgroundService.loadTextures();
  print('✅ Textures loaded, starting app');
  runApp(GratiStellarApp());
}

class GratiStellarApp extends StatelessWidget {
  const GratiStellarApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building GratiStellarApp');
    return MaterialApp(
      title: 'GratiStellar',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'JosefinSans',
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Auth-aware routing
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4A6FA5),
                      Color(0xFF166088),
                      Color(0xFF0B1426),
                      Color(0xFF2C3E50),
                    ],
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFE135),
                  ),
                ),
              ),
            );
          }

          // If user is signed in, show main app
          if (snapshot.hasData) {
            return GratitudeScreen();
          }

          // Otherwise, show welcome screen
          return WelcomeScreen();
        },
      ),
    );
  }
}

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
  final FirestoreService _firestoreService = FirestoreService();

  List<GratitudeStar> gratitudeStars = [];
  List<OrganicNebulaRegion> _organicNebulaRegions = [];
  List<VanGoghStar> _vanGoghStars = [];
  List<BackgroundStar> _staticStars = [];
  List<Paint> _glowPatterns = [];
  List<Paint> _backgroundGradients = [];
  late AnimationController _backgroundController;
  late AnimationController _starController;
  late CameraController _cameraController;
  bool _isLoading = true;
  bool _showBranding = true;
  bool _isAnimating = false;
  bool _isAppInBackground = false;
  bool _showAllGratitudes = false;
  bool _mindfulnessMode = false;
  bool _isMultiFingerGesture = false;
    AnimationController? _birthController;
  GratitudeStar? _animatingStar;
  final math.Random _random = math.Random();
  DateTime? _lastScrollTime;
  int _mindfulnessInterval = 3;
  Timer? _mindfulnessTimer;
  GratitudeStar? _activeMindfulnessStar;
  final String _userName = "A friend";
  Color? _previewColor;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    print('🎬 GratitudeScreen initState starting...');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = CameraController();

    // Monitor auth state changes
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (mounted && user != null && _authService.hasEmailAccount) {
        print('👤 Auth state changed, reloading gratitudes...');
        _loadGratitudes();
      }
    });

    _backgroundController = AnimationController(
      duration: AnimationConstants.backgroundDuration,
      vsync: this,
    )..repeat();

    _starController = AnimationController(
      duration: AnimationConstants.starFieldDuration,
      vsync: this,
    )..repeat();

    _birthController = AnimationController(
      duration: AnimationConstants.birthAnimationDuration,
      vsync: this,
    );

    _birthController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeBirthAnimation();
      }
    });

    print('🎭 Animation controllers created');

// Generate static universe based on full screen size
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenSize = view.physicalSize / view.devicePixelRatio;

// Layer-specific universe sizes (starting conservative, will adjust if needed)
    final backgroundSize = screenSize;  // No padding - doesn't zoom/pan
    final nebulaSize = screenSize;      // Starting at 1.0x - test if nebulae stay visible
    final vanGoghSize = screenSize;     // Starting at 1.0x - test if spiral stays centered

    _staticStars = BackgroundService.generateStaticStars(backgroundSize);
    _vanGoghStars = VanGoghStarService.generateVanGoghStars(vanGoghSize);
    _organicNebulaRegions = OrganicNebulaService.generateOrganicNebulae(nebulaSize);

    print('📐 Generated universe - Screen: ${screenSize.width.round()}x${screenSize.height.round()}');
    print('   Background: ${backgroundSize.width.round()}x${backgroundSize.height.round()} (${_staticStars.length} stars)');
    print('   Nebula: ${nebulaSize.width.round()}x${nebulaSize.height.round()} (${_organicNebulaRegions.length} regions)');
    print('   Van Gogh: ${vanGoghSize.width.round()}x${vanGoghSize.height.round()} (${_vanGoghStars.length} stars)');

    try {
      _initializePrecomputedElements();
      print('✅ Precomputed elements initialized');
    } catch (e) {
      print('❌ Error in initialization: $e');
    }

    _loadGratitudes();

    _startSplashTimer();
  }

  void _initializePrecomputedElements() {
    print('🌟 Starting initialization...');

    _glowPatterns = GratitudeStarService.generateGlowPatterns();
    print('✨ Generated ${_glowPatterns.length} glow patterns');

    _backgroundGradients = BackgroundService.generateBackgroundGradients();
    print('🎨 Generated ${_backgroundGradients.length} background gradients');
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
    print('💾 Loading gratitudes...');

    // Check if this is first run after install/reinstall
    await _checkFirstRun();

    // Restore anonymous session if exists
    await _restoreAnonymousSessionIfNeeded();

    // Safety check: If signed in, verify local data belongs to current user
    if (_authService.isSignedIn) {
      final currentUid = _authService.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      final localDataOwner = prefs.getString('local_data_owner_uid');

      if (localDataOwner != null && localDataOwner != currentUid) {
        // Local data belongs to different user - clear ALL data!
        print('⚠️ Local data belongs to different user. Clearing...');
        await StorageService.clearAllData();  // ← Use centralized clear
        await prefs.setString('local_data_owner_uid', currentUid!);

        // Load empty list, will sync from cloud
        if (mounted) {
          setState(() {
            gratitudeStars = [];
            _isLoading = false;
          });
        }

        // Sync from cloud
        if (_authService.hasEmailAccount) {
          _syncWithCloud();
        }
        return; // Exit early
      }

      // Store current user as owner if not set
      if (localDataOwner == null && currentUid != null) {
        await prefs.setString('local_data_owner_uid', currentUid);
      }
    }
    final stars = await StorageService.loadGratitudeStars();

    if (mounted) {
      setState(() {
        gratitudeStars = stars;
        _isLoading = false;
        print('🎯 Loaded ${stars.length} gratitude stars, _isLoading = false');
      });
      // Initialize camera bounds after loading stars
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _cameraController.updateBounds(gratitudeStars, MediaQuery.of(context).size);
        }
      });

      // If user is signed in with email, sync with cloud AFTER local load
      if (_authService.hasEmailAccount) {
        print('🔄 User has email account, starting cloud sync...');
        await _syncWithCloud();
      }
    }
  }

  Future<void> _restoreAnonymousSessionIfNeeded() async {
    try {
      // Only restore if not currently signed in
      if (_authService.isSignedIn) {
        print('✓ User already signed in, skipping session restoration');
        return;
      }

      // Check if we have a saved anonymous UID
      final savedUid = await _authService.getSavedAnonymousUid();

      if (savedUid != null) {
        print('🔄 Found saved anonymous UID: $savedUid');

        // Firebase will auto-restore anonymous sessions if valid
        // We just need to wait a moment for Firebase to initialize
        await Future.delayed(Duration(milliseconds: 500));

        // Check if session was restored
        if (_authService.isSignedIn && _authService.currentUser?.uid == savedUid) {
          print('✅ Anonymous session restored successfully');
        } else {
          print('⚠️ Saved session expired or invalid, will create new session on welcome screen');
        }
      } else {
        print('ℹ️ No saved anonymous UID found');
      }
    } catch (e) {
      print('⚠️ Error restoring anonymous session: $e');
      // Continue normally - user will create new session
    }
  }

  Future<void> _syncWithCloud() async {
    try {
      print('🔄 Starting cloud sync...');

      // Check if user has cloud data
      final hasCloudData = await _firestoreService.hasCloudData();

      if (hasCloudData) {
        // Sync and merge data
        print('📥 Cloud data exists, syncing...');
        final mergedStars = await _firestoreService.syncStars(gratitudeStars);

        if (mounted) {
          setState(() {
            gratitudeStars = mergedStars;
          });
          await _saveGratitudes();
          print('✅ Sync complete! Total stars: ${mergedStars.length}');
        }
      } else {
        // First time - upload local stars to cloud
        print('📤 No cloud data, uploading local stars...');
        await _firestoreService.uploadStars(gratitudeStars);
        print('✅ Local stars uploaded to cloud');
      }
    } catch (e) {
      print('⚠️ Sync failed: $e');
      // Don't show error to user - local data is still safe
    }
  }

  Future<void> _saveGratitudes() async {
    await StorageService.saveGratitudeStars(gratitudeStars);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _cameraController.dispose();
    _backgroundController.dispose();
    _starController.dispose();
    _gratitudeController.dispose();
    _birthController?.dispose();
    _mindfulnessTimer?.cancel();
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
          _backgroundController.stop();
          _starController.stop();
          _birthController?.stop();
          _mindfulnessTimer?.cancel();
        }
        break;

      case AppLifecycleState.resumed:
      // App coming back to foreground
        if (_isAppInBackground) {
          _isAppInBackground = false;
          _backgroundController.repeat();
          _starController.repeat();

          // Reload gratitudes when app resumes (will sync if signed in)
          if (_authService.hasEmailAccount) {
            _loadGratitudes();
          }

          // Restart mindfulness timer if it was active
          if (_mindfulnessMode) {
            _scheduleNextStar();
          }
        }
        break;

      case AppLifecycleState.hidden:
      // Do nothing for now
        break;
    }
  }

  void _addGratitude() async {
    // Cancel mindfulness mode if active
    if (_mindfulnessMode) {
      _stopMindfulnessMode();
      setState(() {
        _mindfulnessMode = false;
      });
    }

    // Cancel show all mode if active
    if (_showAllGratitudes) {
      setState(() {
        _showAllGratitudes = false;
      });
    }

    // Trim whitespace, newlines, and collapse multiple spaces
    final trimmedText = _gratitudeController.text
        .trim()                           // Remove leading/trailing whitespace
        .replaceAll(RegExp(r'\s+'), ' '); // Collapse multiple spaces/newlines to single space

    if (trimmedText.isEmpty) return;

    final screenSize = MediaQuery.of(context).size;
    final newStar = GratitudeStarService.createStar(
      trimmedText,  // Use trimmed text instead of raw controller text
      screenSize,
      _random,
      gratitudeStars,
    );

    _gratitudeController.clear();

    setState(() {
      _isAnimating = true;
      _animatingStar = newStar;
    });

    await _adjustCameraForDestination(newStar, screenSize);

    final startScreen = Offset(screenSize.width / 2, screenSize.height);
    final endWorld = Offset(newStar.worldX * screenSize.width, newStar.worldY * screenSize.height);
    final endScreen = _cameraController.worldToScreen(endWorld);

    final distance = (endScreen - startScreen).distance;
    final duration = (distance / StarBirthConfig.travelBaseSpeed * 1000)
        .clamp(StarBirthConfig.travelDurationMin.toDouble(),
        StarBirthConfig.travelDurationMax.toDouble())
        .toInt();

    _birthController!.duration = Duration(milliseconds: duration);
    _birthController!.forward(from: 0.0);
  }

  void _completeBirthAnimation() {
    if (_animatingStar != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        gratitudeStars.add(_animatingStar!);
        _animatingStar = null;
        _isAnimating = false;
      });
      _saveGratitudes();
      // Update camera bounds for new star
      _cameraController.updateBounds(gratitudeStars, MediaQuery.of(context).size);

      // Sync to cloud if signed in
      if (_authService.hasEmailAccount) {
        _firestoreService.addStar(gratitudeStars.last).catchError((e) {
          print('⚠️ Failed to sync new star to cloud: $e');
        });
      }

      _birthController!.reset();
    }
  }

  Future<void> _adjustCameraForDestination(GratitudeStar star, Size screenSize) async {
    final targetScreenPos = Offset(screenSize.width / 2, screenSize.height / 2);
    final worldPosPixels = Offset(star.worldX * screenSize.width, star.worldY * screenSize.height);
    final targetCameraPosition = targetScreenPos - (worldPosPixels * _cameraController.scale);

    print('🎯 Centering star at scale ${_cameraController.scale}');
    print('World pos: $worldPosPixels, Target screen: $targetScreenPos');
    print('Target camera position: $targetCameraPosition');

    _cameraController.animateTo(
      targetPosition: targetCameraPosition,
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    await Future.delayed(Duration(milliseconds: 400));
  }

  /// Shows the edit dialog for a star (delegates to modal_dialogs.dart)
  void _showStarDetails(
      GratitudeStar star, {
        VoidCallback? onJumpToStar,
        VoidCallback? onAfterSave,
        VoidCallback? onAfterDelete,
      }) {
    GratitudeDialogs.showEditStar(
      context: context,
      star: star,
      allStars: gratitudeStars,
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
    final shareText = '$_userName shared their gratitude with you:\n${star.text}\n\n- GratiStellar - your universe of thankfulness';
    SharePlus.instance.share(
        ShareParams(text: shareText)
    );
  }

  void _saveStarEdits(GratitudeStar updatedStar) {
    final index = gratitudeStars.indexWhere((s) => s.id == updatedStar.id);
    if (index != -1) {
      HapticFeedback.mediumImpact();
      setState(() {
        gratitudeStars[index] = updatedStar;
      });
      _saveGratitudes();
    }
  }

  void _deleteStar(GratitudeStar star) {
    HapticFeedback.heavyImpact();

    final starId = star.id; // Save ID before removing

    setState(() {
      gratitudeStars.removeWhere((s) => s.id == star.id);
    });
    _saveGratitudes();
    // Update camera bounds after deletion
    _cameraController.updateBounds(gratitudeStars, MediaQuery.of(context).size);

    // Sync deletion to cloud if signed in
    if (_authService.hasEmailAccount) {
      _firestoreService.deleteStar(starId).catchError((e) {
        print('⚠️ Failed to sync star deletion to cloud: $e');
      });
    }
  }

  void _handleStarTap(TapDownDetails details) {
    final screenSize = MediaQuery.of(context).size;

    final tappedStar = StarHitTester.findStarAtScreenPosition(
      details.localPosition,
      gratitudeStars,
      screenSize,
      cameraPosition: _cameraController.position,
      cameraScale: _cameraController.scale,
    );

    if (tappedStar != null) {
      HapticFeedback.lightImpact();
      _showStarDetails(tappedStar);
    }
  }

  // Toggle methods
  void _toggleShowAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _showAllGratitudes = !_showAllGratitudes;
      // Disable mindfulness mode when enabling show all
      if (_showAllGratitudes && _mindfulnessMode) {
        _stopMindfulnessMode();
        _mindfulnessMode = false;
      }
    });
  }

  void _toggleMindfulness() {
    // Check if there are any stars
    if (gratitudeStars.isEmpty) {
      GratitudeDialogs.showMindfulnessNoStars(context);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _mindfulnessMode = !_mindfulnessMode;
      // Disable show all mode when enabling mindfulness
      if (_mindfulnessMode && _showAllGratitudes) {
        _showAllGratitudes = false;
      }
    });

    if (_mindfulnessMode) {
      _startMindfulnessMode();
    } else {
      _stopMindfulnessMode();
    }
  }

  void _startMindfulnessMode() {
    print('Mindfulness mode started');

    // Immediately select and navigate to first star
    _selectRandomStar();

    // Schedule next star selection after interval + camera movement time
    _scheduleNextStar();
  }

  void _scheduleNextStar() {
    // Wait for: interval duration + camera animation (2000ms) + buffer (200ms)
    final totalDelay = Duration(milliseconds: (_mindfulnessInterval * 1000) + 2200);

    _mindfulnessTimer?.cancel();
    _mindfulnessTimer = Timer(totalDelay, () {
      if (mounted && _mindfulnessMode) {
        _selectRandomStar();
        _scheduleNextStar(); // Schedule the next one
      }
    });
  }

  void _stopMindfulnessMode() {
    _mindfulnessTimer?.cancel();
    _mindfulnessTimer = null;
    setState(() {
      _activeMindfulnessStar = null;
    });
    print('Mindfulness mode stopped');
  }

  void _selectRandomStar() {
    if (gratitudeStars.isEmpty) {
      _stopMindfulnessMode();
      setState(() {
        _mindfulnessMode = false;
      });
      return;
    }

    final random = math.Random();
    final selectedStar = gratitudeStars[random.nextInt(gratitudeStars.length)];

    print('🧘 Mindfulness: Selected star "${selectedStar.text}"');
    print('🧘 Star position: (${selectedStar.worldX}, ${selectedStar.worldY})');

    HapticFeedback.lightImpact();

    // Update star - AnimatedSwitcher handles the animation
    setState(() {
      _activeMindfulnessStar = selectedStar;
    });

    print('🧘 Active mindfulness star set: ${_activeMindfulnessStar?.text}');

    _navigateToMindfulnessStar(selectedStar);
  }

  void _navigateToMindfulnessStar(GratitudeStar star) {
    final screenSize = MediaQuery.of(context).size;
    final targetScale = CameraController.focusZoomLevel;

    // Convert star's normalized world coordinates to pixels
    final starWorldX = star.worldX * screenSize.width;
    final starWorldY = star.worldY * screenSize.height;

    print('🧘 Screen size: $screenSize');
    print('🧘 Star world position (pixels): ($starWorldX, $starWorldY)');
    print('🧘 Target scale: $targetScale');

    // Calculate camera position to center the star at the new scale
    final verticalPosition = screenSize.height * 0.40;

    final targetPosition = Offset(
      screenSize.width / 2 - starWorldX * targetScale,
      verticalPosition - starWorldY * targetScale,
    );

    print('🧘 Target camera position: $targetPosition');

    _cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: targetScale,
      duration: Duration(milliseconds: AnimationConstants.mindfulnessTransitionMs),
      curve: Curves.easeInOutCubic,  // Smooth speed ramp at start and end
      vsync: this,
    );
  }

  void _onMindfulnessIntervalChanged(double value) {
    setState(() {
      _mindfulnessInterval = value.round();
    });

    // Restart timer with new interval if currently active
    if (_mindfulnessMode && _mindfulnessTimer != null) {
      _scheduleNextStar();  // ✅ Use the correct method that includes camera delay
    }
  }

  void _navigateToListView() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListViewScreen(
          stars: gratitudeStars,
          onStarTap: (star, refreshList) => _showStarDetailsFromList(star, refreshList),
          onJumpToStar: (star) {},
        ),
      ),
    );
  }

  void _showStarDetailsFromList(GratitudeStar star, VoidCallback refreshList) {
    _showStarDetails(
      star,
      onJumpToStar: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _jumpToStar(star);
      },
      onAfterSave: refreshList,     // ← Add this
      onAfterDelete: refreshList,   // ← Add this
    );
  }

  void _jumpToStar(GratitudeStar star) {
    final screenSize = MediaQuery.of(context).size;
    final targetScale = CameraController.focusZoomLevel;

    // Convert star's normalized world coordinates to pixels
    final starWorldX = star.worldX * screenSize.width;
    final starWorldY = star.worldY * screenSize.height;

    // Calculate camera position to center the star at the new scale
    final targetPosition = Offset(
      screenSize.width / 2 - starWorldX * targetScale,
      screenSize.height / 2 - starWorldY * targetScale,
    );

    _cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: targetScale,
      duration: Duration(milliseconds: 1500),
      curve: Curves.easeInOutCubic,
      vsync: this,
    );
  }

  // Helper widget builders
  Widget _buildHamburgerButton() {
    return GestureDetector(
      onTap: () {
        _scaffoldKey.currentState?.openDrawer();
      },
      child: Icon(
        Icons.menu,
        color: Colors.white.withValues(alpha: 0.8),
        size: FontScaling.getResponsiveIconSize(context, 28) * UIConstants.universalUIScale,
      ),
    );
  }

  Widget _buildDrawer() {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Color(0xFF1A2238).withValues(alpha: 0.98),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with Icon and Title side-by-side
          Container(
            padding: EdgeInsets.fromLTRB(
              FontScaling.getResponsiveSpacing(context, 16),
              MediaQuery.of(context).padding.top + FontScaling.getResponsiveSpacing(context, 16),
              FontScaling.getResponsiveSpacing(context, 16),
              FontScaling.getResponsiveSpacing(context, 16),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A6FA5).withValues(alpha: 0.3),
                  Color(0xFF1A2238),
                ],
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icon_star.svg',
                  width: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                  height: FontScaling.getResponsiveIconSize(context, 48) * UIConstants.universalUIScale,
                  colorFilter: ColorFilter.mode(Color(0xFFFFE135), BlendMode.srcIn),
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
                Expanded(
                  child: Text(
                    l10n.appTitle,
                    style: FontScaling.getHeadingMedium(context).copyWith(
                      fontSize: FontScaling.getHeadingMedium(context).fontSize! * UIConstants.universalUIScale,
                      color: Color(0xFFFFE135),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Account section
          ListTile(
            leading: Icon(
              _authService.hasEmailAccount ? Icons.account_circle : Icons.login,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
            title: Text(
              _authService.hasEmailAccount
                  ? l10n.accountMenuItem
                  : l10n.signInWithEmailMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
              ),
            ),
            subtitle: _authService.hasEmailAccount
                ? Text(
              _authService.currentUser?.displayName ?? l10n.defaultUserName,
              style: FontScaling.getCaption(context),
            )
                : null,
            onTap: () {
              Navigator.pop(context);
              if (_authService.hasEmailAccount) {
                _showAccountDialog();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInScreen(),
                  ),
                );
              }
            },
          ),

          // Heavy divider
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.5),
            thickness: 2,
            height: 2,
          ),

          // List View
          ListTile(
            leading: Icon(
              Icons.list,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
            title: Text(
              l10n.listViewMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _navigateToListView();
            },
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Send Feedback
          ListTile(
            leading: Icon(
              Icons.feedback_outlined,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
            title: Text(
              l10n.feedbackMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showFeedbackDialog();
            },
          ),

          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

          // Exit
          ListTile(
            leading: Icon(
              Icons.close,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
            ),
            title: Text(
              l10n.exitButton,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * UIConstants.universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              GratitudeDialogs.showQuitConfirmation(context);
            },
          ),
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),

// Version number at bottom
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              final buildNumber = snapshot.data?.buildNumber ?? '1';

              return Padding(
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 16)),
                child: Center(
                  child: Text(
                    'Version $version ($buildNumber)',
                    style: FontScaling.getCaption(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddGratitudeModal() {
    GratitudeDialogs.showAddGratitude(
      context: context,
      controller: _gratitudeController,
      onAdd: _addGratitude,
      isAnimating: _isAnimating,
    );
  }

  Widget _buildAddStarButton() {
    return GestureDetector(
      onTap: _isAnimating ? null : _showAddGratitudeModal,
      child: Container(
        width: FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale,
        height: FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale,
        decoration: BoxDecoration(
          color: _isAnimating
              ? Color(0xFFFFE135).withValues(alpha: 0.5)
              : Color(0xFFFFE135),
          borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 35) * UIConstants.universalUIScale),
          boxShadow: _isAnimating ? [] : [
            BoxShadow(
              color: Color(0xFFFFE135).withValues(alpha: 0.4),
              blurRadius: 20 * UIConstants.universalUIScale,
              spreadRadius: 5 * UIConstants.universalUIScale,
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icon_star.svg',
            width: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
            height: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Bottom row UI buttons
  Widget _buildBottomButtonRow() {
    // Calculate button row dimensions
    final buttonSize = FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale;
    final spacing = FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale;
    final addStarSize = FontScaling.getResponsiveSpacing(context, 70) * UIConstants.universalUIScale;

    // Total row width
    final rowWidth = buttonSize + spacing + addStarSize + spacing + buttonSize;

    // Offset from center to mindfulness button center
    // Need to go right by: half of add star + spacing + half of button
    final connectorOffset = (addStarSize / 2) + spacing + (buttonSize / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Horizontal slider appears above buttons when mindfulness is active
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _mindfulnessMode ? null : 0,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _mindfulnessMode ? 1.0 : 0.0,
            child: _mindfulnessMode ? _buildMindfulnessSlider() : SizedBox.shrink(),
          ),
        ),

        // Connector line from slider to mindfulness button
        if (_mindfulnessMode)
          SizedBox(
            height: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
            width: rowWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: (rowWidth / 2) + connectorOffset - 1,  // Center + offset - half line width
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: _mindfulnessMode ? 1.0 : 0.0,
                    child: Container(
                      width: 2,
                      height: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFE135).withValues(alpha: 0.5),
                            Color(0xFFFFE135).withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Stable 3-button row (never moves)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.visibility,
              isActive: _showAllGratitudes,
              onTap: _toggleShowAll,
            ),
            SizedBox(width: spacing),
            _buildAddStarButton(),
            SizedBox(width: spacing),
            _buildActionButton(
              icon: Icons.self_improvement,
              isActive: _mindfulnessMode,
              onTap: _toggleMindfulness,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMindfulnessSlider() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    // Calculate responsive width
    final sliderWidth = isMobile
        ? math.min(220.0, screenWidth * 0.6)  // Max 220px or 60% of screen (whichever is smaller)
        : 200.0;  // Compact on larger screens too

    return Container(
      width: sliderWidth,
      padding: EdgeInsets.symmetric(
        horizontal: FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale,
        vertical: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1A2238).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20 * UIConstants.universalUIScale),
        border: Border.all(
          color: Color(0xFFFFE135).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppLocalizations.of(context)!.mindfulnessIntervalLabel}: ${_mindfulnessInterval}s',
            style: FontScaling.getCaption(context).copyWith(
              fontSize: FontScaling.getBodySmall(context).fontSize! * UIConstants.universalUIScale,
            ),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8) * UIConstants.universalUIScale),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Color(0xFFFFE135),
              inactiveTrackColor: Color(0xFFFFE135).withValues(alpha: 0.3),
              thumbColor: Color(0xFFFFE135),
              overlayColor: Color(0xFFFFE135).withValues(alpha: 0.2),
              trackHeight: 4 * UIConstants.universalUIScale,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 12 * UIConstants.universalUIScale,  // Larger thumb for mobile
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: 24 * UIConstants.universalUIScale,  // Larger tap target
              ),
            ),
            child: Slider(
              value: _mindfulnessInterval.toDouble(),
              min: 2,
              max: 20,
              divisions: 18,
              onChanged: _onMindfulnessIntervalChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isAnimating ? null : onTap,
      child: Container(
        width: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
        height: FontScaling.getResponsiveSpacing(context, 56) * UIConstants.universalUIScale,
        decoration: BoxDecoration(
          color: isActive
              ? Color(0xFFFFE135).withValues(alpha: 0.9)
              : Color(0xFF1A2238).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 28) * UIConstants.universalUIScale),
          border: Border.all(
            color: Color(0xFFFFE135).withValues(alpha: isActive ? 1.0 : 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Color(0xFF1A2238) : Colors.white.withValues(alpha: 0.8),
          size: FontScaling.getResponsiveIconSize(context, 24) * UIConstants.universalUIScale,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Color(0xFFFFE135),
          size: FontScaling.getResponsiveIconSize(context, 20) * UIConstants.universalUIScale,
        ),
        SizedBox(height: FontScaling.getResponsiveSpacing(context, 4) * UIConstants.universalUIScale),
        Text(
          label,
          style: FontScaling.getStatsLabel(context).copyWith(
            fontSize: FontScaling.getStatsLabel(context).fontSize! * UIConstants.statsLabelTextScale,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: FontScaling.getStatsNumber(context).copyWith(
              fontSize: FontScaling.getStatsNumber(context).fontSize! * UIConstants.universalUIScale,
            ),
          ),
      ],
    );
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
                        style: FontScaling.getInputText(context),
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
                        keyboardType: TextInputType.emailAddress,
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

                              final success = await feedbackService.submitFeedback(
                                type: selectedType,
                                message: message,
                                contactEmail: contactEmail.isNotEmpty ? contactEmail : null,
                              );

                              if (mounted) {
                                scaffoldMessenger.showSnackBar(  // ← Use captured reference
                                  SnackBar(
                                    content: Text(
                                        success ? l10n.feedbackSuccess : l10n.feedbackError
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

  // Check if this is the first run after install and clear stale data
  Future<void> _checkFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRunBefore = prefs.getBool('has_run_before') ?? false;

      if (!hasRunBefore) {
        print('🆕 First run detected - clearing any stale data');

        // Clear all local data to ensure fresh start
        await StorageService.clearAllData();

        // Mark that app has run
        await prefs.setBool('has_run_before', true);

        print('✅ First run setup complete');
      }
    } catch (e) {
      print('⚠️ Error checking first run: $e');
      // Non-critical, continue anyway
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building GratitudeScreen, _isLoading: $_isLoading, stars: ${_staticStars.length}');

    final currentSize = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFF4A6FA5),
                Color(0xFF166088),
                Color(0xFF0B1426),
                Color(0xFF2C3E50),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icon_star.svg',
                  width: FontScaling.getResponsiveIconSize(context, 64),
                  height: FontScaling.getResponsiveIconSize(context, 64),
                  colorFilter: ColorFilter.mode(_previewColor ?? Colors.white, BlendMode.srcIn),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 20)),
                Text(
                  AppLocalizations.of(context)!.loadingMessage,
                  style: FontScaling.getBodyMedium(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Layer 1: Static background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _cameraController,
                  builder: (context, child) {
                    return Transform(
                      transform: _cameraController.getBackgroundTransform(),
                      child: CustomPaint(
                        painter: StaticBackgroundPainter(_staticStars),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),
            ),

            // Layer 2: Nebula
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_backgroundController, _cameraController]),
                  builder: (context, child) {
                    return Transform(
                      transform: _cameraController.getNebulaTransform(currentSize),
                      child: OrganicNebulaWidget(
                        regions: _organicNebulaRegions,
                        animationValue: _backgroundController.value,
                      ),
                    );
                  },
              ),
            ),

            // Layer 2.5: Van Gogh stars
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _cameraController,
                  builder: (context, child) {
                    return Transform(
                      transform: _cameraController.getVanGoghTransform(currentSize),
                      child: CustomPaint(
                        painter: VanGoghMidgroundPainter(_vanGoghStars),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),
            ),

            // Layer 3: Visual starfield (rendering only, no gestures)
            RepaintBoundary(
              child: Positioned.fill(
                child: AnimatedBuilder(
                  animation: _cameraController,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // Stars layer
                        Transform(
                          transform: _cameraController.transform,
                          child: StarfieldCanvas(
                            stars: gratitudeStars,
                            animationController: _starController,
                            glowPatterns: _glowPatterns,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Layer 3.5: Floating labels (NO TRANSFORM - window level)
            if (_showAllGratitudes || _mindfulnessMode)
              RepaintBoundary(
                child: Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _cameraController,
                    builder: (context, child) {
                      final starsToShow = _mindfulnessMode && _activeMindfulnessStar != null
                          ? [_activeMindfulnessStar!]
                          : gratitudeStars;

                      // Viewport culling: filter out off-screen stars
                      final visibleStars = starsToShow.where((star) {
                        final starX = star.worldX * currentSize.width;
                        final starY = star.worldY * currentSize.height;
                        final starScreenX = (starX * _cameraController.scale) + _cameraController.position.dx;
                        final starScreenY = (starY * _cameraController.scale) + _cameraController.position.dy;

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
                          if (_mindfulnessMode) {
                            return TweenAnimationBuilder<double>(
                              key: ValueKey(star.id),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 1000),
                              builder: (context, opacity, child) {
                                return FloatingGratitudeLabel(
                                  star: star,
                                  screenSize: currentSize,
                                  cameraScale: _cameraController.scale,
                                  cameraPosition: _cameraController.position,
                                  opacity: opacity,
                                );
                              },
                            );
                          }

                          // Show All mode: no animation
                          return FloatingGratitudeLabel(
                            star: star,
                            screenSize: currentSize,
                            cameraScale: _cameraController.scale,
                            cameraPosition: _cameraController.position,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),

            // Layer 4: Full-screen gesture detection (MOVED HERE)
            Positioned.fill(
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    if (_mindfulnessMode) {
                      _stopMindfulnessMode();
                      setState(() {
                        _mindfulnessMode = false;
                      });
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
                  behavior: HitTestBehavior.translucent,  // ← KEY: Makes entire area respond to gestures
                  onScaleStart: _isAnimating ? null : (details) {
                    if (_mindfulnessMode) {
                      _stopMindfulnessMode();
                      setState(() {
                        _mindfulnessMode = false;
                      });
                    }

                    // Detect if this is a multi-finger gesture
                    _isMultiFingerGesture = details.pointerCount > 1;
                  },
                  onScaleUpdate: _isAnimating ? null : (details) {
                    if (_mindfulnessMode) {
                      _stopMindfulnessMode();
                      setState(() {
                        _mindfulnessMode = false;
                      });
                    }

                    // Handle pinch zoom with threshold to reduce sensitivity
                    if (details.scale != 1.0) {
                      final scaleChange = (details.scale - 1.0).abs();
                      if (scaleChange > 0.01) {
                        // Very gentle zoom
                        final dampingFactor = 0.025;
                        final dampenedScale = 1.0 + ((details.scale - 1.0) * dampingFactor);
                        final newScale = _cameraController.scale * dampenedScale;
                        _cameraController.updateScale(newScale, details.focalPoint);
                      }
                    }

                    // Handle pan (when not pinching)
                    if (details.scale == 1.0) {
                      _cameraController.updatePosition(details.focalPointDelta);
                    }
                  },
                  onScaleEnd: _isAnimating ? null : (details) {
                    // Reset multi-finger flag when gesture ends
                    _isMultiFingerGesture = false;
                  },
                  onTapDown: _isAnimating ? null : (details) {
                    // Only handle tap if it wasn't a multi-finger gesture
                    if (!_isMultiFingerGesture) {
                      _handleStarTap(details);
                    }
                  },
                  child: Container(color: Colors.transparent), // Transparent hit target
                ),
              ),
            ),
            // Animated star birth layer
            if (_isAnimating && _animatingStar != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_birthController!, _cameraController]),
                  builder: (context, child) {
                    return Transform(
                      transform: _cameraController.transform,
                      child: AnimatedStarBirth(
                        star: _animatingStar!,
                        animation: _birthController!,
                        cameraController: _cameraController,
                        screenSize: MediaQuery.of(context).size,
                      ),
                    );
                  },
                ),
              ),

            // Branding overlay
            if (_showBranding)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _skipSplash,  // ADD THIS
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.appTitle,
                            style: FontScaling.getAppTitle(context).copyWith(
                              fontSize: FontScaling.getAppTitle(context).fontSize! * UIConstants.universalUIScale,
                            ),
                          ),
                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 16) * UIConstants.universalUIScale),
                          Text(
                            AppLocalizations.of(context)!.appSubtitle,
                            style: FontScaling.getSubtitle(context).copyWith(
                              fontSize: FontScaling.getSubtitle(context).fontSize! * UIConstants.universalUIScale,
                            ),
                          ),
                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 32) * UIConstants.universalUIScale),
                          // Add skip hint
                          Text(
                            'Tap to skip',
                            style: FontScaling.getCaption(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Hamburger menu button (top-left)
            if (!_showBranding)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: _buildHamburgerButton(),
              ),

            // Stats card
            if (!_showBranding)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale,
                      vertical: FontScaling.getResponsiveSpacing(context, 12) * UIConstants.universalUIScale,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A2238).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20 * UIConstants.universalUIScale),
                      border: Border.all(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatItem(Icons.star, AppLocalizations.of(context)!.statsTotal, StorageService.getTotalStars(gratitudeStars).toString()),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale),
                          _buildStatItem(Icons.trending_up, AppLocalizations.of(context)!.statsThisWeek, StorageService.getThisWeekStars(gratitudeStars).toString()),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20) * UIConstants.universalUIScale),
                          _buildStatItem(
                            StorageService.getAddedToday(gratitudeStars) ? Icons.check_circle : Icons.radio_button_unchecked,
                            AppLocalizations.of(context)!.statsToday,
                            '',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom button row with slider integrated
            if (!_showBranding)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 50,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildBottomButtonRow(),
                ),
              ),

            // Empty state message
            if (!_showBranding && gratitudeStars.isEmpty)
              EmptyStateWidget(),

            // Camera controls overlay
            if (!_showBranding)
              CameraControlsOverlay(  // REMOVE RepaintBoundary wrapper here
                cameraController: _cameraController,
                stars: gratitudeStars,
                screenSize: MediaQuery.of(context).size,
                vsync: this,
                safeAreaPadding: MediaQuery.of(context).padding,
              ),
          ],
        ),
      ),
    );
  }
}