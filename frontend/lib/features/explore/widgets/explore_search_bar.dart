import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_text_field.dart';

class ExploreSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const ExploreSearchBar({
    super.key,
    required this.query,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<ExploreSearchBar> createState() => _ExploreSearchBarState();
}

class _ExploreSearchBarState extends State<ExploreSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant ExploreSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Search',
      hint: 'Search posts, people, or ideas',
      controller: _controller,
      onChanged: _onChanged,
      prefixIcon: const Icon(Icons.search_outlined),
      suffixIcon: _controller.text.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                _controller.clear();
                widget.onClear();
              },
              icon: const Icon(Icons.close),
              tooltip: 'Clear search',
            ),
    );
  }
}
