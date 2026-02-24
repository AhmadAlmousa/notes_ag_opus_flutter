import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sanitizers.dart';
import '../../../data/models/field.dart';
import '../../../data/models/note.dart';
import '../../../data/models/template.dart';
import '../../widgets/common/emoji_picker_dialog.dart';
import '../../widgets/field_inputs/field_input_widget.dart';

/// Auto-save state indicator.
enum _SaveState { unsaved, saving, saved }

/// Note editor screen with form-based entry and debounced auto-save.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.templateId,
    this.category,
    this.filename,
  });

  final String? templateId;
  final String? category;
  final String? filename;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  Note? _note;
  Template? _template;
  bool _isLoading = true;
  bool _isNew = true;
  bool _hasChanges = false;
  _SaveState _saveState = _SaveState.unsaved;
  Timer? _autoSaveTimer;
  late List<Map<String, dynamic>> _records;
  late String _category;
  late List<String> _tags;
  late TextEditingController _titleController;
  String? _icon;
  String? _originalCategory;
  String? _originalFilename;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Trigger a final save if there are unsaved changes
    if (_hasChanges && _note != null && _template != null) {
      _performSave(navigate: false);
    }
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {

    if (widget.filename != null && widget.category != null) {
      // Editing existing note
      _note = ref.read(noteRepoProvider).getNote(
        widget.category!,
        widget.filename!,
      );
      if (_note != null) {
        _template = ref.read(templateRepoProvider).getById(_note!.templateId);
        _records = List.from(_note!.records.map((r) => Map<String, dynamic>.from(r)));
        _category = _note!.category;
        _tags = List.from(_note!.tags);
        _isNew = false;
        _icon = _note!.icon;
        _originalCategory = _note!.category;
        _originalFilename = _note!.filename;
        // Use explicit title if available, otherwise derive from filename
        _titleController.text = _note!.title ?? 
            _note!.getDisplayTitle(_template?.display.primaryField);
      }
    } else if (widget.templateId != null) {
      // Creating new note
      _template = ref.read(templateRepoProvider).getById(widget.templateId!);
      if (_template != null) {
        _note = ref.read(noteRepoProvider).createNew(
          templateId: widget.templateId!,
          category: widget.category ?? _template!.defaultFolder ?? 'personal',
          templateVersion: _template!.version,
        );
        _records = [{}]; // Start with one empty record
        _category = _note!.category;
        _tags = [];
        _titleController.text = '';
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
        _saveState = _SaveState.unsaved;
      });
    }
    // Restart the 2-second auto-save debounce timer
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  /// Silently auto-saves without navigation or snackbar.
  Future<void> _autoSave() async {
    if (!mounted || _template == null || _note == null) return;
    if (_titleController.text.trim().isEmpty) return; // Don't auto-save without title
    setState(() => _saveState = _SaveState.saving);
    await _performSave(navigate: false);
    if (mounted) setState(() => _saveState = _SaveState.saved);
  }

  void _updateFieldValue(int recordIndex, String fieldId, dynamic value) {
    _records[recordIndex][fieldId] = value;
    _markChanged();
  }

  void _addRecord() {
    setState(() {
      _records.add({});
      _hasChanges = true;
    });
  }

  void _removeRecord(int index) {
    if (_records.length > 1) {
      setState(() {
        _records.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  /// Generates a collision-safe filename from the note title.
  /// If a note with the same filename already exists in the category
  /// (and it's not the same note being edited), appends a timestamp.
  String _generateSafeFilename(String title) {
    final base = Sanitizers.toFilename(title);
    final candidate = '$base.md';

    // For existing notes keeping the same title, preserve the filename
    if (!_isNew && _originalFilename == candidate) return candidate;

    // Check if filename already exists in this category
    final repo = ref.read(noteRepoProvider);
    final existing = repo.getNote(_category, candidate);
    if (existing == null) return candidate;

    // Collision detected: append timestamp
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${base}_$ts.md';
  }

  /// Explicit save — validates, saves, and navigates to the note view.
  Future<void> _save() async {
    if (_template == null || _note == null) return;

    // Trigger form validation
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before saving')),
      );
      return;
    }

    _autoSaveTimer?.cancel();
    setState(() => _saveState = _SaveState.saving);

    await _performSave(navigate: true);
  }

  /// Core save logic — reused by both auto-save and explicit save.
  Future<void> _performSave({required bool navigate}) async {
    if (_template == null || _note == null) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final filename = _generateSafeFilename(title);

    final updatedNote = _note!.copyWith(
      title: title,
      icon: _icon,
      filename: filename,
      category: _category,
      records: _records,
      tags: _tags,
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(noteRepoProvider);
    await repo.save(updatedNote);

    // Delete old file if category or filename changed (prevents duplicates)
    if (!_isNew && _originalCategory != null && _originalFilename != null) {
      final categoryChanged = _originalCategory != _category;
      final filenameChanged = _originalFilename != filename;
      if (categoryChanged || filenameChanged) {
        await repo.delete(_originalCategory!, _originalFilename!);
        // Push deletion of old path to cloud
        final syncService = ref.read(syncServiceProvider);
        syncService.pushDeletion('notes/$_originalCategory/$_originalFilename');
      }
    }

    // Push to cloud
    final syncService = ref.read(syncServiceProvider);
    syncService.pushDocument(
      'notes/${updatedNote.category}/${updatedNote.filename}',
      updatedNote.toMarkdown(),
    );

    // Update tracking for subsequent saves
    _originalCategory = _category;
    _originalFilename = filename;
    _hasChanges = false;
    if (_isNew) _isNew = false;

    if (navigate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/notes/${updatedNote.category}/${updatedNote.filename}');
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    // Auto-save before leaving instead of discarding
    if (_titleController.text.trim().isNotEmpty) {
      await _performSave(navigate: false);
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor')),
        body: const Center(child: Text('Template not found')),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isNew ? 'New Note' : 'Edit Note'),
              if (_saveState == _SaveState.saving) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                Text('Saving...', style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
              ] else if (_saveState == _SaveState.saved) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text('Saved', style: TextStyle(
                  fontSize: 12, color: Colors.green.shade600,
                )),
              ],
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.extension,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _template!.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Note title field
              _buildTitleField(theme),

              const SizedBox(height: 16),

              // Category selector
              _buildCategorySelector(theme),

              const SizedBox(height: 20),

              // Records section header
              Text(
                'Records',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Records
              ..._buildRecords(theme),

              // Add record button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addRecord,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Record'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Title',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Emoji icon button
            GestureDetector(
              onTap: () async {
                final emoji = await EmojiPickerDialog.show(
                  context,
                  currentEmoji: _icon,
                );
                if (emoji != null) {
                  setState(() {
                    _icon = emoji.isEmpty ? null : emoji;
                    _hasChanges = true;
                  });
                }
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: _icon != null && _icon!.isNotEmpty
                      ? Text(_icon!, style: const TextStyle(fontSize: 24))
                      : Icon(
                          Icons.emoji_emotions_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title text field
            Expanded(
              child: TextFormField(
                controller: _titleController,
                onChanged: (_) => _markChanged(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Note title is required'
                    : null,
                decoration: InputDecoration(
                  hintText: 'Enter a title for this note',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap the icon to set an emoji • Title is used as filename',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    final categories = ref.read(noteRepoProvider).getCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = category == _category;
            return FilterChip(
              label: Text(category[0].toUpperCase() + category.substring(1)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _category = category;
                    _hasChanges = true;
                  });
                }
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildRecords(ThemeData theme) {
    return List.generate(_records.length, (index) {
      return Padding(
        key: ValueKey('record_$index'),
        padding: const EdgeInsets.only(bottom: 16),
        child: _RecordForm(
          index: index,
          record: _records[index],
          fields: _template!.fields,
          canRemove: _records.length > 1,
          onFieldChanged: (fieldId, value) =>
              _updateFieldValue(index, fieldId, value),
          onRemove: () => _removeRecord(index),
        ),
      );
    });
  }
}

class _RecordForm extends StatelessWidget {
  const _RecordForm({
    required this.index,
    required this.record,
    required this.fields,
    required this.canRemove,
    required this.onFieldChanged,
    required this.onRemove,
  });

  final int index;
  final Map<String, dynamic> record;
  final List<Field> fields;
  final bool canRemove;
  final Function(String, dynamic) onFieldChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Record ${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (canRemove)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: 'Remove record',
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: fields.map((field) {
                // For customLabel fields, assemble a Map from flat keys
                dynamic fieldValue = record[field.id];
                if (field.type == FieldType.customLabel) {
                  fieldValue = {
                    'label': record['${field.id}_label']?.toString() ?? '',
                    'value': record['${field.id}_value']?.toString() ?? '',
                  };
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FieldInputWidget(
                    field: field,
                    value: fieldValue,
                    onChanged: (value) {
                      if (field.type == FieldType.customLabel && value is Map) {
                        // Split back to flat keys
                        onFieldChanged('${field.id}_label', value['label'] ?? '');
                        onFieldChanged('${field.id}_value', value['value'] ?? '');
                      } else {
                        onFieldChanged(field.id, value);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
