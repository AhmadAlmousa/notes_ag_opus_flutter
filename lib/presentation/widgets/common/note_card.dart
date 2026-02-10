import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/note.dart';

/// A card for displaying a note in lists.
class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  final Note note;
  final VoidCallback onTap;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Colors.indigo;
      case 'work':
        return Colors.grey;
      case 'family':
        return Colors.pink;
      case 'travel':
        return Colors.lightBlue;
      case 'finance':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Icons.lock;
      case 'work':
        return Icons.description;
      case 'family':
        return Icons.health_and_safety;
      case 'travel':
        return Icons.flight;
      case 'finance':
        return Icons.receipt_long;
      default:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(widget.note.category);
    final categoryIcon = _getCategoryIcon(widget.note.category);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.note.getDisplayTitle(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _getTimeAgo(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.note.category.toUpperCase(),
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Description
                        Expanded(
                          child: Text(
                            _getDescription(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo() {
    if (widget.note.updatedAt != null) {
      return AppDateUtils.getRelativeTime(widget.note.updatedAt!);
    }
    if (widget.note.createdAt != null) {
      return AppDateUtils.getRelativeTime(widget.note.createdAt!);
    }
    return '';
  }

  String _getDescription() {
    if (widget.note.records.isEmpty) return 'No records';

    // Try to get a meaningful description from first record
    final first = widget.note.records.first;
    for (final key in ['username', 'email', 'description', 'notes']) {
      if (first.containsKey(key) && first[key] != null) {
        return first[key].toString();
      }
    }

    return '${widget.note.records.length} record${widget.note.records.length != 1 ? 's' : ''}';
  }
}
