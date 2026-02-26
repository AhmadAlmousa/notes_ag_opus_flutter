import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/storage_service.dart';

class SyncConflictDialog extends StatefulWidget {
  const SyncConflictDialog({
    super.key,
    required this.storage,
  });

  final StorageService storage;

  @override
  State<SyncConflictDialog> createState() => _SyncConflictDialogState();
}

class _SyncConflictDialogState extends State<SyncConflictDialog> {
  final Set<String> _selectedTemplates = {};
  final Set<String> _selectedNotes = {};

  late Map<String, String> _templates;
  late Map<String, String> _notes;

  @override
  void initState() {
    super.initState();
    _templates = widget.storage.getTemplates();
    _notes = widget.storage.getNotes();

    // Default: select all
    _selectedTemplates.addAll(_templates.keys);
    _selectedNotes.addAll(_notes.keys);
  }

  @override
  Widget build(BuildContext context) {
    if (_templates.isEmpty && _notes.isEmpty) {
      return const SizedBox.shrink(); // Not technically possible if show logic is correct
    }

    return AlertDialog(
      title: const Text('Local Data found'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have existing local templates or notes. Select the ones you want to KEEP before syncing with Google Drive.',
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (_templates.isNotEmpty) ...[
                    const Text('Templates', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._templates.keys.map((id) => CheckboxListTile(
                          title: Text(id),
                          dense: true,
                          value: _selectedTemplates.contains(id),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedTemplates.add(id);
                              } else {
                                _selectedTemplates.remove(id);
                              }
                            });
                          },
                        )),
                    const SizedBox(height: 16),
                  ],
                  if (_notes.isNotEmpty) ...[
                    const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._notes.keys.map((path) => CheckboxListTile(
                          title: Text(path),
                          dense: true,
                          value: _selectedNotes.contains(path),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedNotes.add(path);
                              } else {
                                _selectedNotes.remove(path);
                              }
                            });
                          },
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Cancel sync
          child: const Text('Cancel Sync'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Delete unselected templates
            for (final id in _templates.keys) {
              if (!_selectedTemplates.contains(id)) {
                await widget.storage.deleteTemplate(id);
              }
            }
            // Delete unselected notes
            for (final path in _notes.keys) {
              if (!_selectedNotes.contains(path)) {
                final parts = path.split('/');
                await widget.storage.deleteNote(parts[0], parts[1]);
              }
            }
            if (context.mounted) {
              Navigator.pop(context, true); // Proceed
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sync & Keep Selected'),
        ),
      ],
    );
  }
}
