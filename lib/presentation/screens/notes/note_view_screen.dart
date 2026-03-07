import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/field.dart';
import '../../../data/models/note.dart';
import '../../../data/models/template.dart';
import '../../../data/services/fs_interop.dart';

/// Note view screen with multiple layout options.
class NoteViewScreen extends ConsumerStatefulWidget {
  const NoteViewScreen({
    super.key,
    required this.category,
    required this.filename,
  });

  final String category;
  final String filename;

  @override
  ConsumerState<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends ConsumerState<NoteViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Note? _note;
  Template? _template;
  bool _isLoading = true;
  // Track which record indices are collapsed
  final Set<int> _collapsedCards = {};

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
    final note = ref.read(noteRepoProvider).getNote(
      widget.category,
      widget.filename,
    );

    Template? template;
    if (note != null) {
      template = ref.read(templateRepoProvider).getById(note.templateId);
    }

    if (!mounted) return;
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
    // Reload data when remote sync changes arrive
    ref.listen(syncTriggerProvider, (_, __) => _loadData());

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
          PopupMenuButton<String>(
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20, color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 8),
                    const Text('Share'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'source',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 20, color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 8),
                    const Text('View Source'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
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
              if (value == 'share') {
                _shareNote();
              } else if (value == 'source') {
                context.push(
                  '/notes/${widget.category}/${widget.filename}/source',
                );
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note?'),
                    content: const Text(
                        'The note will be moved to the recycle bin '
                        'and permanently deleted after 7 days.'),
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
                  await ref.read(noteRepoProvider).delete(
                    widget.category,
                    widget.filename,
                  );
                  // Sync deletion to cloud
                  ref.read(syncServiceProvider).pushDeletion(
                    'notes/${widget.category}/${widget.filename}',
                  );
                  // Notify listening screens to rebuild
                  ref.read(syncTriggerProvider.notifier).trigger();
                  if (mounted) context.go('/');
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
                color: WidgetStateProperty.resolveWith<Color?>(
                  (states) => index.isOdd
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                      : null,
                ),
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
      
      case FieldType.image:
        return GestureDetector(
          onTap: () => _showImageDialog(context, value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(
                'View',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
                return ActionChip(
                  avatar: Icon(
                    Icons.label_outline,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  label: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => context.push('/notes?tag=${Uri.encodeComponent(tag)}'),
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
    final allCollapsed = _note!.records.isNotEmpty &&
        _collapsedCards.length == _note!.records.length;
    return Column(
      children: [
        // Collapse/expand-all toolbar
        if (_note!.records.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(allCollapsed ? Icons.unfold_more : Icons.unfold_less, size: 16),
                  label: Text(allCollapsed ? 'Expand All' : 'Collapse All', style: const TextStyle(fontSize: 12)),
                  onPressed: () => setState(() {
                    if (allCollapsed) {
                      _collapsedCards.clear();
                    } else {
                      _collapsedCards.addAll(List.generate(_note!.records.length, (i) => i));
                    }
                  }),
                ),
              ],
            ),
          ),
        ...List.generate(_note!.records.length, (index) {
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
      ],
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
    final isCollapsed = _collapsedCards.contains(index);
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
          // Header — tappable to collapse/expand
          GestureDetector(
            onTap: () => setState(() {
              if (isCollapsed) {
                _collapsedCards.remove(index);
              } else {
                _collapsedCards.add(index);
              }
            }),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isCollapsed ? const Radius.circular(12) : Radius.zero,
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
                  // Collapse indicator
                  AnimatedRotation(
                    turns: isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fields — hidden when collapsed
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _buildFieldRows(theme, record),
              ),
            ),
            secondChild: const SizedBox.shrink(),
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
      case FieldType.image:
        return Icons.image;
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

      case FieldType.image:
        return _ImageGallery(value: value?.toString() ?? '');

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

class _PasswordField extends ConsumerStatefulWidget {
  const _PasswordField({required this.value});

  final String value;

  @override
  ConsumerState<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends ConsumerState<_PasswordField> {
  bool? _localOverride; // null = follow global setting

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final globalShow = ref.watch(showPasswordsProvider);
    final isVisible = _localOverride ?? globalShow;

    return Row(
      children: [
        Expanded(
          child: Text(
            isVisible ? widget.value : '•' * widget.value.length.clamp(8, 16),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => setState(() => _localOverride = !isVisible),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          tooltip: isVisible ? 'Hide password' : 'Show password',
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

/// Inline image gallery for cards/grid layout.
class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.value});
  final String value;

  List<String> _parse() {
    if (value.isEmpty) return [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [value];
  }

  Widget _buildImage(String ref) {
    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      return Image.network(
        ref,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    final absPath = FileSystemInterop.getAbsolutePath(ref);
    if (absPath != null && !kIsWeb) {
      return Image.file(
        File(absPath),
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        height: 120,
        width: 120,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );

  @override
  Widget build(BuildContext context) {
    final images = _parse();
    if (images.isEmpty) {
      return Text(
        '-',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => _showImageDialog(ctx, jsonEncode(images), startIndex: i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(images[i]),
          ),
        ),
      ),
    );
  }
}

/// Show a fullscreen image viewer dialog.
void _showImageDialog(BuildContext context, String value, {int startIndex = 0}) {
  List<String> images;
  try {
    final decoded = jsonDecode(value);
    images = decoded is List ? decoded.cast<String>() : [value];
  } catch (_) {
    images = [value];
  }
  if (images.isEmpty) return;

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: startIndex),
              itemCount: images.length,
              itemBuilder: (_, i) {
                final ref = images[i];
                Widget img;
                if (ref.startsWith('http://') || ref.startsWith('https://')) {
                  img = Image.network(ref, fit: BoxFit.contain);
                } else {
                  final abs = FileSystemInterop.getAbsolutePath(ref);
                  if (abs != null && !kIsWeb) {
                    img = Image.file(File(abs), fit: BoxFit.contain);
                  } else {
                    img = const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    );
                  }
                }
                return InteractiveViewer(child: Center(child: img));
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${images.length} images — swipe to navigate',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

