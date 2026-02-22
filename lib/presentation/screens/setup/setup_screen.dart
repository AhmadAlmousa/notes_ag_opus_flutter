import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/fs_interop.dart';

/// First-run setup screen for selecting storage location.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _loading = false;
  String? _selectedPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final name = await FileSystemInterop.pickDirectory();
      await FileSystemInterop.initDirectories();
      setState(() {
        _selectedPath = name;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access directory: $e';
        _loading = false;
      });
    }
  }

  Future<void> _useOPFS() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final name = await FileSystemInterop.useOPFS();
      await FileSystemInterop.initDirectories();
      setState(() {
        _selectedPath = name;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not initialize storage: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFSA = FileSystemInterop.isFileSystemAccessSupported;
    final hasOPFS = FileSystemInterop.isOPFSSupported;

    return Scaffold(
      body: FadeTransition(
        opacity: _animationController,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFFA29BFE)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Welcome to Organote',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Choose where to store your notes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Option 1: Local Directory (FSA)
                  if (hasFSA) ...[
                    _StorageOptionCard(
                      icon: Icons.folder_open,
                      title: 'Local Directory',
                      description:
                          'Pick a folder on your device. Notes are stored as .md files you can access anytime.',
                      badge: 'Recommended',
                      badgeColor: Colors.green,
                      onTap: _loading ? null : _pickDirectory,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Option 2: OPFS (Browser Storage)
                  if (hasOPFS)
                    _StorageOptionCard(
                      icon: Icons.cloud_outlined,
                      title: 'App Storage',
                      description: hasFSA
                          ? 'Uses browser\'s private file system. Files are only accessible within the app.'
                          : 'Automatically stores your notes in the browser\'s private file system.',
                      badge: hasFSA ? null : 'Recommended',
                      badgeColor: Colors.green,
                      onTap: _loading ? null : _useOPFS,
                    ),

                  if (!hasFSA && !hasOPFS) ...[
                    _StorageOptionCard(
                      icon: Icons.storage_outlined,
                      title: 'Browser Storage',
                      description:
                          'Your browser does not support advanced file storage. Notes will be stored in browser local storage.',
                      onTap: _loading ? null : widget.onComplete,
                    ),
                  ],

                  if (_loading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_selectedPath != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Storage Ready',
                                style:
                                    theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPath!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StorageOptionCard extends StatelessWidget {
  const _StorageOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? AppTheme.primaryColor)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  badgeColor ?? AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
