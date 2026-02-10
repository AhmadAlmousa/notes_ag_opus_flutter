import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sanitizers.dart';
import '../../../data/models/field.dart';
import '../../../data/models/template.dart';

/// Template builder/editor screen.
class TemplateBuilderScreen extends StatefulWidget {
  const TemplateBuilderScreen({super.key, this.templateId});

  final String? templateId;

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  late Template _template;
  late TextEditingController _nameController;
  late TextEditingController _idController;
  bool _isNew = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  void _loadTemplate() {
    if (widget.templateId != null) {
      final existing =
          AppState.instance.templateRepository.getById(widget.templateId!);
      if (existing != null) {
        _template = existing;
        _isNew = false;
      } else {
        _template = AppState.instance.templateRepository.createNew();
      }
    } else {
      _template = AppState.instance.templateRepository.createNew();
    }

    _nameController = TextEditingController(text: _template.name);
    _idController = TextEditingController(text: _template.templateId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _updateName(String value) {
    _markChanged();
    // Auto-generate ID from name if new template
    if (_isNew) {
      _idController.text = Sanitizers.labelToId(value);
    }
  }

  void _addField() {
    setState(() {
      _template = _template.copyWith(
        fields: [
          ..._template.fields,
          Field(
            id: 'field_${_template.fields.length + 1}',
            type: FieldType.text,
            label: 'New Field',
          ),
        ],
      );
      _hasChanges = true;
    });
  }

  void _updateField(int index, Field field) {
    final fields = List<Field>.from(_template.fields);
    fields[index] = field;
    setState(() {
      _template = _template.copyWith(fields: fields);
      _hasChanges = true;
    });
  }

  void _removeField(int index) {
    final fields = List<Field>.from(_template.fields);
    fields.removeAt(index);
    setState(() {
      _template = _template.copyWith(fields: fields);
      _hasChanges = true;
    });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final fields = List<Field>.from(_template.fields);
    final field = fields.removeAt(oldIndex);
    fields.insert(newIndex, field);
    setState(() {
      _template = _template.copyWith(fields: fields);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name is required')),
      );
      return;
    }

    if (!Sanitizers.isValidTemplateId(_idController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template ID must be lowercase with underscores only'),
        ),
      );
      return;
    }

    final updatedTemplate = _template.copyWith(
      templateId: _idController.text,
      name: _nameController.text,
      version: _isNew ? 1 : _template.version + 1,
    );

    await AppState.instance.templateRepository.save(updatedTemplate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNew ? 'Template created!' : 'Template updated!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
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
          title: Text(_isNew ? 'New Template' : 'Edit Template'),
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
              _buildSection(
                context,
                'Template Info',
                Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      onChanged: _updateName,
                      decoration: const InputDecoration(
                        labelText: 'Template Name',
                        hintText: 'e.g., Family Login',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idController,
                      onChanged: (_) => _markChanged(),
                      enabled: _isNew,
                      decoration: InputDecoration(
                        labelText: 'Template ID',
                        hintText: 'e.g., family_login',
                        helperText: _isNew
                            ? 'Auto-generated from name'
                            : 'Cannot be changed after creation',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Layout selector
                    DropdownButtonFormField<TemplateLayout>(
                      value: _template.layout,
                      decoration: const InputDecoration(
                        labelText: 'Layout',
                      ),
                      items: TemplateLayout.values.map((layout) {
                        return DropdownMenuItem(
                          value: layout,
                          child: Row(
                            children: [
                              Icon(
                                _getLayoutIcon(layout),
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(layout.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _template = _template.copyWith(layout: value);
                            _hasChanges = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Fields
              _buildSection(
                context,
                'Fields',
                Column(
                  children: [
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _template.fields.length,
                      onReorder: _reorderFields,
                      itemBuilder: (context, index) {
                        return _FieldCard(
                          key: ValueKey('field_$index'),
                          field: _template.fields[index],
                          index: index,
                          onUpdate: (field) => _updateField(index, field),
                          onDelete: () => _removeField(index),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addField,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Field'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget child) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  IconData _getLayoutIcon(TemplateLayout layout) {
    switch (layout) {
      case TemplateLayout.cards:
        return Icons.view_agenda_rounded;
      case TemplateLayout.table:
        return Icons.table_chart_rounded;
      case TemplateLayout.list:
        return Icons.format_list_bulleted_rounded;
      case TemplateLayout.grid:
        return Icons.grid_view_rounded;
    }
  }
}

class _FieldCard extends StatefulWidget {
  const _FieldCard({
    super.key,
    required this.field,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  final Field field;
  final int index;
  final ValueChanged<Field> onUpdate;
  final VoidCallback onDelete;

  @override
  State<_FieldCard> createState() => _FieldCardState();
}

class _FieldCardState extends State<_FieldCard> {
  late TextEditingController _labelController;
  late TextEditingController _idController;
  late TextEditingController _dropdownOptionsController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _labelController = TextEditingController(text: widget.field.label);
    _idController = TextEditingController(text: widget.field.id);
    _dropdownOptionsController = TextEditingController(
      text: widget.field.options?.dropdownOptions?.join(', ') ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _FieldCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers if the field id changed (different field)
    if (oldWidget.field.id != widget.field.id) {
      _labelController.text = widget.field.label;
      _idController.text = widget.field.id;
      _dropdownOptionsController.text =
          widget.field.options?.dropdownOptions?.join(', ') ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _idController.dispose();
    _dropdownOptionsController.dispose();
    super.dispose();
  }

  void _updateField(Field updated) {
    widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.drag_indicator,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _getFieldIcon(widget.field.type),
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.field.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.field.type.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.field.required)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Required',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) _buildExpandedContent(context),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          TextField(
            controller: _labelController,
            onEditingComplete: () {
              // Only update parent when done editing to avoid text selection issues
              final value = _labelController.text;
              final newId = Sanitizers.labelToId(value);
              _idController.text = newId;
              _updateField(widget.field.copyWith(
                label: value,
                id: newId,
              ));
            },
            onSubmitted: (value) {
              final newId = Sanitizers.labelToId(value);
              _idController.text = newId;
              _updateField(widget.field.copyWith(
                label: value,
                id: newId,
              ));
            },
            decoration: const InputDecoration(
              labelText: 'Label',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _idController,
            onChanged: (value) {
              _updateField(widget.field.copyWith(id: value));
            },
            decoration: const InputDecoration(
              labelText: 'Field ID',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FieldType>(
            value: widget.field.type,
            decoration: const InputDecoration(
              labelText: 'Field Type',
              isDense: true,
            ),
            items: FieldType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _getFieldIcon(type),
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(type.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                // Clear options when type changes
                _updateField(widget.field.copyWith(
                  type: value,
                  options: null,
                ));
              }
            },
          ),

          // Type-specific options
          ..._buildTypeSpecificOptions(context),

          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Required'),
            value: widget.field.required,
            onChanged: (value) {
              _updateField(widget.field.copyWith(required: value));
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build type-specific options based on field type
  List<Widget> _buildTypeSpecificOptions(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.field.type) {
      case FieldType.date:
        // Calendar mode selector
        return [
          const SizedBox(height: 12),
          Text(
            'Calendar Type',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<CalendarMode>(
            segments: const [
              ButtonSegment(
                value: CalendarMode.gregorian,
                label: Text('Gregorian'),
                icon: Icon(Icons.calendar_today, size: 16),
              ),
              ButtonSegment(
                value: CalendarMode.hijri,
                label: Text('Hijri'),
                icon: Icon(Icons.calendar_month, size: 16),
              ),
              ButtonSegment(
                value: CalendarMode.dual,
                label: Text('Dual'),
                icon: Icon(Icons.compare_arrows, size: 16),
              ),
            ],
            selected: {widget.field.options?.calendarMode ?? CalendarMode.gregorian},
            onSelectionChanged: (selected) {
              _updateField(widget.field.copyWith(
                options: FieldOptions(
                  calendarMode: selected.first,
                ),
              ));
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ];

      case FieldType.dropdown:
        // Dropdown options editor
        return [
          const SizedBox(height: 12),
          TextField(
            controller: _dropdownOptionsController,
            onChanged: (value) {
              final options = value
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              _updateField(widget.field.copyWith(
                options: FieldOptions(dropdownOptions: options),
              ));
            },
            decoration: const InputDecoration(
              labelText: 'Dropdown Options',
              hintText: 'Option 1, Option 2, Option 3',
              helperText: 'Separate options with commas',
              isDense: true,
            ),
            maxLines: 2,
          ),
          if (widget.field.options?.dropdownOptions?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.field.options!.dropdownOptions!.map((opt) {
                  return Chip(
                    label: Text(opt, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      final options = List<String>.from(
                        widget.field.options!.dropdownOptions!,
                      )..remove(opt);
                      _dropdownOptionsController.text = options.join(', ');
                      _updateField(widget.field.copyWith(
                        options: FieldOptions(dropdownOptions: options),
                      ));
                    },
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
        ];

      case FieldType.number:
        // Min/max validators
        return [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: widget.field.options?.min?.toString(),
                  onChanged: (value) {
                    final min = num.tryParse(value);
                    _updateField(widget.field.copyWith(
                      options: FieldOptions(
                        min: min,
                        max: widget.field.options?.max,
                      ),
                    ));
                  },
                  decoration: const InputDecoration(
                    labelText: 'Min Value',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: widget.field.options?.max?.toString(),
                  onChanged: (value) {
                    final max = num.tryParse(value);
                    _updateField(widget.field.copyWith(
                      options: FieldOptions(
                        min: widget.field.options?.min,
                        max: max,
                      ),
                    ));
                  },
                  decoration: const InputDecoration(
                    labelText: 'Max Value',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ];

      case FieldType.digits:
        // Length validator
        return [
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.field.options?.length?.toString(),
            onChanged: (value) {
              final length = int.tryParse(value);
              _updateField(widget.field.copyWith(
                options: FieldOptions(length: length),
              ));
            },
            decoration: const InputDecoration(
              labelText: 'Exact Length',
              hintText: 'e.g., 6 for PIN codes',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
          ),
        ];

      default:
        return [];
    }
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
    }
  }
}
