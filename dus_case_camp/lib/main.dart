import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart'; // Will create next
import 'screens/profile_screen.dart'; // Will create next
import 'screens/case_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/library_screen.dart';
import 'screens/user_lists_screens.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_weeks_screen.dart';
import 'screens/admin/admin_cases_screen.dart';
import 'screens/admin/admin_submissions_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    print('Firebase initialization failed (expected if not configured): $e');
  }

  // Initialize Notifications (non-blocking) only if Firebase is ready
  if (firebaseInitialized) {
    NotificationService().initialize().then((_) {
      NotificationService().setupForegroundHandler();
    }).catchError((e) {
      print('Notification init failed: $e');
    });
  }

  runApp(const ProviderScope(child: DusCaseCampApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/setup-profile',
      builder: (context, state) => const SetupProfileScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'case/:caseId',
              builder: (context, state) {
                final caseId = state.pathParameters['caseId']!;
                return CaseDetailScreen(caseId: caseId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
            GoRoute(
              path: 'watch-later',
              builder: (context, state) => const WatchLaterScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin/weeks',
          builder: (context, state) => const AdminWeeksScreen(),
          routes: [
            GoRoute(
              path: ':weekId/cases',
              builder: (context, state) {
                final weekId = state.pathParameters['weekId']!;
                return AdminCasesScreen(weekId: weekId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/admin/reviews',
          builder: (context, state) => const AdminSubmissionsScreen(),
        ),
      ],
    ),
  ],
);

class DusCaseCampApp extends ConsumerWidget {
  const DusCaseCampApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'DUS Case Camp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8), // Primary Blue
          secondary: const Color(0xFF00BCD4), // Accent Cyan
          error: const Color(0xFFD93025), // Error Red
          surface: Colors.grey[50],
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.black87),
          titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
              color: Colors.black87),
          bodyLarge:
              TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
          labelSmall: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      routerConfig: _router,
      locale: locale,
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
