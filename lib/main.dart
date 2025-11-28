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
import 'screens/onboarding/splash_screen.dart';
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

  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Crashlytics
  await CrashlyticsService().initialize();

  AppLogger.data('📦 Loading textures...');
  try {
    CrashlyticsService().log('Starting texture loading');
    await BackgroundService.loadTextures();
    CrashlyticsService().log('Textures loaded successfully');
    AppLogger.success('✅ Textures loaded, starting app');
  } catch (e, stack) {
    CrashlyticsService().recordError(e, stack, reason: 'Texture loading failed');
    AppLogger.error('⚠️ Texture loading error: $e (continuing anyway)');
  }

  // Note: Layer cache will be initialized per screen size in GratitudeScreen
  // This is because we need to know the actual screen size first

  runApp(GratiStellarApp());
}

class GratiStellarApp extends StatelessWidget {
  const GratiStellarApp({super.key});

  /// Build loading screen shown during async checks
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFE135),
          ),
        ),
      ),
    );
  }

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
        ),

        // Onboarding-aware routing with Firebase auth state listener
        home: FutureBuilder<bool>(
          future: OnboardingService().isOnboardingComplete(),
          builder: (context, onboardingSnapshot) {
            // Show loading while checking onboarding status
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            final onboardingComplete = onboardingSnapshot.data ?? false;

            if (!onboardingComplete) {
              // First time user - start onboarding flow
              return SplashScreen();
            }

            // Onboarding complete - use auth state listener
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                // Show loading while checking auth state
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }

                // If authenticated, show main app
                if (authSnapshot.hasData) {
                  return GratitudeScreen();
                }

                // Edge case: onboarding complete but no user
                // This shouldn't happen, but if it does, restart onboarding
                AppLogger.warning('Onboarding complete but no user - restarting onboarding');
                Future.microtask(() async {
                  await OnboardingService().resetOnboarding();
                });
                return SplashScreen();
              },
            );
          },
        ),
      ),
    );
  }
}