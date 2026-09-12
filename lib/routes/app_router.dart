import 'package:caminhandojuntos/screens/accessibility_settings_screen.dart';
import 'package:caminhandojuntos/screens/achievements_screen.dart';
import 'package:caminhandojuntos/screens/dashboard_screen.dart';
import 'package:caminhandojuntos/screens/permission_screen.dart';
import 'package:caminhandojuntos/screens/emergency_alert_screen.dart';
import 'package:caminhandojuntos/screens/profile_screen.dart';
import 'package:caminhandojuntos/screens/registration_screen.dart';
import 'package:caminhandojuntos/screens/rewards_store_screen.dart';
import 'package:caminhandojuntos/screens/summary_screen.dart';
import 'package:caminhandojuntos/screens/walking_screen.dart';
import 'package:caminhandojuntos/screens/welcome_screen.dart';
import 'package:caminhandojuntos/screens/splash_screen.dart';
import 'package:caminhandojuntos/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Provider que mantém a instância do roteador estável.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/', // Inicia sempre no Splash
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/registration',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: '/walking',
        builder: (context, state) => const WalkingScreen(),
      ),
      GoRoute(
        path: '/summary',
        builder: (context, state) => const SummaryScreen(),
      ),
      GoRoute(
        path: '/accessibility',
        builder: (context, state) => const AccessibilitySettingsScreen(),
      ),
      GoRoute(
        path: '/emergency',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return EmergencyAlertScreen(
            contactName: extra['name']!,
            contactPhone: extra['phone']!,
          );
        },
      ),

      // Shell para as abas principais com BottomNav persistente
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/store',
                builder: (context, state) => const RewardsStoreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
