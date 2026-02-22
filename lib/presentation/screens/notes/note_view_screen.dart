import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/field.dart';
import '../../../data/models/note.dart';
import '../../../data/models/template.dart';

/// Note view screen with multiple layout options.
class NoteViewScreen extends StatefulWidget {
  const NoteViewScreen({
    super.key,
    required this.category,
    required this.filename,
  });

  final String category;
  final String filename;

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Note? _note;
  Template? _template;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final note = AppState.instance.noteRepository.getNote(
      widget.category,
      widget.filename,
    );

    Template? template;
    if (note != null) {
      template = AppState.instance.templateRepository.getById(note.templateId);
    }

    setState(() {
      _note = note;
      _template = template;
      _isLoading = false;
    });

    _animationController.forward();
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareNote() {
    // Build shareable text from note data
    final buffer = StringBuffer();
    buffer.writeln(_note!.getDisplayTitle(_template?.display.primaryField));
    buffer.writeln('---');
    
    for (var i = 0; i < _note!.records.length; i++) {
      if (_note!.records.length > 1) {
        buffer.writeln('Record ${i + 1}:');
      }
      final record = _note!.records[i];
      for (final entry in record.entries) {
        final fieldDef = _template?.fields.firstWhere(
          (f) => f.id == entry.key,
          orElse: () => Field(id: entry.key, type: FieldType.text, label: entry.key),
        );
        // Don't share password fields
        if (fieldDef?.type != FieldType.password) {
          buffer.writeln('${fieldDef?.label ?? entry.key}: ${entry.value}');
        }
      }
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied to clipboard for sharing'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: const Center(child: Text('Note not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _note!.category.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _template?.name ?? _note!.templateId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: _shareNote,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'View Source',
            onPressed: () => context.push(
              '/notes/${widget.category}/${widget.filename}/source',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              await context.push(
                '/notes/${widget.category}/${widget.filename}/edit',
              );
              _loadData();
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await AppState.instance.noteRepository.delete(
                    widget.category,
                    widget.filename,
                  );
                  if (mounted) context.go('/notes');
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Builds the AppBar title with icon, type, and category.
  Widget _buildAppBarTitle() {
    final hasEmoji = _note!.icon != null && _note!.icon!.isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasEmoji) ...[
          Text(_note!.icon!, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            _note!.getDisplayTitle(_template?.display.primaryField),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final layout = _template?.layout ?? TemplateLayout.cards;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags and record count
          _buildTagsAndCount(theme),
          const SizedBox(height: 16),

          // Records based on layout type
          if (_note!.records.isEmpty)
            _buildEmptyRecords(theme)
          else if (layout == TemplateLayout.table)
            _buildTableLayout(theme)
          else if (layout == TemplateLayout.grid)
            _buildGridLayout(theme)
          else
            _buildRecordsList(theme),
        ],
      ),
    );
  }

  Widget _buildTableLayout(ThemeData theme) {
    final fields = _template?.fields ?? [];

    // Build column headers — for customLabel fields, show user-defined label from first record
    final columns = <DataColumn>[];
    for (final field in fields) {
      String colLabel = field.label;
      if (field.type == FieldType.customLabel && _note!.records.isNotEmpty) {
        final firstLabel = _note!.records.first['${field.id}_label']?.toString();
        if (firstLabel != null && firstLabel.isNotEmpty) {
          colLabel = firstLabel;
        }
      }
      columns.add(DataColumn(
        label: Text(colLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
            columns: columns,
            rows: List.generate(_note!.records.length, (index) {
              final record = _note!.records[index];
              return DataRow(
                cells: [
                  ...fields.map((field) {
                    String value;
                    if (field.type == FieldType.customLabel) {
                      value = record['${field.id}_value']?.toString() ?? '';
                    } else {
                      value = record[field.id]?.toString() ?? '';
                    }
                    return DataCell(
                      _buildTableCellContent(theme, field, value),
                      onTap: () => _copyToClipboard(value, field.label),
                    );
                  }),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCellContent(ThemeData theme, Field field, String value) {
    if (value.isEmpty) {
      return Text(
        '-',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    switch (field.type) {
      case FieldType.password:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('•' * value.length.clamp(4, 8)),
            const SizedBox(width: 4),
            const Icon(Icons.copy, size: 12),
          ],
        );
      
      case FieldType.boolean:
        final boolVal = value == 'true';
        return Icon(
          boolVal ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: boolVal ? Colors.green : Colors.red,
        );
      
      case FieldType.url:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              value.length > 30 ? '${value.substring(0, 30)}...' : value,
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ],
        );
      
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.length > 40 ? '${value.substring(0, 40)}...' : value,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.copy,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        );
    }
  }

  Widget _buildTagsAndCount(ThemeData theme) {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_note!.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _note!.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '${_note!.records.length} record${_note!.records.length != 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecords(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No records',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(ThemeData theme) {
    return Column(
      children: List.generate(_note!.records.length, (index) {
        final record = _note!.records[index];
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (0.2 + 0.1 * index).clamp(0.0, 1.0),
            (0.5 + 0.1 * index).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRecordCard(theme, record, index),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGridLayout(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptive columns: ~300px per column
        final crossAxisCount = (constraints.maxWidth / 300).floor().clamp(1, 4);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_note!.records.length, (index) {
            final record = _note!.records[index];
            final width = (constraints.maxWidth - (crossAxisCount - 1) * 12) /
                crossAxisCount;

            return SizedBox(
              width: width,
              child: _buildRecordCard(theme, record, index),
            );
          }),
        );
      },
    );
  }

  /// Returns the title for a record card based on the first field value.
  String _getRecordTitle(Map<String, dynamic> record, int index) {
    final fields = _template?.fields ?? [];
    if (fields.isNotEmpty && record.isNotEmpty) {
      final firstField = fields.first;
      String? firstValue;
      if (firstField.type == FieldType.customLabel) {
        firstValue = record['${firstField.id}_value']?.toString();
      } else {
        firstValue = record[firstField.id]?.toString();
      }
      if (firstValue != null && firstValue.isNotEmpty) {
        return firstValue;
      }
    }
    return 'Record ${index + 1}';
  }

  Widget _buildRecordCard(
    ThemeData theme,
    Map<String, dynamic> record,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getRecordTitle(record, index),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Action buttons from template
                if (_template?.actions.isNotEmpty == true)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _template!.actions.map((action) {
                      final fieldValue = record[action.field]?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _ActionButton(
                          action: action,
                          value: fieldValue,
                          onCopy: () => _copyToClipboard(fieldValue, action.label),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _buildFieldRows(theme, record),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldRows(
    ThemeData theme,
    Map<String, dynamic> record,
  ) {
    final fields = _template?.fields ?? [];
    final List<Widget> rows = [];

    for (final fieldDef in fields) {
      // For customLabel, get user label and value from flat keys
      String displayLabel = fieldDef.label;
      dynamic displayValue;
      if (fieldDef.type == FieldType.customLabel) {
        final userLabel = record['${fieldDef.id}_label']?.toString();
        if (userLabel != null && userLabel.isNotEmpty) {
          displayLabel = userLabel;
        }
        displayValue = record['${fieldDef.id}_value'];
      } else {
        displayValue = record[fieldDef.id];
      }

      rows.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getFieldIcon(fieldDef.type),
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              // Field content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildFieldValue(theme, fieldDef, displayValue),
                  ],
                ),
              ),
              // Copy button
              IconButton(
                icon: Icon(
                  Icons.copy,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                onPressed: () => _copyToClipboard(
                  displayValue?.toString() ?? '',
                  displayLabel,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Copy $displayLabel',
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  IconData _getFieldIcon(FieldType type) {
    switch (type) {
      case FieldType.text:
        return Icons.title;
      case FieldType.number:
        return Icons.numbers;
      case FieldType.digits:
        return Icons.pin;
      case FieldType.date:
        return Icons.calendar_today;
      case FieldType.dropdown:
        return Icons.arrow_drop_down_circle;
      case FieldType.boolean:
        return Icons.toggle_on;
      case FieldType.url:
        return Icons.link;
      case FieldType.ip:
        return Icons.dns;
      case FieldType.password:
        return Icons.lock;
      case FieldType.regex:
        return Icons.rule;
      case FieldType.customLabel:
        return Icons.label_outline;
    }
  }

  Widget _buildFieldValue(
    ThemeData theme,
    Field field,
    dynamic value,
  ) {
    if (value == null || value.toString().isEmpty) {
      return Text(
        '-',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    switch (field.type) {
      case FieldType.password:
        return _PasswordField(value: value.toString());

      case FieldType.date:
        final dateStr = value.toString();
        final (datePart, format) = AppDateUtils.parseFromStorage(dateStr);
        final displayText = format == 'hijri'
            ? '$datePart (Hijri)'
            : datePart;
        return Text(
          displayText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        );

      case FieldType.url:
        return GestureDetector(
          onTap: () {
            // TODO: Open URL
          },
          child: Text(
            value.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
        );

      case FieldType.boolean:
        final boolVal = value == true || value == 'true';
        return Row(
          children: [
            Icon(
              boolVal ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: boolVal ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              boolVal ? 'Yes' : 'No',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case FieldType.customLabel:
        return Text(
          value?.toString() ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        );

      default:
        return Text(
          value.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.value});

  final String value;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            _isVisible ? widget.value : '•' * widget.value.length.clamp(8, 16),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _isVisible ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => setState(() => _isVisible = !_isVisible),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          tooltip: _isVisible ? 'Hide password' : 'Show password',
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.value,
    required this.onCopy,
  });

  final dynamic action;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onCopy,
      icon: const Icon(Icons.copy, size: 14),
      label: Text(
        action.label,
        style: const TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
