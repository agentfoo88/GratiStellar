import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background.dart';
import 'core/services/firebase_initializer.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'features/gratitudes/data/datasources/galaxy_local_data_source.dart';
import 'features/gratitudes/data/datasources/galaxy_remote_data_source.dart';
import 'features/gratitudes/data/datasources/local_data_source.dart';
import 'features/gratitudes/data/datasources/remote_data_source.dart';
import 'features/gratitudes/data/repositories/galaxy_repository.dart';
import 'features/gratitudes/data/repositories/gratitude_repository.dart';
import 'features/gratitudes/presentation/state/galaxy_provider.dart';
import 'features/gratitudes/presentation/state/gratitude_provider.dart';
import 'font_scaling.dart';
import 'l10n/app_localizations.dart';
import 'screens/onboarding/age_gate_screen.dart';
import 'screens/onboarding/enhanced_splash_screen.dart';
import 'services/auth_service.dart';
import 'services/crashlytics_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/firestore_service.dart';
import 'services/onboarding_service.dart';
import 'services/sync_status_service.dart';
import 'services/user_profile_manager.dart';

// UI SCALE and ANIMATION CONFIGURATION found in constants.dart

void main() async {
  AppLogger.start('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL FIX: Set first run flag BEFORE initializing providers
  // This prevents the first run cleanup from deleting galaxies created during initialization
  try {
    final prefs = await SharedPreferences.getInstance();
    final hasRunBefore = prefs.getBool('has_run_before') ?? false;
    if (!hasRunBefore) {
      AppLogger.info('🆕 First run detected - will skip data cleanup during provider initialization');
      await prefs.setBool('has_run_before', true);
    }
  } catch (e) {
    AppLogger.error('⚠️ Error setting first run flag: $e');
  }

  AppLogger.data('🔥 Initializing Firebase...');
  // Initialize Firebase using FirebaseInitializer with retry logic
  final firebaseInitialized = await FirebaseInitializer.instance.ensureInitialized();

  if (firebaseInitialized) {
    // Initialize Crashlytics only if Firebase is ready
    AppLogger.data('💥 Initializing Crashlytics...');
    try {
      await CrashlyticsService().initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.error('❌ Crashlytics initialization timed out!');
          throw TimeoutException('Crashlytics init timeout');
        },
      );
      AppLogger.success('✅ Crashlytics initialized');
    } catch (e) {
      AppLogger.error('❌ Crashlytics failed: $e (continuing anyway)');
    }
  } else {
    // Firebase failed to initialize after all retries
    AppLogger.warning('⚠️ Firebase initialization failed, app will run in offline mode');
    AppLogger.warning('⚠️ Some features may be unavailable');
  }

  AppLogger.data('📦 Loading textures...');
  try {
    CrashlyticsService().log('Starting texture loading');
    await BackgroundService.loadTextures().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        AppLogger.error('❌ Texture loading timed out!');
        throw TimeoutException('Texture loading timeout');
      },
    );
    CrashlyticsService().log('Textures loaded successfully');
    AppLogger.success('✅ Textures loaded, starting app');
  } catch (e, stack) {
    CrashlyticsService().recordError(e, stack, reason: 'Texture loading failed');
    AppLogger.error('⚠️ Texture loading error: $e (continuing anyway)');
  }

  // Note: Layer cache will be initialized per screen size in GratitudeScreen
  // This is because we need to know the actual screen size first

  // Validate WCAG compliance in debug mode
  if (kDebugMode) {
    AppLogger.data('🎨 Validating WCAG compliance...');
    AppTheme.validateWCAG();
  }

  AppLogger.start('🏃 Running app...');
  runApp(GratiStellarApp());
}

class GratiStellarApp extends StatelessWidget {
  const GratiStellarApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.start('🏗️ Building GratiStellarApp');

    // Initialize services (these are singletons/static, so safe to create here)
    final authService = AuthService();
    final syncStatusService = SyncStatusService();
    final firestoreService = FirestoreService();
    
    // Initialize user profile manager for user-scoped storage
    final userProfileManager = UserProfileManager(authService: authService);
    
    final localDataSource = LocalDataSource(userProfileManager: userProfileManager);
    final remoteDataSource = RemoteDataSource(firestoreService);
    final repository = GratitudeRepository(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      authService: authService,
    );

    // Initialize galaxy services
    final galaxyLocalDataSource = GalaxyLocalDataSource(userProfileManager: userProfileManager);
    final galaxyRemoteDataSource = GalaxyRemoteDataSource(
      authService: authService,
    );
    final galaxyRepository = GalaxyRepository(
      localDataSource: galaxyLocalDataSource,
      remoteDataSource: galaxyRemoteDataSource,
      gratitudeRepository: repository,
      authService: authService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: syncStatusService),
        ChangeNotifierProvider.value(value: userProfileManager),
        ChangeNotifierProvider(
          create: (_) => DailyReminderService()..initialize(),
        ),
        // Galaxy Provider FIRST
        ChangeNotifierProvider(
          create: (_) => GalaxyProvider(
            galaxyRepository: galaxyRepository,
            gratitudeRepository: repository,
          ),
        ),

        // Gratitude Provider SECOND (depends on Galaxy Provider)
        ChangeNotifierProxyProvider<GalaxyProvider, GratitudeProvider?>(
          create: (context) {
            final gratitudeProvider = GratitudeProvider(
              repository: repository,
              authService: authService,
              syncStatusService: syncStatusService,
              random: math.Random(),
            );

            // Link providers bidirectionally ONCE during creation
            final galaxyProvider = context.read<GalaxyProvider>();
            gratitudeProvider.setGalaxyProvider(galaxyProvider);
            galaxyProvider.setGratitudeProvider(gratitudeProvider);

            return gratitudeProvider;
          },
          update: (context, galaxyProvider, gratitudeProvider) {
            // Ensure gratitudeProvider exists
            if (gratitudeProvider == null) {
              gratitudeProvider = GratitudeProvider(
                repository: repository,
                authService: authService,
                syncStatusService: syncStatusService,
                random: math.Random(),
              );

              // Link on first update if needed
              gratitudeProvider.setGalaxyProvider(galaxyProvider);
              galaxyProvider.setGratitudeProvider(gratitudeProvider);
            }

            return gratitudeProvider;
          },
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
              fontSize: FontScaling.mobileBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Add focus theme
          focusColor: AppTheme.primary,
          // Update input decoration theme for visible focus
          inputDecorationTheme: InputDecorationTheme(
            focusColor: AppTheme.primary,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.borderSubtle,
              ),
            ),
          ),
          // Update elevated button theme for focus
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              overlayColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return AppTheme.overlayLight;
                }
                return Colors.transparent;
              }),
            ),
          ),
          // Time picker theme to match app design
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppTheme.backgroundDark,
            dialBackgroundColor: AppTheme.backgroundDarker,
            dialHandColor: AppTheme.primary,
            dialTextColor: Colors.white.withValues(alpha: 0.9),
            hourMinuteTextColor: AppTheme.primary,
            hourMinuteColor: AppTheme.backgroundDark,
            dayPeriodTextColor: Colors.white.withValues(alpha: 0.9),
            dayPeriodColor: AppTheme.backgroundDark,
            dayPeriodBorderSide: BorderSide(
              color: AppTheme.primary,
              width: 1,
            ),
            hourMinuteTextStyle: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
            dayPeriodTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            helpTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
            entryModeIconColor: AppTheme.primary,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
          ),
          // Dialog theme for consistency
          dialogTheme: DialogThemeData(
            backgroundColor: AppTheme.backgroundDark,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
            contentTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
          ),
          // Text button theme for dialog actions
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Always show splash first, then route based on state
        home: const _SplashWrapper(),
      ),
    );
  }
}

/// Wrapper widget that shows splash screen first, then navigates to appropriate screen
class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper();

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  bool _splashComplete = false;

  /// Build a simple loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      // Show splash screen first
      return EnhancedSplashScreen(
        displayMode: SplashDisplayMode.onboarding,
        onComplete: () {
          // Mark splash as complete and rebuild to show main content
          if (mounted) {
            setState(() {
              _splashComplete = true;
            });
          }
        },
      );
    }

    // After splash, wait for galaxy initialization before showing the main app
    final galaxyProvider = Provider.of<GalaxyProvider>(context, listen: false);
    final gratitudeProvider = Provider.of<GratitudeProvider?>(context, listen: false);

    return FutureBuilder<void>(
      future: _initializeProviders(galaxyProvider, gratitudeProvider).timeout(
        Duration(seconds: 90),  // Generous timeout for slow emulators
        onTimeout: () {
          AppLogger.error('❌ Initialization hung for 90+ seconds, showing error');
          throw TimeoutException('App initialization timed out after 90 seconds');
        },
      ),
      builder: (context, initSnapshot) {
        // Show loading while initializing
        if (initSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Preparing your universe...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle initialization errors
        if (initSnapshot.hasError) {
          final error = initSnapshot.error;
          AppLogger.error('Error during initialization: $error');

          // Handle timeout errors specifically
          if (error is TimeoutException) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundDarker,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_off, color: Colors.orange, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Initialization took too long',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'The app may be experiencing connectivity issues or running slowly.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          // Force restart initialization
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.backgroundDarker,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Handle other errors
          return Scaffold(
            backgroundColor: AppTheme.backgroundDarker,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Failed to initialize app',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '$error',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.backgroundDarker,
                      ),
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // After initialization, show the appropriate screen based on onboarding/auth state
        final userProfileManager = Provider.of<UserProfileManager>(context, listen: false);

        return FutureBuilder<Widget>(
          future: OnboardingService(userProfileManager: userProfileManager).getInitialScreen(),
          builder: (context, snapshot) {
            // Show loading while determining initial screen
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            // Handle errors in initial screen determination
            if (snapshot.hasError) {
              AppLogger.error('Error determining initial screen: ${snapshot.error}');
              // On error, navigate to age gate to restart onboarding
              return const AgeGateScreen();
            }

            // Return the determined screen (GratitudeScreen, AgeGateScreen, or ConsentScreen)
            return snapshot.data ?? const AgeGateScreen();
          },
        );
      },
    );
  }

  /// Initialize providers in the correct order
  Future<void> _initializeProviders(
    GalaxyProvider galaxyProvider,
    GratitudeProvider? gratitudeProvider,
  ) async {
    try {
      // Initialize galaxy system first
      await galaxyProvider.initialize();
      AppLogger.success('✅ Galaxy system initialized');

      // Then load gratitudes
      if (gratitudeProvider != null) {
        await gratitudeProvider.loadGratitudes();
        AppLogger.success('✅ Gratitudes loaded');
      }
    } catch (e) {
      AppLogger.error('❌ Provider initialization failed: $e');
      rethrow;
    }
  }
}