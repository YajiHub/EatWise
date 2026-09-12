import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/log_history_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/manual_log_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/weight_history_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/profile_screen.dart';
import 'package:eatwise/features/food_ai/presentation/screens/food_ai_screen.dart';
import 'package:eatwise/features/chat_log/presentation/screens/chat_log_screen.dart';
import 'package:eatwise/features/chat_log/presentation/screens/ask_ai_screen.dart';
import 'package:eatwise/features/settings/presentation/screens/settings_screen.dart';
import 'package:eatwise/features/planner/presentation/screens/planner_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen())),
          GoRoute(path: '/food-ai', pageBuilder: (context, state) => const NoTransitionPage(child: FoodAIScreen())),
          GoRoute(path: '/chat-log', pageBuilder: (context, state) => const NoTransitionPage(child: ChatLogScreen())),
          GoRoute(path: '/history', pageBuilder: (context, state) => const NoTransitionPage(child: LogHistoryScreen())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen())),
          GoRoute(path: '/planner', pageBuilder: (context, state) => const NoTransitionPage(child: PlannerScreen())),
          GoRoute(path: '/ask-ai', pageBuilder: (context, state) => const NoTransitionPage(child: AskAiScreen())),
          GoRoute(path: '/manual-log', pageBuilder: (context, state) => const NoTransitionPage(child: ManualLogScreen())),
          GoRoute(path: '/weight-history', pageBuilder: (context, state) => const NoTransitionPage(child: WeightHistoryScreen())),
          GoRoute(path: '/settings', pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen())),
        ],
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();

    // Map every route to a nav index 0-4
    final idx = loc.startsWith('/food-ai')
        ? 1
        : loc.startsWith('/chat-log') || loc.startsWith('/ask-ai')
            ? 2
            : loc.startsWith('/history')
                ? 3
                : loc.startsWith('/profile')
                    ? 4
                    : 0; // dashboard, manual-log, weight-history → Home

    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: Column(
        children: [
          Expanded(child: child),
          NavigationBar(
            selectedIndex: idx,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            indicatorColor: colorScheme.primaryContainer,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 300),
            onDestinationSelected: (i) {
              HapticFeedback.selectionClick();
              switch (i) {
                case 0: context.go('/dashboard'); break;
                case 1: context.go('/food-ai'); break;
                case 2: context.go('/chat-log'); break;
                case 3: context.go('/history'); break;
                case 4: context.go('/profile'); break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt_rounded),
                label: 'Scan',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note_rounded),
                label: 'Log',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
