import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/log_history_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/manual_log_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/weight_history_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/profile_screen.dart';
import 'package:eatwise/features/dashboard/presentation/screens/fasting_screen.dart';
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
          GoRoute(path: '/fasting', pageBuilder: (context, state) => const NoTransitionPage(child: FastingScreen())),
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

    // 4-Tab Obsidian Dock mapping:
    // 0: HUB (/dashboard, /manual-log, /weight-history, /fasting)
    // 1: SCAN (/food-ai)
    // 2: COACH (/chat-log, /ask-ai, /planner)
    // 3: HISTORY (/history)
    final int? activeIdx = loc.startsWith('/food-ai')
        ? 1
        : (loc.startsWith('/chat-log') || loc.startsWith('/ask-ai') || loc.startsWith('/planner'))
            ? 2
            : loc.startsWith('/history')
                ? 3
                : (loc.startsWith('/dashboard') || loc.startsWith('/manual-log') || loc.startsWith('/weight-history') || loc.startsWith('/fasting'))
                    ? 0
                    : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: isDark ? const Color(0xFF080C14) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF090D17) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0x18FFFFFF) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 6,
            bottom: math.max(8.0, bottomPad),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0: HUB
              _buildNavButton(
                context: context,
                index: 0,
                active: activeIdx == 0,
                icon: Icons.grid_view_rounded,
                label: 'HUB',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/dashboard');
                },
              ),

              // 1: SCAN (Elevated Neon Emerald Center Pill)
              _buildScanCenterButton(
                context: context,
                active: activeIdx == 1,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  context.go('/food-ai');
                },
              ),

              // 2: COACH
              _buildNavButton(
                context: context,
                index: 2,
                active: activeIdx == 2,
                icon: Icons.psychology_rounded,
                label: 'COACH',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/chat-log');
                },
              ),

              // 3: HISTORY
              _buildNavButton(
                context: context,
                index: 3,
                active: activeIdx == 3,
                icon: Icons.calendar_today_outlined,
                selectedIcon: Icons.calendar_today_rounded,
                label: 'HISTORY',
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/history');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required int index,
    required bool active,
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF7E8798) : Colors.grey.shade500;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? (selectedIcon ?? icon) : icon,
                  size: 22,
                  color: active ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.8,
                    color: active ? activeColor : inactiveColor,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? activeColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanCenterButton({
    required BuildContext context,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: active ? 0.65 : 0.4),
                    blurRadius: active ? 16 : 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.black,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'SCAN',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
