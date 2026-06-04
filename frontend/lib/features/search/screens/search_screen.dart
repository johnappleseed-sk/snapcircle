import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _SearchAppBar(),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              label: 'Search',
              hint: 'Find users or posts',
            ),
            SizedBox(height: 16),
            Text('Search results will appear here.'),
          ],
        ),
      ),
    );
  }
}

class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SearchAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Search'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
