import 'field.dart';

/// Layout types for displaying notes.
enum TemplateLayout {
  cards,
  table,
  list,
  grid,
}

extension TemplateLayoutExtension on TemplateLayout {
  String get displayName {
    switch (this) {
      case TemplateLayout.cards:
        return 'Cards';
      case TemplateLayout.table:
        return 'Table';
      case TemplateLayout.list:
        return 'List';
      case TemplateLayout.grid:
        return 'Grid';
    }
  }

  String get iconName {
    switch (this) {
      case TemplateLayout.cards:
        return 'view_agenda';
      case TemplateLayout.table:
        return 'table_chart';
      case TemplateLayout.list:
        return 'view_list';
      case TemplateLayout.grid:
        return 'grid_view';
    }
  }

  static TemplateLayout fromString(String value) {
    return TemplateLayout.values.firstWhere(
      (layout) => layout.name == value.toLowerCase(),
      orElse: () => TemplateLayout.cards,
    );
  }
}

/// Display settings for a template.
class DisplaySettings {
  const DisplaySettings({
    this.preset,
    this.primaryField,
  });

  /// Display preset (e.g., 'credentials', 'contact').
  final String? preset;

  /// Primary field ID to display in list views.
  final String? primaryField;

  factory DisplaySettings.fromYaml(Map<String, dynamic>? yaml) {
    if (yaml == null) return const DisplaySettings();
    return DisplaySettings(
      preset: yaml['preset'] as String?,
      primaryField: yaml['primary'] as String?,
    );
  }

  Map<String, dynamic> toYaml() {
    final map = <String, dynamic>{};
    if (preset != null) map['preset'] = preset;
    if (primaryField != null) map['primary'] = primaryField;
    return map;
  }
}

/// An action button defined in a template.
class TemplateAction {
  const TemplateAction({
    required this.label,
    required this.field,
    required this.type,
  });

  final String label;
  final String field;
  final String type; // 'copy', 'open', etc.

  factory TemplateAction.fromYaml(Map<String, dynamic> yaml) {
    return TemplateAction(
      label: yaml['label'] as String? ?? '',
      field: yaml['field'] as String? ?? '',
      type: yaml['type'] as String? ?? 'copy',
    );
  }

  Map<String, dynamic> toYaml() {
    return {
      'label': label,
      'field': field,
      'type': type,
    };
  }
}

/// A template that defines the structure for notes.
class Template {
  const Template({
    required this.templateId,
    required this.name,
    this.version = 1,
    this.layout = TemplateLayout.cards,
    this.defaultFolder,
    this.display = const DisplaySettings(),
    this.fields = const [],
    this.actions = const [],
  });

  final String templateId;
  final String name;
  final int version;
  final TemplateLayout layout;
  final String? defaultFolder;
  final DisplaySettings display;
  final List<Field> fields;
  final List<TemplateAction> actions;

  /// Creates a Template from parsed YAML frontmatter and schema.
  factory Template.fromYaml({
    required Map<String, dynamic> frontmatter,
    required Map<String, dynamic> schema,
  }) {
    return Template(
      templateId: frontmatter['template_id'] as String? ?? '',
      name: frontmatter['name'] as String? ?? '',
      version: frontmatter['version'] as int? ?? 1,
      layout: TemplateLayoutExtension.fromString(
        frontmatter['layout'] as String? ?? 'cards',
      ),
      defaultFolder: frontmatter['default_folder'] as String?,
      display: DisplaySettings.fromYaml(
        schema['display'] as Map<String, dynamic>?,
      ),
      fields: (schema['fields'] as List<dynamic>?)
              ?.map((f) => Field.fromYaml(f as Map<String, dynamic>))
              .toList() ??
          [],
      actions: (schema['actions'] as List<dynamic>?)
              ?.map((a) => TemplateAction.fromYaml(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts template to markdown file content.
  String toMarkdown() {
    final buffer = StringBuffer();

    // Frontmatter
    buffer.writeln('---');
    buffer.writeln('template_id: $templateId');
    buffer.writeln('name: $name');
    buffer.writeln('version: $version');
    buffer.writeln('layout: ${layout.name}');
    if (defaultFolder != null) {
      buffer.writeln('default_folder: $defaultFolder');
    }
    buffer.writeln('---');
    buffer.writeln();

    // Schema block
    buffer.writeln('```schema');
    if (display.preset != null || display.primaryField != null) {
      buffer.writeln('display:');
      if (display.preset != null) {
        buffer.writeln('  preset: ${display.preset}');
      }
      if (display.primaryField != null) {
        buffer.writeln('  primary: ${display.primaryField}');
      }
    }

    buffer.writeln('fields:');
    for (final field in fields) {
      buffer.writeln('  - id: ${field.id}');
      buffer.writeln('    type: ${field.type.name}');
      buffer.writeln('    label: ${field.label}');
      if (field.required) {
        buffer.writeln('    required: true');
      }
      if (field.options != null) {
        final opts = field.options!;
        if (opts.min != null) buffer.writeln('    min: ${opts.min}');
        if (opts.max != null) buffer.writeln('    max: ${opts.max}');
        if (opts.length != null) buffer.writeln('    length: ${opts.length}');
        if (opts.calendarMode != null) {
          buffer.writeln('    calendar: ${opts.calendarMode!.name}');
        }
        if (opts.dropdownOptions != null) {
          buffer.writeln('    options:');
          for (final opt in opts.dropdownOptions!) {
            buffer.writeln('      - $opt');
          }
        }
      }
    }

    if (actions.isNotEmpty) {
      buffer.writeln('actions:');
      for (final action in actions) {
        buffer.writeln('  - label: ${action.label}');
        buffer.writeln('    field: ${action.field}');
        buffer.writeln('    type: ${action.type}');
      }
    }

    buffer.writeln('```');

    return buffer.toString();
  }

  Template copyWith({
    String? templateId,
    String? name,
    int? version,
    TemplateLayout? layout,
    String? defaultFolder,
    DisplaySettings? display,
    List<Field>? fields,
    List<TemplateAction>? actions,
  }) {
    return Template(
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      version: version ?? this.version,
      layout: layout ?? this.layout,
      defaultFolder: defaultFolder ?? this.defaultFolder,
      display: display ?? this.display,
      fields: fields ?? this.fields,
      actions: actions ?? this.actions,
    );
  }
}
