import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'; // Added for SystemNavigator.pop()
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
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

// Floating label widget for displaying gratitude text
class FloatingGratitudeLabel extends StatelessWidget {
  final GratitudeStar star;
  final Size screenSize;

  const FloatingGratitudeLabel({
    super.key,
    required this.star,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    // Convert normalized world coordinates to screen pixels
    final starX = star.worldX * screenSize.width;
    final starY = star.worldY * screenSize.height;

    // Position label to the right of the star with some offset
    final labelOffset = Offset(starX + 20, starY - 10);

    return Positioned(
      left: labelOffset.dx,
      top: labelOffset.dy,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.3, // 30% max width
        ),
        padding: EdgeInsets.symmetric(
          horizontal: FontScaling.getResponsiveSpacing(context, 12),
          vertical: FontScaling.getResponsiveSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: Color(0xFF1A2238).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: StarColors.getColor(star.colorIndex).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: StarColors.getColor(star.colorIndex).withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          star.text,
          style: FontScaling.getBodySmall(context).copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

void main() async {
  print('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();
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
            fontSize: 22.0,
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
  // ========================================
  // UI SCALE CONFIGURATION
  // ========================================
  static const double universalUIScale = 0.75;          // Universal scale for top/bottom UI (new 100% baseline)
  static const double labelBackgroundAlpha = 0.85;      // Floating label transparency
  static const double statsLabelTextScale = 1.15;       // Stats bar label text boost (15% larger than base)

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _gratitudeController = TextEditingController();
  List<GratitudeStar> gratitudeStars = [];
  List<OrganicNebulaRegion> _organicNebulaRegions = [];
  late AnimationController _backgroundController;
  late AnimationController _starController;
  late CameraController _cameraController;
  bool _isLoading = true;
  bool _showBranding = true;
  bool _isAnimating = false;
  AnimationController? _birthController;
  GratitudeStar? _animatingStar;
  final math.Random _random = math.Random();
  DateTime? _lastScrollTime;
  List<VanGoghStar> _vanGoghStars = [];
  List<BackgroundStar> _staticStars = [];
  List<Paint> _glowPatterns = [];
  List<Paint> _backgroundGradients = [];
  Size? _lastVanGoghSize;
  Size? _lastNebulaSize;
  Size? _lastBackgroundSize;
  bool _showAllGratitudes = false;
  bool _mindfulnessMode = false;
  int _mindfulnessInterval = 5;
  Timer? _mindfulnessTimer;
  GratitudeStar? _activeMindfulnessStar;

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

    try {
      _initializePrecomputedElements();
      print('✅ Precomputed elements initialized');
      _organicNebulaRegions = OrganicNebulaService.generateOrganicNebulae(Size(800, 600));
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
    _birthController?.dispose();
    _mindfulnessTimer?.cancel();
    super.dispose();
  }

  void _addGratitude() async {
    if (_gratitudeController.text.isEmpty) return;

    final screenSize = MediaQuery.of(context).size;
    final newStar = GratitudeStarService.createStar(
      _gratitudeController.text,
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
      setState(() {
        gratitudeStars.add(_animatingStar!);
        _animatingStar = null;
        _isAnimating = false;
      });
      _saveGratitudes();
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

  void _showAddGratitudeModal() {
    if (_isAnimating) return;

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
      _showStarDetails(tappedStar);
    }
  }

  // Toggle methods
  void _toggleShowAll() {
    setState(() {
      _showAllGratitudes = !_showAllGratitudes;
    });
  }

  void _toggleMindfulness() {
    setState(() {
      _mindfulnessMode = !_mindfulnessMode;
    });

    if (_mindfulnessMode) {
      _startMindfulnessMode();
    } else {
      _stopMindfulnessMode();
    }
  }

  void _startMindfulnessMode() {
    // TODO: Implement in Phase 4
    print('Mindfulness mode started');
  }

  void _stopMindfulnessMode() {
    _mindfulnessTimer?.cancel();
    _mindfulnessTimer = null;
    _activeMindfulnessStar = null;
    print('Mindfulness mode stopped');
  }

  // Phase 3: Dialog methods
  void _showComingSoonDialog(String feature) {
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
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFFFE135),
                  size: FontScaling.getResponsiveIconSize(context, 48),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Text(
                  feature,
                  style: FontScaling.getModalTitle(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Text(
                  'Coming Soon',
                  style: FontScaling.getBodyMedium(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.closeButton,
                    style: FontScaling.getButtonText(context).copyWith(
                      color: Color(0xFFFFE135),
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

  void _showQuitConfirmationDialog() {
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
                Icon(
                  Icons.logout,
                  color: Color(0xFFFFE135),
                  size: FontScaling.getResponsiveIconSize(context, 48),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Text(
                  'Exit GratiStellar?',
                  style: FontScaling.getModalTitle(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Text(
                  'Are you sure you want to exit the app?',
                  style: FontScaling.getBodyMedium(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),
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
                        SystemNavigator.pop();
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
                        'Exit',
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
    return Drawer(
      backgroundColor: Color(0xFF1A2238).withValues(alpha: 0.98),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFFE135),
                  size: FontScaling.getResponsiveIconSize(context, 48) * universalUIScale,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12) * universalUIScale),
                Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: FontScaling.getHeadingMedium(context).copyWith(
                    fontSize: FontScaling.getHeadingMedium(context).fontSize! * universalUIScale,
                    color: Color(0xFFFFE135),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.login,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * universalUIScale,
            ),
            title: Text(
              'Login',
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showComingSoonDialog('Login');
            },
          ),
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),
          ListTile(
            leading: Icon(
              Icons.list,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * universalUIScale,
            ),
            title: Text(
              'List View',
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showComingSoonDialog('List View');
            },
          ),
          Divider(
            color: Color(0xFFFFE135).withValues(alpha: 0.2),
            height: 1,
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 24) * universalUIScale,
            ),
            title: Text(
              'Exit',
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showQuitConfirmationDialog();
            },
          ),
        ],
      ),
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

  Widget _buildBottomButtonRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.visibility,
          isActive: _showAllGratitudes,
          onTap: _toggleShowAll,
        ),
        SizedBox(width: FontScaling.getResponsiveSpacing(context, 16) * universalUIScale),
        _buildAddStarButton(),
        SizedBox(width: FontScaling.getResponsiveSpacing(context, 16) * universalUIScale),
        _buildActionButton(
          icon: Icons.self_improvement,
          isActive: _mindfulnessMode,
          onTap: _toggleMindfulness,
        ),
      ],
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
            fontSize: FontScaling.getStatsLabel(context).fontSize! * universalUIScale * statsLabelTextScale,
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

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building GratitudeScreen, _isLoading: $_isLoading, stars: ${_staticStars.length}');

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
                  onPanStart: _isAnimating ? null : (details) {},
                  onPanUpdate: _isAnimating ? null : (details) {
                    _cameraController.updatePosition(details.delta);
                  },
                  onPanEnd: _isAnimating ? null : (details) {},
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
                          // Floating labels layer (when Show All is active)
                          if (_showAllGratitudes)
                            Transform(
                              transform: _cameraController.transform,
                              child: Stack(
                                children: gratitudeStars.map((star) {
                                  return FloatingGratitudeLabel(
                                    star: star,
                                    screenSize: currentSize,
                                  );
                                }).toList(),
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
                top: 16 * universalUIScale,
                left: 16 * universalUIScale,
                child: _buildHamburgerButton(),
              ),

            // Stats card
            if (!_showBranding)
              Positioned(
                top: 16 * universalUIScale,
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

            // Bottom button row with all 3 buttons
            if (!_showBranding)
              Positioned(
                bottom: 50 * universalUIScale,
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
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: FontScaling.getResponsiveIconSize(context, 64) * universalUIScale,
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
              CameraControlsOverlay(
                cameraController: _cameraController,
                stars: gratitudeStars,
                screenSize: MediaQuery.of(context).size,
                vsync: this,
              ),
          ],
        ),
      ),
    );
  }
}