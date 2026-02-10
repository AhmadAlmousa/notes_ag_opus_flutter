import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Styled search bar widget.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.onSearch,
    this.hintText = 'Search...',
    this.autofocus = false,
  });

  final ValueChanged<String>? onSearch;
  final String hintText;
  final bool autofocus;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onSubmit(String value) {
    widget.onSearch?.call(value);
  }

  void _onClear() {
    _controller.clear();
    widget.onSearch?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onSubmitted: _onSubmit,
        onChanged: (value) {
          // Debounce search
          if (value.isEmpty) {
            widget.onSearch?.call('');
          }
        },
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.search,
              color: _isFocused
                  ? AppTheme.primaryColor
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _onClear,
                ),
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  // TODO: Show filter options
                },
              ),
            ],
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
