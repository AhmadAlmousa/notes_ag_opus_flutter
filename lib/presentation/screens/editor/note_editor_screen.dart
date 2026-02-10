import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sanitizers.dart';
import '../../../data/models/field.dart';
import '../../../data/models/note.dart';
import '../../../data/models/template.dart';
import '../../widgets/field_inputs/field_input_widget.dart';

/// Note editor screen with form-based entry.
class NoteEditorScreen extends StatefulWidget {
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
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  Note? _note;
  Template? _template;
  bool _isLoading = true;
  bool _isNew = true;
  bool _hasChanges = false;
  late List<Map<String, dynamic>> _records;
  late String _category;
  late List<String> _tags;
  late TextEditingController _titleController;
  Set<String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final appState = AppState.instance;

    if (widget.filename != null && widget.category != null) {
      // Editing existing note
      _note = appState.noteRepository.getNote(
        widget.category!,
        widget.filename!,
      );
      if (_note != null) {
        _template = appState.templateRepository.getById(_note!.templateId);
        _records = List.from(_note!.records.map((r) => Map<String, dynamic>.from(r)));
        _category = _note!.category;
        _tags = List.from(_note!.tags);
        _isNew = false;
        // Extract title from filename
        _titleController.text = _note!.filename.replaceAll('_', ' ');
      }
    } else if (widget.templateId != null) {
      // Creating new note
      _template = appState.templateRepository.getById(widget.templateId!);
      if (_template != null) {
        _note = appState.noteRepository.createNew(
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
      });
    }
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

  Future<void> _save() async {
    if (_template == null || _note == null) return;

    // Validate title  
    final errors = <String>{};
    if (_titleController.text.trim().isEmpty) {
      errors.add('title');
    }

    // Validate required fields and collect errors
    for (int i = 0; i < _records.length; i++) {
      final record = _records[i];
      for (final field in _template!.fields) {
        if (field.required &&
            (record[field.id] == null ||
                record[field.id].toString().isEmpty)) {
          errors.add('$i:${field.id}');
        }
      }
    }

    // If there are errors, show them and update state
    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors = errors;
      });
      
      if (errors.contains('title')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note title is required')),
        );
      } else {
        final missingFields = errors
            .where((e) => e.contains(':'))
            .map((e) {
              final parts = e.split(':');
              final field = _template!.fields.firstWhere(
                (f) => f.id == parts[1],
                orElse: () => _template!.fields.first,
              );
              return field.label;
            })
            .toSet()
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Missing required fields: $missingFields')),
        );
      }
      return;
    }

    // Generate filename from title
    final filename = Sanitizers.toFilename(_titleController.text.trim());

    final updatedNote = _note!.copyWith(
      filename: filename,
      category: _category,
      records: _records,
      tags: _tags,
      updatedAt: DateTime.now(),
    );

    await AppState.instance.noteRepository.save(updatedNote);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNew ? 'Note created!' : 'Note saved!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/notes/${updatedNote.category}/${updatedNote.filename}');
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

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
          title: Text(_isNew ? 'New Note' : 'Edit Note'),
          actions: [
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
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
        TextField(
          controller: _titleController,
          onChanged: (_) => _markChanged(),
          decoration: InputDecoration(
            hintText: 'Enter a title for this note',
            prefixIcon: const Icon(Icons.title),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 4),
        Text(
          'This will be used as the note filename',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    final categories = AppState.instance.noteRepository.getCategories();

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
        padding: const EdgeInsets.only(bottom: 16),
        child: _RecordForm(
          index: index,
          record: _records[index],
          fields: _template!.fields,
          canRemove: _records.length > 1,
          validationErrors: _validationErrors,
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
    required this.validationErrors,
    required this.onFieldChanged,
    required this.onRemove,
  });

  final int index;
  final Map<String, dynamic> record;
  final List<Field> fields;
  final bool canRemove;
  final Set<String> validationErrors;
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
          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: fields.map((field) {
                final hasError = validationErrors.contains('$index:${field.id}');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FieldInputWidget(
                    field: field,
                    value: record[field.id],
                    onChanged: (value) => onFieldChanged(field.id, value),
                    hasError: hasError,
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
