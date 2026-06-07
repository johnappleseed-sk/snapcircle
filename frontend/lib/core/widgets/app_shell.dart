import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          final route = _routes[index];
          if (GoRouterState.of(context).uri.path != route) {
            context.go(route);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
