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
    // Work in world coordinates
    final starX = star.worldX * screenSize.width;
    final starY = star.worldY * screenSize.height;

    final maxLabelWidth = screenSize.width * 0.4;
    const verticalOffset = 70.0;

    return Positioned(
      left: starX,
      top: starY - verticalOffset,
      child: FractionalTranslation(
        translation: Offset(-0.5, 0), // Shift left by 50% of actual width
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxLabelWidth,
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
            textAlign: TextAlign.center,
          ),
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
  static const double universalUIScale = 0.75;
  static const double labelBackgroundAlpha = 0.85;
  static const double statsLabelTextScale = 1.15;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _gratitudeController = TextEditingController();
  final TextEditingController _editTextController = TextEditingController();
  final TextEditingController _hexColorController = TextEditingController();
  final TextEditingController _redController = TextEditingController();
  final TextEditingController _greenController = TextEditingController();
  final TextEditingController _blueController = TextEditingController();

  List<GratitudeStar> gratitudeStars = [];
  List<OrganicNebulaRegion> _organicNebulaRegions = [];
  late AnimationController _backgroundController;
  late AnimationController _starController;
  late CameraController _cameraController;
  late AnimationController _labelFadeController;
  late Animation<double> _labelFadeAnimation;
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

  // Phase 4 additions
  final String _userName = "A friend";
  String? _editingStarId;
  bool _isEditMode = false;
  Color? _previewColor;

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

    _labelFadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

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
    _editTextController.dispose();
    _hexColorController.dispose();
    _redController.dispose();
    _greenController.dispose();
    _blueController.dispose();
    _birthController?.dispose();
    _mindfulnessTimer?.cancel();
    _labelFadeController.dispose();  // ADD THIS LINE
    super.dispose();
  }

  void _addGratitude() async {
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
            constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
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
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
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
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    SizedBox(width: FontScaling.getResponsiveSpacing(context, 12)),
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
    setState(() {
      _isEditMode = false;
      _editingStarId = star.id;
      _editTextController.text = star.text;
    });

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
                padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 20)),
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
                      size: FontScaling.getResponsiveIconSize(context, 48),
                    ),
                    SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),

                    // Text display or edit mode
                    if (!_isEditMode)
                      Text(
                        star.text,
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
                          _buildModalIconButton(
                            icon: Icons.edit,
                            label: AppLocalizations.of(context)!.editButton,
                            onTap: () {
                              setState(() {
                                _isEditMode = true;
                              });
                            },
                          ),
                          _buildModalIconButton(
                            icon: Icons.share,
                            label: AppLocalizations.of(context)!.shareButton,
                            onTap: () => _shareStar(star),
                          ),
                          _buildModalIconButton(
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
                              _showColorPicker(star, setState);
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
                                  _showDeleteConfirmation(star, context);
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
                                    _editTextController.text = star.text;
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
                                  _saveStarEdits(star);
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
        _editingStarId = null;
      });
    });
  }

  Widget _buildModalIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Color(0xFFFFE135),
              size: FontScaling.getResponsiveIconSize(context, 28),
            ),
            SizedBox(height: FontScaling.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: FontScaling.getCaption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareStar(GratitudeStar star) {
    final shareText = '$_userName shared their gratitude with you:\n${star.text}\n\n- GratiStellar - your universe of thankfulness';
    SharePlus.instance.share(
        ShareParams(text: shareText)
    );
  }

  void _saveStarEdits(GratitudeStar star) {
    final index = gratitudeStars.indexWhere((s) => s.id == star.id);
    if (index != -1) {
      setState(() {
        gratitudeStars[index] = star.copyWith(
          text: _editTextController.text,
        );
      });
      _saveGratitudes();
    }
  }

  void _showDeleteConfirmation(GratitudeStar star, BuildContext modalContext) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
            padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 24)),
            decoration: BoxDecoration(
              color: Color(0xFF1A2238).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.5),
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
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: FontScaling.getResponsiveIconSize(context, 48),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Text(
                  AppLocalizations.of(context)!.deleteConfirmTitle,
                  style: FontScaling.getModalTitle(context).copyWith(
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Container(
                  padding: EdgeInsets.all(FontScaling.getResponsiveSpacing(context, 12)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"${star.text}"',
                    style: FontScaling.getBodySmall(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Text(
                  AppLocalizations.of(context)!.deleteWarning,
                  style: FontScaling.getBodySmall(context).copyWith(
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 20)),
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
                    ElevatedButton.icon(
                      onPressed: () {
                        _deleteStar(star);
                        Navigator.of(context).pop(); // Close confirmation
                        Navigator.of(modalContext).pop(); // Close edit modal
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
                          horizontal: FontScaling.getResponsiveSpacing(context, 20),
                          vertical: FontScaling.getResponsiveSpacing(context, 12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
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

  void _deleteStar(GratitudeStar star) {
    setState(() {
      gratitudeStars.removeWhere((s) => s.id == star.id);
    });
    _saveGratitudes();
  }

  void _showColorPicker(GratitudeStar star, StateSetter modalSetState) {
    // Initialize preview color and controllers
    _previewColor = StarColors.getColor(star.colorIndex);
    final currentColor = StarColors.getColor(star.colorIndex);
    final r = (currentColor.r * 255).round();
    final g = (currentColor.g * 255).round();
    final b = (currentColor.b * 255).round();
    _hexColorController.text = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    _redController.text = r.toString();
    _greenController.text = g.toString();
    _blueController.text = b.toString();

    int selectedColorIndex = star.colorIndex;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        child: Icon(
                          Icons.auto_awesome,
                          color: _previewColor,
                          size: FontScaling.getResponsiveIconSize(context, 64),
                        ),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 24)),

                      // Color grid
                      Text(
                        AppLocalizations.of(context)!.presetColorsTitle,
                        style: FontScaling.getBodyMedium(context),
                      ),
                      SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                      _buildColorGrid(selectedColorIndex, (index) {
                        setState(() {
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
                          if (value.length == 7 && value.startsWith('#')) {
                            try {
                              final color = Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
                              setState(() {
                                _previewColor = color;
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
                              onChanged: (value) => _updateFromRGB(setState),
                            ),
                          ),
                          SizedBox(width: FontScaling.getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: TextField(
                              controller: _greenController,
                              decoration: InputDecoration(
                                labelText: 'G',  // CHANGED: was 'B'
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: FontScaling.getInputText(context),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _updateFromRGB(setState),
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
                              onChanged: (value) => _updateFromRGB(setState),
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
                              _applyColorChange(star, selectedColorIndex, modalSetState);
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
        );
      },
    );
  }

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

  void _applyColorChange(GratitudeStar star, int colorIndex, StateSetter modalSetState) {
    final index = gratitudeStars.indexWhere((s) => s.id == star.id);
    if (index != -1) {
      setState(() {
        gratitudeStars[index] = star.copyWith(colorIndex: colorIndex);
      });
      modalSetState(() {
        // Update the modal's star reference
      });
      _saveGratitudes();
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
    // Check if there are any stars
    if (gratitudeStars.isEmpty) {
      _showMindfulnessNoStarsDialog();
      return;
    }

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

    _labelFadeController.reverse().then((_) {
      setState(() {
        _activeMindfulnessStar = selectedStar;
      });
      _labelFadeController.forward();
    });

    print('🧘 Active mindfulness star set: ${_activeMindfulnessStar?.text}');

    _navigateToMindfulnessStar(selectedStar);
  }

  void _navigateToMindfulnessStar(GratitudeStar star) {
    final screenSize = MediaQuery.of(context).size;
    final targetScale = 2.5; // Zoom in closer for mindfulness

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
      duration: Duration(milliseconds: 2000),  // Slower: 800ms → 1500ms
      curve: Curves.easeInOutCubic,  // Smooth speed ramp at start and end
      vsync: this,
    );
  }

  void _showMindfulnessNoStarsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, minWidth: 400),
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
                  Icons.self_improvement,
                  color: Color(0xFFFFE135),
                  size: FontScaling.getResponsiveIconSize(context, 48),
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 16)),
                Text(
                  AppLocalizations.of(context)!.mindfulnessNoStarsTitle,
                  style: FontScaling.getModalTitle(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Text(
                  AppLocalizations.of(context)!.mindfulnessNoStarsMessage,
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

  void _onMindfulnessIntervalChanged(double value) {
    setState(() {
      _mindfulnessInterval = value.round();
    });

    // Restart timer with new interval if currently active
    if (_mindfulnessMode && _mindfulnessTimer != null) {
      _scheduleNextStar();  // ✅ Use the correct method that includes camera delay
    }
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
                  AppLocalizations.of(context)!.comingSoonTitle,
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
                  AppLocalizations.of(context)!.exitTitle,
                  style: FontScaling.getModalTitle(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: FontScaling.getResponsiveSpacing(context, 12)),
                Text(
                  AppLocalizations.of(context)!.exitMessage,
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
                        AppLocalizations.of(context)!.exitButton,
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
              AppLocalizations.of(context)!.loginMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
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
              AppLocalizations.of(context)!.listViewMenuItem,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
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
              AppLocalizations.of(context)!.exitButton,
              style: FontScaling.getBodyMedium(context).copyWith(
                fontSize: FontScaling.getBodyMedium(context).fontSize! * universalUIScale,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
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
        // Slider appears to the right of Mindfulness button when active
        if (_mindfulnessMode) ...[
          SizedBox(width: FontScaling.getResponsiveSpacing(context, 16) * universalUIScale),
          _buildMindfulnessSlider(),
        ],
      ],
    );
  }

  Widget _buildMindfulnessSlider() {
    return Container(
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
            style: FontScaling.getBodySmall(context).copyWith(
              fontSize: FontScaling.getBodySmall(context).fontSize! * universalUIScale,
            ),
          ),
          SizedBox(height: FontScaling.getResponsiveSpacing(context, 8) * universalUIScale),
          SizedBox(
            width: 200 * universalUIScale,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Color(0xFFFFE135),
                inactiveTrackColor: Color(0xFFFFE135).withValues(alpha: 0.3),
                thumbColor: Color(0xFFFFE135),
                overlayColor: Color(0xFFFFE135).withValues(alpha: 0.2),
                trackHeight: 4 * universalUIScale,
              ),
              child: Slider(
                value: _mindfulnessInterval.toDouble(),
                min: 2,
                max: 20,
                divisions: 18,
                onChanged: _onMindfulnessIntervalChanged,
              ),
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
                  onPanStart: _isAnimating ? null : (details) {
                    if (_mindfulnessMode) {
                      _stopMindfulnessMode();
                      setState(() {
                        _mindfulnessMode = false;
                      });
                    }
                  },
                  onPanUpdate: _isAnimating ? null : (details) {
                    if (_mindfulnessMode) {
                      _stopMindfulnessMode();
                      setState(() {
                        _mindfulnessMode = false;
                      });
                    }
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
                                    );
                                  }),

                                // Mindfulness mode - single star
                                if (_mindfulnessMode && _activeMindfulnessStar != null)
                                  Builder(
                                    builder: (context) {
                                      print('🏷️ Rendering mindfulness label for: ${_activeMindfulnessStar!.text}');
                                      print('🏷️ Camera position: ${_cameraController.position}');
                                      print('🏷️ Camera scale: ${_cameraController.scale}');
                                      return FloatingGratitudeLabel(
                                        star: _activeMindfulnessStar!,
                                        screenSize: currentSize,
                                      );
                                    },
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
                top: 50 * universalUIScale,
                left: 16 * universalUIScale,
                child: _buildHamburgerButton(),
              ),

            // Stats card
            if (!_showBranding)
              Positioned(
                top: 50 * universalUIScale,
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