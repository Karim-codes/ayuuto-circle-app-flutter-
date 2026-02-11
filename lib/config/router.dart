import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/group/group_detail_screen.dart';
import '../screens/group/group_created_screen.dart';
import '../screens/group/invite_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/join/join_group_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _historyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'history');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isAuthRoute = state.matchedLocation == '/sign-in' ||
        state.matchedLocation == '/sign-up';
    final isSplash = state.matchedLocation == '/';

    if (isSplash) return null;
    if (!isAuth && !isAuthRoute) return '/sign-in';
    if (isAuth && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),

    // Bottom navigation shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 1: History
        StatefulShellBranch(
          navigatorKey: _historyNavigatorKey,
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        // Tab 2: Profile
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Full-screen routes (pushed on top of bottom nav)
    GoRoute(
      path: '/create-group',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: '/group/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final groupId = state.pathParameters['id']!;
        return GroupDetailScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/group-created/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final groupId = state.pathParameters['id']!;
        final groupName = state.uri.queryParameters['name'] ?? 'Your Circle';
        return GroupCreatedScreen(groupId: groupId, groupName: groupName);
      },
    ),
    GoRoute(
      path: '/join',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const JoinGroupScreen(),
    ),
    GoRoute(
      path: '/group/:id/invite',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final groupId = state.pathParameters['id']!;
        return InviteScreen(groupId: groupId);
      },
    ),
  ],
);
