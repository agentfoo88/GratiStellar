import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'background.dart';
import 'core/utils/app_logger.dart';
import 'features/gratitudes/data/datasources/galaxy_local_data_source.dart';
import 'features/gratitudes/data/datasources/galaxy_remote_data_source.dart';
import 'features/gratitudes/data/datasources/local_data_source.dart';
import 'features/gratitudes/data/datasources/remote_data_source.dart';
import 'features/gratitudes/data/repositories/galaxy_repository.dart';
import 'features/gratitudes/data/repositories/gratitude_repository.dart';
import 'features/gratitudes/presentation/state/galaxy_provider.dart';
import 'features/gratitudes/presentation/state/gratitude_provider.dart';
import 'firebase_options.dart';
import 'font_scaling.dart';
import 'l10n/app_localizations.dart';
import 'screens/gratitude_screen.dart';
import 'screens/onboarding/age_gate_screen.dart';
import 'screens/onboarding/enhanced_splash_screen.dart';
import 'services/auth_service.dart';
import 'services/crashlytics_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/firestore_service.dart';
import 'services/onboarding_service.dart';
import 'services/sync_status_service.dart';

// UI SCALE and ANIMATION CONFIGURATION found in constants.dart

void main() async {
  AppLogger.start('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.data('🔥 Initializing Firebase...');
  // Initialize Firebase with generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10), // Increased timeout for slower devices
      onTimeout: () {
        AppLogger.error('❌ Firebase initialization timed out!');
        throw TimeoutException('Firebase init timeout');
      },
    );
    AppLogger.success('✅ Firebase initialized');
    
    // Verify Firebase is actually ready by checking if we can access it
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase apps list is empty after initialization');
    }
    
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
  } catch (e, stack) {
    AppLogger.error('❌ Firebase initialization failed: $e');
    // Only try to log to Crashlytics if Firebase might be partially initialized
    try {
      if (Firebase.apps.isNotEmpty) {
        CrashlyticsService().recordError(e, stack, reason: 'Firebase initialization failed');
      }
    } catch (_) {
      // Ignore - Crashlytics might not be available
    }
    // Don't throw - let the app continue and handle gracefully
    // The app will show onboarding which doesn't require Firebase immediately
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
    final localDataSource = LocalDataSource();
    final remoteDataSource = RemoteDataSource(firestoreService);
    final repository = GratitudeRepository(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      authService: authService,
    );

    // Initialize galaxy services
    final galaxyLocalDataSource = GalaxyLocalDataSource();
    final galaxyRemoteDataSource = GalaxyRemoteDataSource(authService: authService);
    final galaxyRepository = GalaxyRepository(
      localDataSource: galaxyLocalDataSource,
      remoteDataSource: galaxyRemoteDataSource,
      gratitudeRepository: repository,
      authService: authService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: syncStatusService),
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

            // Initialize galaxy system ONCE, then load gratitudes
            if (!galaxyProvider.isLoading && galaxyProvider.activeGalaxyId == null) {
              // First time - initialize galaxies
              Future.microtask(() async {
                await galaxyProvider.initialize();
                // After galaxies are ready, load gratitudes
                await gratitudeProvider!.loadGratitudes();
              });
            } else if (galaxyProvider.activeGalaxyId != null &&
                gratitudeProvider.gratitudeStars.isEmpty &&
                !gratitudeProvider.isLoading) {
              // Galaxy is ready but gratitudes not loaded yet
              Future.microtask(() => gratitudeProvider!.loadGratitudes());
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
          focusColor: Color(0xFFFFE135),
          // Update input decoration theme for visible focus
          inputDecorationTheme: InputDecorationTheme(
            focusColor: Color(0xFFFFE135),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Color(0xFFFFE135),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Color(0xFFFFE135).withValues(alpha: 0.3),
              ),
            ),
          ),
          // Update elevated button theme for focus
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              overlayColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return Color(0xFFFFE135).withValues(alpha: 0.2);
                }
                return Colors.transparent;
              }),
            ),
          ),
          // Time picker theme to match app design
          timePickerTheme: TimePickerThemeData(
            backgroundColor: const Color(0xFF1A2238),
            dialBackgroundColor: const Color(0xFF0A0E27),
            dialHandColor: const Color(0xFFFFE135),
            dialTextColor: Colors.white.withValues(alpha: 0.9),
            hourMinuteTextColor: const Color(0xFFFFE135),
            hourMinuteColor: const Color(0xFF1A2238),
            dayPeriodTextColor: Colors.white.withValues(alpha: 0.9),
            dayPeriodColor: const Color(0xFF1A2238),
            dayPeriodBorderSide: const BorderSide(
              color: Color(0xFFFFE135),
              width: 1,
            ),
            hourMinuteTextStyle: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFE135),
            ),
            dayPeriodTextStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            helpTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFE135),
            ),
            entryModeIconColor: const Color(0xFFFFE135),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(
                color: Color(0xFFFFE135),
                width: 2,
              ),
            ),
          ),
          // Dialog theme for consistency
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF1A2238),
            titleTextStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFE135),
            ),
            contentTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(
                color: Color(0xFFFFE135),
                width: 2,
              ),
            ),
          ),
          // Text button theme for dialog actions
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFE135),
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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFE135)),
        ),
      ),
    );
  }

  /// Check if Firebase is ready
  bool _isFirebaseReady() {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
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

    // After splash, show the appropriate screen based on onboarding/auth state
    return FutureBuilder<bool>(
      future: OnboardingService().isOnboardingComplete(),
      builder: (context, onboardingSnapshot) {
        // Show loading while checking onboarding status
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Handle errors in onboarding check
        if (onboardingSnapshot.hasError) {
          AppLogger.error('Error checking onboarding status: ${onboardingSnapshot.error}');
          // On error, navigate to age gate to restart onboarding
          return const AgeGateScreen();
        }

        final onboardingComplete = onboardingSnapshot.data ?? false;

        if (!onboardingComplete) {
          // First time user - start onboarding flow with age gate
          return const AgeGateScreen();
        }

        // Onboarding complete - use auth state listener
        // Check if Firebase is ready before accessing auth
        if (!_isFirebaseReady()) {
          AppLogger.warning('Firebase not ready, showing age gate as fallback');
          return const AgeGateScreen();
        }

        // Wrap in try-catch to handle Firebase initialization issues
        try {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              // Show loading while checking auth state
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              // Handle errors in auth stream
              if (authSnapshot.hasError) {
                AppLogger.error('Error in auth state stream: ${authSnapshot.error}');
                // On error, restart onboarding as safe fallback
                Future.microtask(() async {
                  try {
                    await OnboardingService().resetOnboarding();
                  } catch (e) {
                    AppLogger.error('Error resetting onboarding: $e');
                  }
                });
                return const AgeGateScreen();
              }

              // If authenticated, show main app
              if (authSnapshot.hasData) {
                return GratitudeScreen();
              }

              // Edge case: onboarding complete but no user
              // This shouldn't happen, but if it does, restart onboarding
              AppLogger.warning('Onboarding complete but no user - restarting onboarding');
              Future.microtask(() async {
                try {
                  await OnboardingService().resetOnboarding();
                } catch (e) {
                  AppLogger.error('Error resetting onboarding: $e');
                }
              });
              return const AgeGateScreen();
            },
          );
        } catch (e, stack) {
          AppLogger.error('Error accessing Firebase Auth: $e');
          CrashlyticsService().recordError(e, stack, reason: 'Firebase Auth access error');
          // Fallback to age gate if Firebase Auth fails
          return const AgeGateScreen();
        }
      },
    );
  }
}