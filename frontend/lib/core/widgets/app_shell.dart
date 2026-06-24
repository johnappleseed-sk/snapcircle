import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_sizes.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AppShell({super.key, required this.child, required this.currentIndex});

  static const _routes = [
    '/home',
    '/explore',
    '/create',
    '/notifications',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => _go(context, 0),
                  ),
                  _NavItem(
                    icon: Icons.search,
                    selectedIcon: Icons.travel_explore,
                    label: 'Explore',
                    isSelected: currentIndex == 1,
                    onTap: () => _go(context, 1),
                  ),
                  _CreateNavItem(
                    isSelected: currentIndex == 2,
                    onTap: () => _go(context, 2),
                  ),
                  _NavItem(
                    icon: Icons.favorite_border,
                    selectedIcon: Icons.favorite,
                    label: 'Activity',
                    isSelected: currentIndex == 3,
                    onTap: () => _go(context, 3),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                    isSelected: currentIndex == 4,
                    onTap: () => _go(context, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, int index) {
    final route = _routes[index];
    if (GoRouterState.of(context).uri.path != route) {
      context.go(route);
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.62);
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  scale: isSelected ? 1.06 : 1,
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CreateNavItem({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Tooltip(
        message: 'Create',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: isSelected ? 0.22 : 0.12,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: theme.colorScheme.surface),
                ),
                const SizedBox(height: 3),
                Text(
                  'Create',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
