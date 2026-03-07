import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';

/// Full-screen Recycle Bin — shows deleted notes with restore/delete options.
class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  Map<String, Map<String, dynamic>> _trash = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  void _loadTrash() {
    final storage = ref.read(storageProvider);
    final trash = storage.getTrash();

    // Remove expired items (> 7 days)
    final now = DateTime.now().toUtc();
    final keysToRemove = <String>[];
    for (final entry in trash.entries) {
      final expiresAt = DateTime.tryParse(entry.value['expiresAt'] ?? '');
      if (expiresAt != null && now.isAfter(expiresAt)) {
        keysToRemove.add(entry.key);
      }
    }
    if (keysToRemove.isNotEmpty) {
      for (final key in keysToRemove) {
        trash.remove(key);
        storage.permanentlyDeleteFromTrash(key);
      }
    }

    setState(() {
      _trash = trash;
      _isLoading = false;
    });
  }

  Future<void> _restoreItem(String key) async {
    final storage = ref.read(storageProvider);
    await storage.restoreFromTrash(key);
    ref.read(syncTriggerProvider.notifier).trigger();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note restored'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTrash();
    }
  }

  Future<void> _permanentlyDelete(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: const Text(
          'This will permanently delete this note and its assets. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final storage = ref.read(storageProvider);
    await storage.permanentlyDeleteFromTrash(key);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permanently deleted'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadTrash();
    }
  }

  Future<void> _emptyAll() async {
    if (_trash.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: Text(
          'This will permanently delete all ${_trash.length} item(s). '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Empty All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final storage = ref.read(storageProvider);
    for (final key in _trash.keys.toList()) {
      await storage.permanentlyDeleteFromTrash(key);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recycle bin emptied'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadTrash();
    }
  }

  String _formatDaysRemaining(String? expiresAtStr) {
    if (expiresAtStr == null) return '';
    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return '';
    final remaining = expiresAt.difference(DateTime.now().toUtc()).inDays;
    if (remaining <= 0) return 'Expires today';
    if (remaining == 1) return '1 day remaining';
    return '$remaining days remaining';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_trash.isNotEmpty)
            TextButton.icon(
              onPressed: _emptyAll,
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Empty All'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trash.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Recycle bin is empty',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deleted notes will appear here for 7 days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trash.length,
                  itemBuilder: (context, index) {
                    final key = _trash.keys.elementAt(index);
                    final item = _trash[key]!;
                    final category = item['category'] as String? ?? '';
                    final filename = item['filename'] as String? ?? key;
                    final deletedAt = item['deletedAt'] as String?;
                    final expiresAt = item['expiresAt'] as String?;

                    final deletedDate = deletedAt != null
                        ? DateFormat.yMMMd().add_jm().format(
                            DateTime.tryParse(deletedAt)?.toLocal() ??
                                DateTime.now())
                        : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor
                              .withValues(alpha: 0.1),
                          child: Icon(
                            Icons.description_outlined,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          filename.replaceAll('.md', '').replaceAll('_', ' '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$category • Deleted $deletedDate',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _formatDaysRemaining(expiresAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.restore,
                                color: Colors.green.shade600,
                              ),
                              onPressed: () => _restoreItem(key),
                              tooltip: 'Restore',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              onPressed: () => _permanentlyDelete(key),
                              tooltip: 'Delete permanently',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
