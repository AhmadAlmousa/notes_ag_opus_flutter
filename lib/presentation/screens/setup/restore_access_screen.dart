import 'package:flutter/material.dart';

import 'package:organote/core/theme/app_theme.dart';
import 'package:organote/data/services/file_system_storage_service.dart';
import 'package:organote/data/services/fs_interop.dart';

/// Shown when the browser needs a user gesture to re-grant file system access.
///
/// This happens when the app uses the File System Access API and the page
/// is reloaded — Chromium requires a physical click before calling
/// `requestPermission()` on the saved directory handle.
class RestoreAccessScreen extends StatefulWidget {
  const RestoreAccessScreen({super.key, required this.onRestored});

  /// Called when access is successfully restored.
  final VoidCallback onRestored;

  @override
  State<RestoreAccessScreen> createState() => _RestoreAccessScreenState();
}

class _RestoreAccessScreenState extends State<RestoreAccessScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _requestAccess() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final name = await FileSystemInterop.requestPermissionInteractive();
      if (name != null) {
        await FileSystemInterop.initDirectories();
        FileSystemStorageService.needsUserActivation = false;
        widget.onRestored();
      } else {
        setState(() {
          _error = 'Permission was denied. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to restore access: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Restore Folder Access',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your browser requires permission to access your Notes folder.\n'
                  'Click the button below to re-grant access.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: 280,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _requestAccess,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(_loading ? 'Granting access...' : 'Restore Access'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
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
