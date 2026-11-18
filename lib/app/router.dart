import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../features/dashboard/home_screen.dart';
import '../features/food_catalog/add_food_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/tips/tips_screen.dart';
import 'providers.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

CustomTransitionPage<void> _buildSmoothPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 190),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.025),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  );
}

final GoRouter fitNepalRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildSmoothPage(
        state: state,
        child: const WelcomeScreen(),
      ),
    ),
    GoRoute(
      path: '/add-food',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _buildSmoothPage(
        state: state,
        child: const AddFoodScreen(),
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return FitNepalMainShell(
          location: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _buildSmoothPage(
            state: state,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => _buildSmoothPage(
            state: state,
            child: const ProgressScreen(),
          ),
        ),
        GoRoute(
          path: '/tips',
          pageBuilder: (context, state) => _buildSmoothPage(
            state: state,
            child: const TipsScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildSmoothPage(
            state: state,
            child: const ProfileScreen(),
          ),
        ),
      ],
    ),
  ],
);

class FitNepalMainShell extends ConsumerWidget {
  final String location;
  final Widget child;

  const FitNepalMainShell({
    super.key,
    required this.location,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(liveProfileProvider);
    final lang = profile.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : FitNepalColors.deepPlum.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  label: FitNepalStrings.tr(lang, 'Home', 'गृह'),
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  activeColor: primaryColor,
                  isSelected: location.startsWith('/home'),
                  onTap: () => context.go('/home'),
                ),
                _BottomNavItem(
                  label: FitNepalStrings.tr(lang, 'Progress', 'प्रगति'),
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  activeColor: primaryColor,
                  isSelected: location.startsWith('/progress'),
                  onTap: () => context.go('/progress'),
                ),
                Semantics(
                  button: true,
                  label: FitNepalStrings.tr(
                    lang,
                    'Add Food',
                    'खाना थप्नुहोस्',
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/add-food'),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [secondaryColor, primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.38),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                _BottomNavItem(
                  label: FitNepalStrings.tr(lang, 'Tips', 'सुझाव'),
                  icon: Icons.lightbulb_outline_rounded,
                  activeIcon: Icons.lightbulb_rounded,
                  activeColor: primaryColor,
                  isSelected: location.startsWith('/tips'),
                  onTap: () => context.go('/tips'),
                ),
                _BottomNavItem(
                  label: FitNepalStrings.tr(lang, 'Profile', 'प्रोफाइल'),
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  activeColor: primaryColor,
                  isSelected: location.startsWith('/profile'),
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color activeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.activeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const inactiveColor = FitNepalColors.mutedPlum;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$label tab',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 66,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
