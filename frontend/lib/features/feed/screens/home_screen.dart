import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../post/screens/create_post_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    _FeedTab(),
    SearchScreen(),
    CreatePostScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Create',
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

class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Latest posts will appear here.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.mutedText,
                ),
          ),
          const SizedBox(height: 16),
          const _PlaceholderPost(),
          const SizedBox(height: 12),
          const _PlaceholderPost(),
        ],
      ),
    );
  }
}

class _PlaceholderPost extends StatelessWidget {
  const _PlaceholderPost();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SnapCircle User', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Backend feed integration will be connected next.'),
        ],
      ),
    );
  }
}
