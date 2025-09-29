import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';  // Add this line
import 'package:vector_math/vector_math_64.dart' show Vector4, Matrix4;
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

void main() async {
  print('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('📦 Loading textures...');
  await BackgroundService.loadTextures(); // Load background textures
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
      // Add localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish (add more languages as needed)
        Locale('fr'), // French
      ],
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'serif',
        // Set default text theme for consistency
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontSize: 22.0, // Your requested default for large screens
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      home: GratitudeScreen(),
    );
  }
}

class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen>
    with TickerProviderStateMixin {
  // Layer parallax configuration
  final TextEditingController _gratitudeController = TextEditingController();
  List<GratitudeStar> gratitudeStars = [];
  List<OrganicNebulaRegion> _organicNebulaRegions = [];
  late AnimationController _backgroundController;
  late AnimationController _starController;
  late CameraController _cameraController;
  bool _isLoading = true;
  bool _showBranding = true;
  final math.Random _random = math.Random();
  DateTime? _lastScrollTime;
  List<VanGoghStar> _vanGoghStars = [];
  List<BackgroundStar> _staticStars = [];
  List<Paint> _glowPatterns = [];
  List<Paint> _backgroundGradients = [];
  Size? _lastVanGoghSize;
  Size? _lastNebulaSize;
  Size? _lastBackgroundSize;

  @override
  void initState() {
    print('🎬 GratitudeScreen initState starting...');
    super.initState();

    _cameraController = CameraController();

    _backgroundController = AnimationController(
      duration: Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _starController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();

    print('🎭 Animation controllers created');

    try {
      _initializePrecomputedElements();
      print('✅ Precomputed elements initialized');
      _organicNebulaRegions = OrganicNebulaService.generateOrganicNebulae(Size(800, 600));
    } catch (e) {
      print('❌ Error in initialization: $e');
    }

    _loadGratitudes();

    // Hide branding after 3 seconds
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

    // Add VanGogh stars generation with placeholder size
    _vanGoghStars = VanGoghStarService.generateVanGoghStars(Size(800, 600));
    print('🌌 Generated ${_vanGoghStars.length} Van Gogh stars');
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
    }
  }

  Future<void> _saveGratitudes() async {
    await StorageService.saveGratitudeStars(gratitudeStars);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _backgroundController.dispose();
    _starController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  void _addGratitude() async {
    if (_gratitudeController.text.isNotEmpty) {
      final screenSize = MediaQuery.of(context).size;
      final newStar = GratitudeStarService.createStar(
        _gratitudeController.text,
        screenSize,
        _random,
        gratitudeStars, // Pass existing stars for overlap prevention
      );

      if (mounted) {
        setState(() {
          gratitudeStars.add(newStar);
          _gratitudeController.clear();
        });
      }
      await _saveGratitudes();
    }
  }

  void _showAddGratitudeModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.createStarModalTitle,
                  style: FontScaling.getModalTitle(context),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 20)),
                TextField(
                  controller: _gratitudeController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.createStarHint,
                    hintStyle: FontScaling.getInputHint(context),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135).withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Color(0xFFFFE135),
                        width: 2,
                      ),
                    ),
                  ),
                  style: FontScaling.getInputText(context),
                  maxLines: 4,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        _gratitudeController.clear();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        AppLocalizations.of(context)!.cancelButton,
                        style: FontScaling.getButtonText(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _addGratitude();
                        Navigator.of(context).pop();
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
                        AppLocalizations.of(context)!.createStarButton,
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
        );
      },
    );
  }

  void _showStarDetails(GratitudeStar star) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: Color(0xFF1A2238).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: StarColors.getColor(star.colorIndex).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: StarColors.getColor(star.colorIndex),
                  size: FontScaling.getResponsiveIconSize(context, 32),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Text(
                  star.text,
                  style: FontScaling.getBodyLarge(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 20)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.closeButton,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: StarColors.getColor(star.colorIndex),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building GratitudeScreen, _isLoading: $_isLoading, stars: ${_staticStars.length}');

    // Regenerate nebula regions with actual screen size (only when screen size changes)
    final currentSize = MediaQuery.of(context).size;
    if (_organicNebulaRegions.isEmpty || _lastNebulaSize != currentSize) {
      _organicNebulaRegions = OrganicNebulaService.generateOrganicNebulae(currentSize);
      _lastNebulaSize = currentSize;
    }

    if (_vanGoghStars.isEmpty || _lastVanGoghSize != currentSize) {
      _vanGoghStars = VanGoghStarService.generateVanGoghStars(currentSize);
      _lastVanGoghSize = currentSize;
      print('🌌 Regenerated ${_vanGoghStars.length} Van Gogh stars for new screen size');
    }

    if (_staticStars.isEmpty || _lastBackgroundSize != currentSize) {
      _staticStars = BackgroundService.generateStaticStars(currentSize);
      _lastBackgroundSize = currentSize;
      print('⭐ Regenerated ${_staticStars.length} background stars for size $currentSize');
    }

    if (_isLoading) {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFFE135),
                  size: FontScaling.getResponsiveIconSize(context, 48),
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
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [

            // Layer 1: Static background with subtle parallax
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

            // Layer 2: Nebula with moderate parallax
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

            // Layer 2.5: Van Gogh stars with stronger parallax
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

            // Layer 3: Screen-level camera controls with secondary star interaction
                      Positioned.fill(
                        child: Listener(
                          // Screen-level zoom (highest priority - works anywhere)
                          onPointerSignal: (pointerSignal) {
                            if (pointerSignal is PointerScrollEvent) {
                              final now = DateTime.now();
                              if (_lastScrollTime != null && now.difference(_lastScrollTime!).inMilliseconds < 16) {
                                return; // Throttle to ~60fps
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
                            // Screen-level pan (high priority - works anywhere)
                            onPanStart: (details) {
                              // Camera pan start
                            },
                            onPanUpdate: (details) {
                              _cameraController.updatePosition(details.delta);
                            },
                            onPanEnd: (details) {
                              // Camera pan end
                            },

                            // Star tap detection (lower priority - doesn't interfere with camera)
                            onTapDown: (details) => _handleStarTap(details),

                            child: AnimatedBuilder(
                              animation: _cameraController,
                              builder: (context, child) {
                                return Transform(
                                  transform: _cameraController.transform,
                                  child: StarfieldCanvas(
                                    stars: gratitudeStars,
                                    animationController: _starController,
                                    glowPatterns: _glowPatterns,
                                  ),
                                );
                    },
                  ),
                ),
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
                          style: FontScaling.getAppTitle(context),
                        ),
                        SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                        Text(
                          AppLocalizations.of(context)!.appSubtitle,
                          style: FontScaling.getSubtitle(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

// Stats card at top
            if (!_showBranding)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: FontScaling.getResponsiveSpacing(context, 20),
                      vertical: FontScaling.getResponsiveSpacing(context, 12),
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A2238).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
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
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20)),
                          _buildStatItem(Icons.trending_up, AppLocalizations.of(context)!.statsThisWeek, StorageService.getThisWeekStars(gratitudeStars).toString()),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 20)),
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

            // Add gratitude button
            if (!_showBranding)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _showAddGratitudeModal,
                    child: Container(
                      width: FontScaling.getResponsiveSpacing(context, 70),
                      height: FontScaling.getResponsiveSpacing(context, 70),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE135),
                        borderRadius: BorderRadius.circular(FontScaling.getResponsiveSpacing(context, 35)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFE135).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: Color(0xFF1A2238),
                        size: FontScaling.getResponsiveIconSize(context, 32),
                      ),
                    ),
                  ),
                ),
              ),

            // Empty state message
            if (!_showBranding && gratitudeStars.isEmpty)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: FontScaling.getResponsiveIconSize(context, 64),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
                      Text(
                        AppLocalizations.of(context)!.emptyStateTitle,
                        style: FontScaling.getEmptyStateTitle(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                      Text(
                        AppLocalizations.of(context)!.emptyStateSubtitle,
                        style: FontScaling.getEmptyStateSubtitle(context),
                      ),
                    ],
                  ),
                ),
              ),
            // Camera controls overlay (add this after your existing overlays)
            if (!_showBranding)
              CameraControlsOverlay(
                cameraController: _cameraController,
                stars: gratitudeStars,
                screenSize: MediaQuery.of(context).size,
                vsync: this,
              ),],
        ),
      ),
    );
  }

  void _handleStarTap(TapDownDetails details) {
    final screenSize = MediaQuery.of(context).size;

    // Use the new hit tester with camera-aware coordinates
    final tappedStar = StarHitTester.findStarAtScreenPosition(
      details.localPosition,
      gratitudeStars,
      screenSize,
      cameraPosition: _cameraController.position,
      cameraScale: _cameraController.scale,
    );

    if (tappedStar != null) {
      _showStarDetails(tappedStar);
    }
    // If no star found, tap does nothing (camera controls already handled)
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Color(0xFFFFE135),
          size: FontScaling.getResponsiveIconSize(context, 20),
        ),
        SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
        Text(
          label,
          style: FontScaling.getStatsLabel(context),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: FontScaling.getStatsNumber(context),
          ),
      ],
    );
  }
}