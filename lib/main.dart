import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'background.dart';
import 'camera_controller.dart';
import 'core/config/constants.dart';
import 'features/gratitudes/data/datasources/local_data_source.dart';
import 'features/gratitudes/data/datasources/remote_data_source.dart';
import 'features/gratitudes/data/repositories/gratitude_repository.dart';
import 'features/gratitudes/presentation/state/gratitude_provider.dart';
import 'features/gratitudes/presentation/widgets/app_drawer.dart';
import 'features/gratitudes/presentation/widgets/bottom_controls.dart';
import 'features/gratitudes/presentation/widgets/empty_state.dart';
import 'features/gratitudes/presentation/widgets/floating_label.dart';
import 'features/gratitudes/presentation/widgets/stats_card.dart';
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

    // Initialize services (these are singletons/static, so safe to create here)
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final localDataSource = LocalDataSource();
    final remoteDataSource = RemoteDataSource(firestoreService);
    final repository = GratitudeRepository(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      authService: authService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GratitudeProvider(
            repository: repository,
            authService: authService,
            random: math.Random(),
          )..loadGratitudes(), // Load data immediately
        ),
      ],
      child: MaterialApp(
        title: 'GratiStellar',
        debugShowCheckedModeBanner: false,
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

  List<OrganicNebulaRegion> _organicNebulaRegions = [];
  List<VanGoghStar> _vanGoghStars = [];
  List<BackgroundStar> _staticStars = [];
  List<Paint> _glowPatterns = [];
  List<Paint> _backgroundGradients = [];
  late AnimationController _backgroundController;
  late AnimationController _starController;
  late CameraController _cameraController;
  bool _showBranding = true;
  bool _isAppInBackground = false;
  bool _isMultiFingerGesture = false;
  AnimationController? _birthController;
  DateTime? _lastScrollTime;
  final String _userName = "A friend";
  Color? _previewColor;
  GratitudeStar? _lastMindfulnessStar;

  // Birth animation completion handler (class-level method)
  void _completeBirthAnimation() async {
    final provider = context.read<GratitudeProvider>();

    if (provider.animatingStar != null) {
      HapticFeedback.mediumImpact();

      await provider.completeBirthAnimation();

      // Update camera bounds for new star
      _cameraController.updateBounds(provider.gratitudeStars, MediaQuery.of(context).size);

      _birthController!.reset();
    }
  }

  @override
  void initState() {
    print('🎬 GratitudeScreen initState starting...');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = CameraController();

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

    // Layer-specific universe sizes
    final backgroundSize = screenSize;
    final nebulaSize = screenSize;
    final vanGoghSize = screenSize;

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

    // Provider handles loading via its initialization
    // Camera bounds will be updated in build() once data loads

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
    final provider = context.read<GratitudeProvider>();
    await provider.loadGratitudes();
    // Provider notifies listeners, UI updates automatically
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _backgroundController.dispose();
    _starController.dispose();
    _gratitudeController.dispose();
    _birthController?.dispose();
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
        }
        break;

      case AppLifecycleState.resumed:
      // App coming back to foreground
        if (_isAppInBackground) {
          _isAppInBackground = false;
          _backgroundController.repeat();
          _starController.repeat();

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

  void _addGratitude() async {
    final provider = context.read<GratitudeProvider>();

    // Cancel modes via provider
    provider.cancelModes();

    final trimmedText = _gratitudeController.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    if (trimmedText.isEmpty) return;

    final screenSize = MediaQuery.of(context).size;

    // Create star via provider
    final newStar = await provider.createGratitude(trimmedText, screenSize);

    _gratitudeController.clear();

    // Start animation via provider
    provider.startBirthAnimation(newStar);

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
    final shareText = '$_userName shared their gratitude with you:\n${star.text}\n\n- GratiStellar - your universe of thankfulness';
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

  void _navigateToMindfulnessStar(GratitudeStar star) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate world position
    final starWorldX = star.worldX * screenSize.width;
    final starWorldY = star.worldY * screenSize.height;
    final starWorldPos = Offset(starWorldX, starWorldY);

    // Position star at 40% from top to avoid bottom slider overlap
    final verticalPosition = screenSize.height * AnimationConstants.mindfulnessVerticalPosition;
    final targetScreenPos = Offset(screenSize.width / 2, verticalPosition);
    final targetCameraPos = targetScreenPos - (starWorldPos * _cameraController.scale);

    print('🧘 Navigating to mindfulness star at world: $starWorldPos');

    // Animate to the star
    _cameraController.animateTo(
      targetPosition: targetCameraPos,
      duration: Duration(milliseconds: AnimationConstants.mindfulnessTransitionMs),
      vsync: this,
    );
  }

  // Toggle methods
  void _toggleShowAll() {
    context.read<GratitudeProvider>().toggleShowAll();
  }

  void _toggleMindfulness() {
    context.read<GratitudeProvider>().toggleMindfulness();
  }

  void _onMindfulnessIntervalChanged(double value) {
    context.read<GratitudeProvider>().setMindfulnessInterval(value.round());
  }

  void _navigateToListView() async {
    final provider = context.read<GratitudeProvider>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListViewScreen(
          stars: provider.gratitudeStars,
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

  void _handleAccountTap() {
    Navigator.pop(context); // Close drawer
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GratitudeProvider>();

    // Get all state from provider
    final gratitudeStars = provider.gratitudeStars;
    final isLoading = provider.isLoading;
    final showAllGratitudes = provider.showAllGratitudes;
    final mindfulnessMode = provider.mindfulnessMode;
    final isAnimating = provider.isAnimating;
    final animatingStar = provider.animatingStar;
    final activeMindfulnessStar = provider.activeMindfulnessStar;
    final mindfulnessInterval = provider.mindfulnessInterval;

    print('🏗️ Building GratitudeScreen, isLoading: $isLoading, stars: ${gratitudeStars.length}');

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
      drawer: AppDrawerWidget(
        authService: _authService,
        onAccountTap: _handleAccountTap,
        onListViewTap: () {
          Navigator.pop(context);
          _navigateToListView();
        },
        onFeedbackTap: () {
          Navigator.pop(context);
          _showFeedbackDialog();
        },
        onExitTap: () {
          Navigator.pop(context);
          GratitudeDialogs.showQuitConfirmation(context);
        },
      ),
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
            Positioned.fill(
              child: RepaintBoundary(
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
            if (showAllGratitudes || mindfulnessMode)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _cameraController,
                    builder: (context, child) {
                      final starsToShow = mindfulnessMode && activeMindfulnessStar != null
                          ? [activeMindfulnessStar]
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
                          if (mindfulnessMode) {
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
                  behavior: HitTestBehavior.translucent,  // ← KEY: Makes entire area respond to gestures
                  onScaleStart: isAnimating ? null : (details) {
                    final provider = context.read<GratitudeProvider>();
                    if (provider.mindfulnessMode) {
                      provider.stopMindfulness();
                    }

                    // Detect if this is a multi-finger gesture
                    _isMultiFingerGesture = details.pointerCount > 1;
                  },
                  onScaleUpdate: isAnimating ? null : (details) {
                    final provider = context.read<GratitudeProvider>();
                    if (provider.mindfulnessMode) {
                      provider.stopMindfulness();
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
                  onScaleEnd: isAnimating ? null : (details) {
                    // Reset multi-finger flag when gesture ends
                    _isMultiFingerGesture = false;
                  },
                  onTapDown: isAnimating ? null : (details) {
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
            if (isAnimating && animatingStar != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_birthController!, _cameraController]),
                  builder: (context, child) {
                    return Transform(
                      transform: _cameraController.transform,
                      child: AnimatedStarBirth(
                        star: animatingStar,
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
                child: HamburgerButton(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),

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