import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'storage.dart';
import 'background.dart';
import 'camera_controller.dart';
import 'starfield.dart';
import 'gratitude_stars.dart';
import 'nebula_regions.dart';
import 'font_scaling.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'modal_dialogs.dart';
import 'list_view_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/sign_in_screen.dart';
import 'widgets/app_dialog.dart';
import 'firebase_options.dart';

// ========================================
// UI SCALE CONFIGURATION
// ========================================
const double universalUIScale = 1.0;
const double labelBackgroundAlpha = 0.85;
const double statsLabelTextScale = 1.15;

// ========================================
// ANIMATION CONFIGURATION
// ========================================
const int mindfulnessTransitionMs = 2000;  // Duration for camera movement and label animation

// Floating label widget for displaying gratitude text
class FloatingGratitudeLabel extends StatelessWidget {
  final GratitudeStar star;
  final Size screenSize;
  final double cameraScale;
  final Offset cameraPosition;

  const FloatingGratitudeLabel({
    super.key,
    required this.star,
    required this.screenSize,
    required this.cameraScale,
    required this.cameraPosition,
  });

  @override
  Widget build(BuildContext context) {
    // Work in world coordinates
    final starX = star.worldX * screenSize.width;
    final starY = star.worldY * screenSize.height;

    final maxLabelWidth = screenSize.width * 0.4;
    const verticalOffset = 70.0;

    // Enhanced edge padding that accounts for zoom level
    final dynamicEdgePadding = 8.0 + (40.0 / cameraScale.clamp(0.5, 2.0));

    // Calculate desired centered position
    double horizontalTranslation = -0.5;

    // Convert star world position to screen position
    final starScreenX = (starX * cameraScale) + cameraPosition.dx;

    // Check if label would overflow left edge
    final labelLeftEdge = starScreenX - (maxLabelWidth / 2);
    if (labelLeftEdge < dynamicEdgePadding) {
      final shiftRight = dynamicEdgePadding - labelLeftEdge;
      horizontalTranslation = -0.5 + (shiftRight / maxLabelWidth);
    }

    // Check if label would overflow right edge
    final labelRightEdge = starScreenX + (maxLabelWidth / 2);
    if (labelRightEdge > screenSize.width - dynamicEdgePadding) {
      final overhang = labelRightEdge - (screenSize.width - dynamicEdgePadding);
      horizontalTranslation = -0.5 - (overhang / maxLabelWidth);
    }

    return Positioned(
      left: starX,
      top: starY - verticalOffset,
      child: FractionalTranslation(
        translation: Offset(horizontalTranslation, 0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxLabelWidth,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: FontScaling.getResponsiveSpacing(context, 12),
            vertical: FontScaling.getResponsiveSpacing(context, 8),
          ),
          decoration: BoxDecoration(
            color: Color(0xFF1A2238).withValues(alpha: labelBackgroundAlpha),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: star.color.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: star.color.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxLabelWidth - FontScaling.getResponsiveSpacing(context, 24),
              ),
              child: Text(
                star.text,
                style: FontScaling.getBodySmall(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  final TextEditingController _editTextController = TextEditingController();
  final TextEditingController _hexColorController = TextEditingController();
  final TextEditingController _redController = TextEditingController();
  final TextEditingController _greenController = TextEditingController();
  final TextEditingController _blueController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  List<GratitudeStar> gratitudeStars = [];
  List<OrganicNebulaRegion> _organicNebulaRegions = [];
  late AnimationController _backgroundController;
  late AnimationController _starController;
  late CameraController _cameraController;
  bool _isLoading = true;
  bool _showBranding = true;
  bool _isAnimating = false;
  bool _isAppInBackground = false;
  AnimationController? _birthController;
  GratitudeStar? _animatingStar;
  final math.Random _random = math.Random();
  DateTime? _lastScrollTime;
  List<VanGoghStar> _vanGoghStars = [];
  List<BackgroundStar> _staticStars = [];
  List<Paint> _glowPatterns = [];
  List<Paint> _backgroundGradients = [];
  bool _showAllGratitudes = false;
  bool _mindfulnessMode = false;
  int _mindfulnessInterval = 3;
  Timer? _mindfulnessTimer;
  GratitudeStar? _activeMindfulnessStar;
  final String _userName = "A friend";
  bool _isEditMode = false;
  Color? _previewColor;
  Color? _tempColorPreview;  // Temporary color during editing
  int? _tempColorIndexPreview;  // Temporary index during editing
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
      duration: Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _starController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _birthController = AnimationController(
      duration: Duration(milliseconds: 1500),
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

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showBranding = false;
        });
      }
    });
  }

  void _initializePrecomputedElements() {
    print('🌟 Starting initialization...');

    _glowPatterns = GratitudeStarService.generateGlowPatterns();
    print('✨ Generated ${_glowPatterns.length} glow patterns');

    _backgroundGradients = BackgroundService.generateBackgroundGradients();
    print('🎨 Generated ${_backgroundGradients.length} background gradients');
  }

  Future<void> _loadGratitudes() async {
    print('💾 Loading gratitudes...');
    final stars = await StorageService.loadGratitudeStars();

    if (mounted) {
      setState(() {
        gratitudeStars = stars;
        _isLoading = false;
        print('🎯 Loaded ${stars.length} gratitude stars, _isLoading = false');
      });

      // If user is signed in with email, sync with cloud AFTER local load
      if (_authService.hasEmailAccount) {
        print('🔄 User has email account, starting cloud sync...');
        await _syncWithCloud();
      }
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
    _authSubscription?.cancel();  // ADD THIS LINE
    _cameraController.dispose();
    _backgroundController.dispose();
    _starController.dispose();
    _gratitudeController.dispose();
    _editTextController.dispose();
    _hexColorController.dispose();
    _redController.dispose();
    _greenController.dispose();
    _blueController.dispose();
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

  void _showStarDetails(GratitudeStar star) {
    final starId = star.id; // Store the ID, not the star reference

    setState(() {
      _isEditMode = false;
      _editTextController.text = star.text;
    });

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Look up the current star by ID on every rebuild
            var currentStar = gratitudeStars.firstWhere(
                  (s) => s.id == starId,
              orElse: () => star, // Fallback to original if somehow deleted
            );

            // Apply temporary color preview if exists
            if (_tempColorPreview != null || _tempColorIndexPreview != null) {
              print('DEBUG EDIT MODAL: Applying temp color - _tempColorPreview: $_tempColorPreview, _tempColorIndexPreview: $_tempColorIndexPreview');
              if (_tempColorIndexPreview != null) {
                // Preset color preview
                currentStar = currentStar.copyWith(
                  colorIndex: _tempColorIndexPreview,
                  clearCustomColor: true,
                );
              } else {
                // Custom color preview
                currentStar = currentStar.copyWith(
                  customColor: _tempColorPreview,
                );
              }
            } else {
              print('DEBUG EDIT MODAL: No temp color to apply');
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                decoration: BoxDecoration(
                  color: Color(0xFF1A2238).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: currentStar.color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icon_star.svg',
                      width: FontScaling.getResponsiveIconSize(context, 48),
                      height: FontScaling.getResponsiveIconSize(context, 48),
                      colorFilter: ColorFilter.mode(currentStar.color, BlendMode.srcIn),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                    // Text display or edit mode
                    if (!_isEditMode)
                      Text(
                        currentStar.text,
                        style: FontScaling.getBodyLarge(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      TextField(
                        controller: _editTextController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.editGratitudeHint,
                          hintStyle: FontScaling.getInputHint(context),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFFFE135).withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        style: FontScaling.getInputText(context),
                        maxLines: 4,
                      ),

                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),

                    // Action buttons
                    if (!_isEditMode)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GratitudeDialogs.buildModalIconButton(
                            context: context,
                            icon: Icons.edit,
                            label: AppLocalizations.of(context)!.editButton,
                            onTap: () {
                              setState(() {
                                _isEditMode = true;
                              });
                            },
                          ),
                          GratitudeDialogs.buildModalIconButton(
                            context: context,
                            icon: Icons.share,
                            label: AppLocalizations.of(context)!.shareButton,
                            onTap: () => _shareStar(currentStar),
                          ),
                          GratitudeDialogs.buildModalIconButton(
                            context: context,
                            icon: Icons.close,
                            label: AppLocalizations.of(context)!.closeButton,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _showColorPicker(currentStar, setState);
                            },
                            icon: Icon(Icons.palette, size: FontScaling.getResponsiveIconSize(context, 20)),
                            label: Text(
                              AppLocalizations.of(context)!.changeColorButton,
                              style: FontScaling.getButtonText(context),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFE135).withValues(alpha: 0.2),
                              foregroundColor: Color(0xFFFFE135),
                              minimumSize: Size(double.infinity, 48),
                              padding: EdgeInsets.symmetric(
                                horizontal: FontScaling.getResponsiveSpacing(context, 20),
                                vertical: FontScaling.getResponsiveSpacing(context, 12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  GratitudeDialogs.showDeleteConfirmation(
                                    context: context,
                                    modalContext: context,
                                    star: currentStar,
                                    onDelete: _deleteStar,
                                  );
                                },
                                icon: Icon(Icons.close, size: FontScaling.getResponsiveIconSize(context, 18)),
                                label: Text(
                                  AppLocalizations.of(context)!.deleteButton,
                                  style: FontScaling.getButtonText(context),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: FontScaling.getResponsiveSpacing(context, 16),
                                    vertical: FontScaling.getResponsiveSpacing(context, 10),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                              SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditMode = false;
                                    _editTextController.text = currentStar.text;
                                    // Clear temp color previews when canceling edit
                                    _tempColorPreview = null;
                                    _tempColorIndexPreview = null;
                                  });
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.cancelButton,
                                  style: FontScaling.getButtonText(context).copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                              ElevatedButton(
                                onPressed: () {
                                  _saveStarEdits(currentStar);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFFE135),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: FontScaling.getResponsiveSpacing(context, 20),
                                    vertical: FontScaling.getResponsiveSpacing(context, 12),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.saveButton,
                                  style: FontScaling.getButtonText(context).copyWith(
                                    color: Color(0xFF1A2238),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clean up when dialog closes
      setState(() {
        _isEditMode = false;
        _tempColorPreview = null;  // Clear temp preview
        _tempColorIndexPreview = null;  // Clear temp preview
      });
    });
  }

  void _shareStar(GratitudeStar star) {
    HapticFeedback.mediumImpact();
    final shareText = '$_userName shared their gratitude with you:\n${star.text}\n\n- GratiStellar - your universe of thankfulness';
    SharePlus.instance.share(
        ShareParams(text: shareText)
    );
  }

  void _saveStarEdits(GratitudeStar star) {
    final index = gratitudeStars.indexWhere((s) => s.id == star.id);
    if (index != -1) {
      HapticFeedback.mediumImpact();
      setState(() {
        var updatedStar = star.copyWith(
          text: _editTextController.text,
        );

        // Apply temporary color changes if any
        if (_tempColorIndexPreview != null) {
          updatedStar = updatedStar.copyWith(
            colorIndex: _tempColorIndexPreview,
            clearCustomColor: true,
          );
        } else if (_tempColorPreview != null) {
          updatedStar = updatedStar.copyWith(
            customColor: _tempColorPreview,
          );
        }

        gratitudeStars[index] = updatedStar;

        // Clear temporary preview
        _tempColorPreview = null;
        _tempColorIndexPreview = null;
      });
      _saveGratitudes();

      // Sync to cloud if signed in
      if (_authService.hasEmailAccount) {
        _firestoreService.updateStar(gratitudeStars[index]).catchError((e) {
          print('⚠️ Failed to sync star edit to cloud: $e');
        });
      }
    }
  }

  void _deleteStar(GratitudeStar star) {
    HapticFeedback.heavyImpact();

    final starId = star.id; // Save ID before removing

    setState(() {
      gratitudeStars.removeWhere((s) => s.id == star.id);
    });
    _saveGratitudes();

    // Sync deletion to cloud if signed in
    if (_authService.hasEmailAccount) {
      _firestoreService.deleteStar(starId).catchError((e) {
        print('⚠️ Failed to sync star deletion to cloud: $e');
      });
    }
  }

  void _showColorPicker(GratitudeStar star, StateSetter modalSetState) {
    // Initialize preview color and controllers
    _previewColor = star.color;
    final currentColor = star.color;
    final r = (currentColor.r * 255).round();
    final g = (currentColor.g * 255).round();
    final b = (currentColor.b * 255).round();
    _hexColorController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    _redController.text = r.toString();
    _greenController.text = g.toString();
    _blueController.text = b.toString();

    int? selectedColorIndex = star.customColor == null ? star.colorIndex : null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateColorPicker) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
                decoration: BoxDecoration(
                  color: Color(0xFF1A2238).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(0xFFFFE135).withValues(alpha: 0.3),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Live preview star
                      Text(
                        AppLocalizations.of(context)!.colorPreviewTitle,
                        style: FontScaling.getModalTitle(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                      Container(
                        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SvgPicture.asset(  // ADD 'child:' here
                          'assets/icon_star.svg',
                          width: FontScaling.getResponsiveIconSize(context, 64),
                          height: FontScaling.getResponsiveIconSize(context, 64),
                          colorFilter: ColorFilter.mode(_previewColor!, BlendMode.srcIn),
                        ),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                      // Color grid
                      Text(
                        AppLocalizations.of(context)!.presetColorsTitle,
                        style: FontScaling.getBodyMedium(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                      _buildColorGrid(selectedColorIndex ?? -1, (index) {
                        setStateColorPicker(() {
                          selectedColorIndex = index;
                          _previewColor = StarColors.getColor(index);
                          final color = StarColors.getColor(index);
                          final r = (color.r * 255).round();
                          final g = (color.g * 255).round();
                          final b = (color.b * 255).round();
                          _hexColorController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                          _redController.text = r.toString();
                          _greenController.text = g.toString();
                          _blueController.text = b.toString();
                        });
                      }),

                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                      // Custom color section
                      Text(
                        AppLocalizations.of(context)!.customColorTitle,
                        style: FontScaling.getBodyMedium(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                      // Hex input
                      TextField(
                        controller: _hexColorController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.hexColorLabel,
                          hintText: AppLocalizations.of(context)!.hexColorHint,
                          hintStyle: FontScaling.getInputHint(context),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: FontScaling.getInputText(context),
                        onChanged: (value) {
                          // Auto-add # if missing
                          String hexValue = value;
                          if (!hexValue.startsWith('#') && hexValue.length >= 6) {
                            hexValue = '#$hexValue';
                            _hexColorController.value = TextEditingValue(
                              text: hexValue,
                              selection: TextSelection.collapsed(offset: hexValue.length),
                            );
                          }

                          if (hexValue.length == 7 && hexValue.startsWith('#')) {
                            try {
                              final color = Color(int.parse(hexValue.substring(1), radix: 16) + 0xFF000000);
                              setStateColorPicker(() {
                                _previewColor = color;
                                selectedColorIndex = null;
                                _redController.text = ((color.r * 255).round()).toString();
                                _greenController.text = ((color.g * 255).round()).toString();
                                _blueController.text = ((color.b * 255).round()).toString();
                              });
                            } catch (e) {
                              // Invalid hex input
                            }
                          }
                        },
                      ),

                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                      // RGB inputs
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _redController,
                              decoration: InputDecoration(
                                labelText: 'R',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: FontScaling.getInputText(context),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                try {
                                  final r = int.parse(_redController.text).clamp(0, 255);
                                  final g = int.parse(_greenController.text).clamp(0, 255);
                                  final b = int.parse(_blueController.text).clamp(0, 255);

                                  final color = Color.fromARGB(255, r, g, b);
                                  setStateColorPicker(() {
                                    _previewColor = color;
                                    selectedColorIndex = null;
                                    _hexColorController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                                  });
                                } catch (e) {
                                  // Invalid RGB input
                                }
                              },
                            ),
                          ),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: TextField(
                              controller: _greenController,
                              decoration: InputDecoration(
                                labelText: 'G',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: FontScaling.getInputText(context),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                try {
                                  final r = int.parse(_redController.text).clamp(0, 255);
                                  final g = int.parse(_greenController.text).clamp(0, 255);
                                  final b = int.parse(_blueController.text).clamp(0, 255);

                                  final color = Color.fromARGB(255, r, g, b);
                                  setStateColorPicker(() {
                                    _previewColor = color;
                                    selectedColorIndex = null;
                                    _hexColorController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                                  });
                                } catch (e) {
                                  // Invalid RGB input
                                }
                              },
                            ),
                          ),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: TextField(
                              controller: _blueController,
                              decoration: InputDecoration(
                                labelText: 'B',
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: FontScaling.getInputText(context),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                try {
                                  final r = int.parse(_redController.text).clamp(0, 255);
                                  final g = int.parse(_greenController.text).clamp(0, 255);
                                  final b = int.parse(_blueController.text).clamp(0, 255);

                                  final color = Color.fromARGB(255, r, g, b);
                                  setStateColorPicker(() {
                                    _previewColor = color;
                                    selectedColorIndex = null;
                                    _hexColorController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                                  });
                                } catch (e) {
                                  // Invalid RGB input
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              AppLocalizations.of(context)!.cancelButton,
                              style: FontScaling.getButtonText(context).copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Only apply changes when Apply is clicked
                              _applyColorChange(star, selectedColorIndex, modalSetState);
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFE135),
                              padding: EdgeInsets.symmetric(
                                horizontal: FontScaling.getResponsiveSpacing(context, 24),
                                vertical: FontScaling.getResponsiveSpacing(context, 12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.applyButton,
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
            );
          },
        );  // ← Close StatefulBuilder
      },  // ← Close showDialog builder function
    ).then((result) {
      print('DEBUG COLOR PICKER CLOSED: result = $result');
      // Clear temp colors if dialog was closed without clicking Apply
      if (result != true) {
        print('DEBUG: Clearing temp colors');
        setState(() {
          _tempColorPreview = null;
          _tempColorIndexPreview = null;
        });
        modalSetState(() {});  // Refresh edit modal
      }
    });
  }  // ← Close _showColorPicker method

  Widget _buildColorGrid(int selectedIndex, Function(int) onColorTap) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
        mainAxisSpacing: FontScaling.getResponsiveSpacing(context, 8),
      ),
      itemCount: StarColors.palette.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onColorTap(index),
          child: Container(
            decoration: BoxDecoration(
              color: StarColors.palette[index],
              shape: BoxShape.circle,
              border: isSelected ? Border.all(
                color: Colors.white,
                width: 3,
              ) : null,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: StarColors.palette[index].withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: isSelected ? Icon(
              Icons.check,
              color: Colors.white,
              size: FontScaling.getResponsiveIconSize(context, 16),
            ) : null,
          ),
        );
      },
    );
  }

  void _updateFromRGB(StateSetter setState) {
    try {
      final r = int.parse(_redController.text).clamp(0, 255);
      final g = int.parse(_greenController.text).clamp(0, 255);
      final b = int.parse(_blueController.text).clamp(0, 255);

      final color = Color.fromARGB(255, r, g, b);
      setState(() {
        _previewColor = color;
        _hexColorController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
      });
    } catch (e) {
      // Invalid RGB input
    }
  }

  void _applyColorChange(GratitudeStar star, int? colorIndex, StateSetter modalSetState) {
    // Store temporarily - don't commit to gratitudeStars yet
    if (colorIndex != null) {
      _tempColorIndexPreview = colorIndex;
      _tempColorPreview = null;  // Clear custom color
    } else {
      _tempColorPreview = _previewColor;
      _tempColorIndexPreview = null;
    }

    // Trigger modal rebuild to show new color in edit modal icon
    modalSetState(() {});
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
    final targetPosition = Offset(
      screenSize.width / 2 - starWorldX * targetScale,
      screenSize.height / 2 - starWorldY * targetScale,
    );

    print('🧘 Target camera position: $targetPosition');

    _cameraController.animateTo(
      targetPosition: targetPosition,
      targetScale: targetScale,
      duration: Duration(milliseconds: mindfulnessTransitionMs),
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
    final starId = star.id; // Store the ID, not the star reference

    setState(() {
      _isEditMode = false;
      _editTextController.text = star.text;
    });

    GratitudeDialogs.showStarDetailsWithJump(
      context: context,
      star: star,
      starId: starId,  // Pass the star ID
      gratitudeStars: gratitudeStars,  // Pass the list for lookup
      editTextController: _editTextController,
      hexColorController: _hexColorController,
      redController: _redController,
      greenController: _greenController,
      blueController: _blueController,
      onShowColorPicker: _showColorPicker,
      onSaveEdits: _saveStarEdits,
      onDelete: _deleteStar,
      onShare: _shareStar,
      onJumpToStar: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _jumpToStar(star);
      },
      onListRefresh: refreshList,
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
        size: FontScaling.getResponsiveIconSize(context, 28) * universalUIScale,
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
                  width: FontScaling.getResponsiveIconSize(context, 48) * universalUIScale,
                  height: FontScaling.getResponsiveIconSize(context, 48) * universalUIScale,
                  colorFilter: ColorFilter.mode(Color(0xFFFFE135), BlendMode.srcIn),
                ),
                SizedBox(width: FontScaling.getResponsiveSpacing(context, 16)),
                Expanded(
                  child: Text(
                    l10n.appTitle,
                    style: FontScaling.getHeadingMedium(context).copyWith(
                      fontSize: FontScaling.getHeadingMedium(context).fontSize! * universalUIScale,
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
              size: FontScaling.getResponsiveIconSize(context, 24) * universalUIScale,
            ),
            title: Text(
              _authService.hasEmailAccount
                  ? l10n.accountMenuItem
                  : l10n.signInWithEmailMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
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
              size: FontScaling.getResponsiveIconSize(context, 24) * universalUIScale,
            ),
            title: Text(
              l10n.listViewMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
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

          // Exit
          ListTile(
            leading: Icon(
              Icons.close,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * universalUIScale,
            ),
            title: Text(
              l10n.exitButton,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              GratitudeDialogs.showQuitConfirmation(context);
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
        width: FontScaling.getResponsiveSpacing(context, 70) * universalUIScale,
        height: FontScaling.getResponsiveSpacing(context, 70) * universalUIScale,
        decoration: BoxDecoration(
          color: _isAnimating
              ? Color(0xFFFFE135).withValues(alpha: 0.5)
              : Color(0xFFFFE135),
          borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 35) * universalUIScale),
          boxShadow: _isAnimating ? [] : [
            BoxShadow(
              color: Color(0xFFFFE135).withValues(alpha: 0.4),
              blurRadius: 20 * universalUIScale,
              spreadRadius: 5 * universalUIScale,
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icon_star.svg',
            width: FontScaling.getResponsiveSpacing(context, 56) * universalUIScale,
            height: FontScaling.getResponsiveSpacing(context, 56) * universalUIScale,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Bottom row UI buttons
  Widget _buildBottomButtonRow() {
    // Calculate button row dimensions
    final buttonSize = FontScaling.getResponsiveSpacing(context, 56) * universalUIScale;
    final spacing = FontScaling.getResponsiveSpacing(context, 16) * universalUIScale;
    final addStarSize = FontScaling.getResponsiveSpacing(context, 70) * universalUIScale;

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
            height: FontScaling.getResponsiveSpacing(context, 12) * universalUIScale,
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
                      height: FontScaling.getResponsiveSpacing(context, 12) * universalUIScale,
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
        horizontal: FontScaling.getResponsiveSpacing(context, 16) * universalUIScale,
        vertical: FontScaling.getResponsiveSpacing(context, 12) * universalUIScale,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1A2238).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20 * universalUIScale),
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
              fontSize: FontScaling.getBodySmall(context).fontSize! * universalUIScale,
            ),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8) * universalUIScale),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Color(0xFFFFE135),
              inactiveTrackColor: Color(0xFFFFE135).withValues(alpha: 0.3),
              thumbColor: Color(0xFFFFE135),
              overlayColor: Color(0xFFFFE135).withValues(alpha: 0.2),
              trackHeight: 4 * universalUIScale,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 12 * universalUIScale,  // Larger thumb for mobile
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: 24 * universalUIScale,  // Larger tap target
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
        width: FontScaling.getResponsiveSpacing(context, 56) * universalUIScale,
        height: FontScaling.getResponsiveSpacing(context, 56) * universalUIScale,
        decoration: BoxDecoration(
          color: isActive
              ? Color(0xFFFFE135).withValues(alpha: 0.9)
              : Color(0xFF1A2238).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 28) * universalUIScale),
          border: Border.all(
            color: Color(0xFFFFE135).withValues(alpha: isActive ? 1.0 : 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Color(0xFF1A2238) : Colors.white.withValues(alpha: 0.8),
          size: FontScaling.getResponsiveIconSize(context, 24) * universalUIScale,
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
          size: FontScaling.getResponsiveIconSize(context, 20) * universalUIScale,
        ),
        SizedBox(height: FontScaling.getResponsiveSpacing(context, 4) * universalUIScale),
        Text(
          label,
          style: FontScaling.getStatsLabel(context).copyWith(
            fontSize: FontScaling.getStatsLabel(context).fontSize! * statsLabelTextScale,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: FontScaling.getStatsNumber(context).copyWith(
              fontSize: FontScaling.getStatsNumber(context).fontSize! * universalUIScale,
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

            // Layer 3: Interactive starfield
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
                  onScaleStart: _isAnimating ? null : (details) {
                    if (_mindfulnessMode) {
                      _stopMindfulnessMode();
                      setState(() {
                        _mindfulnessMode = false;
                      });
                    }
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
                        // Dampen the scale change to make it less sensitive
                        // Instead of applying full scale change, only apply a fraction
                        final dampingFactor = 0.25;  // Adjust this (0.1 = very slow, 1.0 = full speed)
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
                  onScaleEnd: _isAnimating ? null : (details) {},
                  onTapDown: _isAnimating ? null : (details) => _handleStarTap(details),
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
                          // Floating labels layer
                          Transform(
                            transform: _cameraController.transform,
                            child: Stack(
                              children: [
                                // Show all gratitudes mode
                                if (_showAllGratitudes)
                                  ...gratitudeStars.map((star) {
                                    return FloatingGratitudeLabel(
                                      star: star,
                                      screenSize: currentSize,
                                      cameraScale: _cameraController.scale,  // ADD
                                      cameraPosition: _cameraController.position,  // ADD
                                    );
                                  }),

                                // Mindfulness mode - single star with animated transitions
                                if (_mindfulnessMode && _activeMindfulnessStar != null)
                                  AnimatedPositioned(
                                    duration: Duration(milliseconds: mindfulnessTransitionMs),
                                    curve: Curves.easeInOutCubic,
                                    left: _activeMindfulnessStar!.worldX * currentSize.width,
                                    top: _activeMindfulnessStar!.worldY * currentSize.height - 70.0,
                                    child: FractionalTranslation(
                                      translation: Offset(-0.5, 0),
                                      child: AnimatedSwitcher(
                                        duration: Duration(milliseconds: 800),
                                        child: Container(
                                          key: ValueKey(_activeMindfulnessStar!.id),
                                          constraints: BoxConstraints(maxWidth: currentSize.width * 0.4),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: FontScaling.getResponsiveSpacing(context, 12),
                                            vertical: FontScaling.getResponsiveSpacing(context, 8),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF1A2238).withValues(alpha: labelBackgroundAlpha),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _activeMindfulnessStar!.color.withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _activeMindfulnessStar!.color.withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _activeMindfulnessStar!.text,
                                            style: FontScaling.getBodySmall(context).copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
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
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: FontScaling.getAppTitle(context).copyWith(
                            fontSize: FontScaling.getAppTitle(context).fontSize! * universalUIScale,
                          ),
                        ),
                        SizedBox(height: FontScaling.getResponsiveSpacing(context, 16) * universalUIScale),
                        Text(
                          AppLocalizations.of(context)!.appSubtitle,
                          style: FontScaling.getSubtitle(context).copyWith(
                            fontSize: FontScaling.getSubtitle(context).fontSize! * universalUIScale,
                          ),
                        ),
                      ],
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
                      horizontal: FontScaling.getResponsiveSpacing(context, 20) * universalUIScale,
                      vertical: FontScaling.getResponsiveSpacing(context, 12) * universalUIScale,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A2238).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20 * universalUIScale),
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
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20) * universalUIScale),
                          _buildStatItem(Icons.trending_up, AppLocalizations.of(context)!.statsThisWeek, StorageService.getThisWeekStars(gratitudeStars).toString()),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20) * universalUIScale),
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
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icon_star.svg',
                        width: FontScaling.getResponsiveIconSize(context, 64) * universalUIScale,
                        height: FontScaling.getResponsiveIconSize(context, 64) * universalUIScale,
                        colorFilter: ColorFilter.mode(Colors.white.withValues(alpha: 0.3), BlendMode.srcIn),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24) * universalUIScale),
                      Text(
                        AppLocalizations.of(context)!.emptyStateTitle,
                        style: FontScaling.getEmptyStateTitle(context).copyWith(
                          fontSize: FontScaling.getEmptyStateTitle(context).fontSize! * universalUIScale,
                        ),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12) * universalUIScale),
                      Text(
                        AppLocalizations.of(context)!.emptyStateSubtitle,
                        style: FontScaling.getEmptyStateSubtitle(context).copyWith(
                          fontSize: FontScaling.getEmptyStateSubtitle(context).fontSize! * universalUIScale,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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