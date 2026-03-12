import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../../core/compliance_checker.dart';
import '../../../data/services/fs_interop.dart';
import '../../../data/services/file_system_storage_service.dart';
import '../../../core/providers.dart';
import '../../../core/export_import_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/dialogs/sync_conflict_dialog.dart';
import '../../widgets/google_sign_in_button_stub.dart'
    if (dart.library.js_interop) '../../widgets/google_sign_in_button_web.dart'
    as gsi_button;


/// Settings screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FadeTransition(
        opacity: _animationController,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize your experience',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Compliance section
                    _buildComplianceSection(context),

                    const SizedBox(height: 16),

                    // Appearance section
                    _buildSection(
                      context,
                      'Appearance',
                      Icons.palette_outlined,
                      [
                        _buildThemeSetting(context),
                        SwitchListTile(
                          title: const Text('Show Passwords'),
                          subtitle: const Text('Reveal password fields globally'),
                          value: ref.watch(showPasswordsProvider),
                          onChanged: (_) => ref.read(showPasswordsProvider.notifier).toggle(),
                          secondary: const Icon(Icons.visibility),
                          dense: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Language section
                    _buildSection(
                      context,
                      'Language',
                      Icons.language,
                      [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Center(
                            child: SegmentedButton<String>(
                              selected: {
                                ref.watch(localeProvider)?.languageCode ?? 'en',
                              },
                              segments: const [
                                ButtonSegment(
                                  value: 'en',
                                  label: Text('English'),
                                ),
                                ButtonSegment(
                                  value: 'ar',
                                  label: Text('العربية'),
                                ),
                              ],
                              onSelectionChanged: (selection) {
                                final code = selection.first;
                                setLocale(ref, Locale(code));
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                textStyle: WidgetStateProperty.all(
                                  const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Data section
                    _buildSection(
                      context,
                      'Data',
                      Icons.storage_outlined,
                      [
                        _buildInfoTile(
                          context,
                          'Templates',
                          '${ref.read(templateRepoProvider).getAll().length} created',
                          Icons.extension_outlined,
                        ),
                        _buildInfoTile(
                          context,
                          'Notes',
                          '${ref.read(noteRepoProvider).getAll().length} saved',
                          Icons.note_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),


                    // Recycle Bin section
                    Builder(builder: (context) {
                      final trashItems = ref.read(noteRepoProvider).getTrash();
                      return _buildSection(
                        context,
                        'Recycle Bin',
                        Icons.delete_outline,
                        [
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.restore_from_trash,
                              color: trashItems.isEmpty
                                  ? theme.colorScheme.onSurfaceVariant
                                  : Colors.orange,
                              size: 22,
                            ),
                            title: Text(
                              trashItems.isEmpty
                                  ? 'No deleted notes'
                                  : '${trashItems.length} deleted note${trashItems.length != 1 ? 's' : ''}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            subtitle: trashItems.isEmpty
                                ? null
                                : Text(
                                    'Auto-purged after 7 days',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                            trailing: TextButton(
                              onPressed: () => context.push('/recycle-bin'),
                              child: const Text('View'),
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 16),

                    // Storage section
                    _buildSection(
                      context,
                      'Storage',
                      Icons.folder_outlined,
                      [
                        _buildInfoTile(
                          context,
                          'Storage Type',
                          _getStorageLabel(ref.read(storageTypeProvider)),
                          Icons.dns_outlined,
                        ),
                        if (ref.read(storageDirectoryPathProvider) != null)
                          _buildInfoTile(
                            context,
                            'Directory',
                            ref.read(storageDirectoryPathProvider)!,
                            Icons.folder_open,
                          ),
                        if (!kIsWeb && ref.read(storageTypeProvider) == 'local')
                          _buildChangeDirectoryButton(context),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Import/Export section
                    _buildSection(
                      context,
                      'Import / Export',
                      Icons.import_export,
                      [
                        _buildImportExportButtons(context),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Cloud Sync section
                    _buildSection(
                      context,
                      'Cloud Sync',
                      Icons.cloud_sync_outlined,
                      [
                        _buildSyncSettings(context),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // About section
                    _buildSection(
                      context,
                      'About',
                      Icons.info_outlined,
                      [
                        _buildInfoTile(
                          context,
                          'Version',
                          '1.2.0',
                          Icons.tag,
                        ),
                        _buildInfoTile(
                          context,
                          'Built with',
                          'Flutter',
                          Icons.flutter_dash,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Danger zone
                    _buildDangerZone(context),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceSection(BuildContext context) {
    final theme = Theme.of(context);
    final allNotes = ref.read(noteRepoProvider).getAll();
    final templates = ref.read(templateRepoProvider).getAll();
    final templateMap = {for (final t in templates) t.templateId: t};
    final compliance = ComplianceChecker.checkAll(allNotes, templateMap);
    final isHealthy = compliance.isHealthy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withValues(alpha: 0.06)
            : Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHealthy
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                color: isHealthy ? Colors.green.shade600 : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Compliance Check',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isHealthy ? Colors.green.shade700 : Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isHealthy)
            Text(
              'All notes are compliant with their templates. ✓',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
              ),
            )
          else ...[
            Text(
              compliance.statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...compliance.issues.take(5).map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${issue.note.getDisplayTitle()} — ${issue.summary}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            if (compliance.issues.length > 5)
              Text(
                '...and ${compliance.issues.length - 5} more issues.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeSetting(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Center(
        child: SegmentedButton<String>(
            selected: {
              ref.watch(isOledModeProvider) ? 'oled' : ref.watch(themeModeProvider).name,
            },
            onSelectionChanged: (selection) {
              final value = selection.first;
              if (value == 'oled') {
                ref.read(themeModeProvider.notifier).setOledMode();
              } else {
                ref.read(themeModeProvider.notifier).setThemeMode(
                  ThemeMode.values.firstWhere((m) => m.name == value),
                );
              }
            },
            segments: const [
              ButtonSegment(
                value: 'system',
                icon: Icon(Icons.brightness_auto, size: 18),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: 'light',
                icon: Icon(Icons.light_mode, size: 18),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: 'dark',
                icon: Icon(Icons.dark_mode, size: 18),
                label: Text('Dark'),
              ),
              ButtonSegment(
                value: 'oled',
                icon: Icon(Icons.brightness_1, size: 18),
                label: Text('OLED'),
              ),
            ],
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ),
    );
  }

  void _showRecycleBinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          final trashItems = ref.read(noteRepoProvider).getTrash();
          final theme = Theme.of(ctx);

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.delete_outline, size: 22),
                const SizedBox(width: 8),
                const Text('Recycle Bin'),
                const Spacer(),
                if (trashItems.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      for (final item in trashItems) {
                        await ref.read(noteRepoProvider).permanentlyDelete(
                            item['key'] as String);
                      }
                      setDialogState(() {});
                      setState(() {});
                    },
                    child: const Text('Empty All',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            content: SizedBox(
              width: 400,
              height: 400,
              child: trashItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('Recycle bin is empty',
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: trashItems.length,
                      itemBuilder: (ctx, index) {
                        final item = trashItems[index];
                        final category = item['category'] as String? ?? '';
                        final filename = item['filename'] as String? ?? '';
                        final deletedAt = item['deletedAt'] as DateTime?;
                        final expiresAt = item['expiresAt'] as DateTime?;

                        final daysLeft = expiresAt != null
                            ? expiresAt
                                .difference(DateTime.now().toUtc())
                                .inDays
                            : 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.description_outlined,
                                color: theme.colorScheme.onSurfaceVariant),
                            title: Text(
                              filename.replaceAll('.md', ''),
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '$category • ${daysLeft}d left',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: daysLeft <= 1
                                    ? Colors.red
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore, size: 20),
                                  tooltip: 'Restore',
                                  onPressed: () async {
                                    await ref
                                        .read(noteRepoProvider)
                                        .restoreFromTrash(
                                            item['key'] as String);
                                    setDialogState(() {});
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever,
                                      size: 20, color: Colors.red),
                                  tooltip: 'Delete permanently',
                                  onPressed: () async {
                                    await ref
                                        .read(noteRepoProvider)
                                        .permanentlyDelete(
                                            item['key'] as String);
                                    setDialogState(() {});
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeDirectoryButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _handleChangeDirectory(context),
          icon: const Icon(Icons.drive_file_move_outline),
          label: const Text('Change Directory'),
        ),
      ),
    );
  }

  Future<void> _handleChangeDirectory(BuildContext context) async {
    if (!kIsWeb) {
      if (await Permission.manageExternalStorage.isDenied ||
          await Permission.storage.isDenied) {
        await [Permission.manageExternalStorage, Permission.storage].request();
      }
    }
    
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select new folder to move your notes',
    );
    if (dirPath == null) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Moving files...'),
          ],
        ),
      ),
    );

    try {
      await FileSystemInterop.changeDirectory(dirPath);
      if (context.mounted) {
        Navigator.pop(context); // close dialog
        
        // Refresh providers
        await FileSystemStorageService.getInstance().then((s) => s.refreshCaches());
        ref.invalidate(appInitProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Directory changed and files moved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImportExportButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ExportImportService.exportNotesToZip(
                context,
                storage: ref.read(storageProvider),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Export All Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ExportImportService.importFromZip(
                context,
                storage: ref.read(storageProvider),
                noteRepo: ref.read(noteRepoProvider),
              ),
              icon: const Icon(Icons.upload),
              label: const Text('Import Notes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Export creates a zip file with all notes and templates.\nImport merges with existing data.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSettings(BuildContext context) {
    final theme = Theme.of(context);
    final storage = ref.read(storageProvider);
    final isConnected = ref.watch(syncStatusProvider);
    final syncService = ref.read(syncServiceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? Colors.green : Colors.red.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isConnected ? Colors.green : Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isConnected && syncService.accountEmail != null)
                      Text(
                        syncService.accountEmail!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Sync your notes and templates across devices using your Google Drive account. '
            'Files are stored in an "Organote" folder.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (!isConnected) ...[
            if (kIsWeb) ...[
              // Web: Use Google's native FedCM button (no popups, immune to COOP/COEP)
              Center(
                child: _buildGoogleSignInButton(syncService, storage),
              ),
            ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await syncService.signIn(storage: storage);
                  if (success) {
                    await _handlePostSignIn(syncService, storage);
                  }
                  if (context.mounted) {
                    final errorMsg = syncService.lastAuthError;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Connected to Google Drive!'
                            : errorMsg ?? 'Sign-in cancelled or failed.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                        duration: Duration(seconds: success ? 3 : 6),
                      ),
                    );
                  }
                  setState(() {});
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await syncService.signOut();
                      // State auto-updates via syncStateProvider
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await syncService.syncAll();
                      if (context.mounted) {
                        // Refresh caches after sync
                        try {
                          ref.read(noteRepoProvider).clearCache();
                          ref.read(templateRepoProvider).clearCache();
                        } catch (_) {}
                        ref.read(syncTriggerProvider.notifier).trigger();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sync complete!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showClearDataDialog(context),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all your templates and notes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
               await ref.read(storageProvider).clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getStorageLabel(String type) {
    switch (type) {
      case 'fsa':
        return 'Local Directory';
      case 'opfs':
        return 'App Storage (OPFS)';
      case 'local':
        return 'Browser Storage';
      default:
        return 'Browser Storage';
    }
  }

  // ── FedCM / Google Sign-In helpers ─────────────────────────────────

  /// Build Google's native FedCM sign-in button for web.
  /// The syncService auth listener handles auth events automatically.
  Widget _buildGoogleSignInButton(
    dynamic syncService,
    dynamic storage,
  ) {
    if (!kIsWeb) return const SizedBox.shrink();
    return _buildWebRenderButton();
  }

  /// Returns Google's native renderButton widget.
  Widget _buildWebRenderButton() {
    return gsi_button.buildGoogleSignInButtonPlatform();
  }

  /// Common post-sign-in logic: conflict dialog, remote change callback, initial pull.
  Future<void> _handlePostSignIn(dynamic syncService, dynamic storage) async {
    bool shouldSync = true;
    final templates = storage.getTemplates() as Map;
    final notes = storage.getNotes() as Map;

    if (templates.isNotEmpty || notes.isNotEmpty) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => SyncConflictDialog(storage: storage),
        );
        shouldSync = result == true;
      }
    }

    if (!shouldSync) {
      await syncService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync cancelled.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {});
      }
      return;
    }

    // onRemoteChange is wired up in initSync (root app ref) — not here

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Syncing with Google Drive...'),
            ],
          ),
        ),
      );
    }

    await syncService.pullAll();

    if (mounted) {
      Navigator.pop(context); // close dialog
    }

    // State auto-updates via syncStateProvider
  }
}
