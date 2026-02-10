import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Responsive app scaffold with bottom navigation.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.floatingActionButton,
    this.appBar,
  });

  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: _BottomNavBar(currentIndex: currentIndex),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.folder_open_rounded,
                label: 'Files',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/notes'),
              ),
              _NavItem(
                icon: Icons.extension_rounded,
                label: 'Templates',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/templates'),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  widget.icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
