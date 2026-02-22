/// Field types supported by Organote templates.
enum FieldType {
  text,
  number,
  digits,
  date,
  dropdown,
  boolean,
  url,
  ip,
  password,
  regex,
  customLabel,
}

/// Extension to get field type from string.
extension FieldTypeExtension on FieldType {
  String get displayName {
    switch (this) {
      case FieldType.text:
        return 'Text';
      case FieldType.number:
        return 'Number';
      case FieldType.digits:
        return 'Digits';
      case FieldType.date:
        return 'Date';
      case FieldType.dropdown:
        return 'Dropdown';
      case FieldType.boolean:
        return 'Boolean';
      case FieldType.url:
        return 'URL';
      case FieldType.ip:
        return 'IP Address';
      case FieldType.password:
        return 'Password';
      case FieldType.regex:
        return 'Regex';
      case FieldType.customLabel:
        return 'Custom Label';
    }
  }

  String get iconName {
    switch (this) {
      case FieldType.text:
        return 'title';
      case FieldType.number:
        return 'numbers';
      case FieldType.digits:
        return 'pin';
      case FieldType.date:
        return 'calendar_today';
      case FieldType.dropdown:
        return 'arrow_drop_down_circle';
      case FieldType.boolean:
        return 'toggle_on';
      case FieldType.url:
        return 'link';
      case FieldType.ip:
        return 'dns';
      case FieldType.password:
        return 'lock';
      case FieldType.regex:
        return 'rule';
      case FieldType.customLabel:
        return 'label';
    }
  }

  static FieldType fromString(String value) {
    final lower = value.toLowerCase();
    // Handle camelCase → enum mapping
    if (lower == 'customlabel' || lower == 'custom_label') {
      return FieldType.customLabel;
    }
    return FieldType.values.firstWhere(
      (type) => type.name == lower,
      orElse: () => FieldType.text,
    );
  }
}

/// Calendar modes for date fields.
enum CalendarMode {
  gregorian,
  hijri,
  dual,
}

/// A field definition within a template.
class Field {
  const Field({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.options,
  });

  final String id;
  final FieldType type;
  final String label;
  final bool required;
  final FieldOptions? options;

  /// Creates a Field from a YAML map.
  factory Field.fromYaml(Map<String, dynamic> yaml) {
    return Field(
      id: yaml['id'] as String? ?? '',
      type: FieldTypeExtension.fromString(yaml['type'] as String? ?? 'text'),
      label: yaml['label'] as String? ?? yaml['id'] as String? ?? '',
      required: yaml['required'] as bool? ?? false,
      options: FieldOptions.fromYaml(yaml),
    );
  }

  /// Converts the Field to a YAML-serializable map.
  Map<String, dynamic> toYaml() {
    final map = <String, dynamic>{
      'id': id,
      'type': type == FieldType.customLabel ? 'custom_label' : type.name,
      'label': label,
    };
    if (required) {
      map['required'] = required;
    }
    if (options != null) {
      map.addAll(options!.toYaml());
    }
    return map;
  }

  Field copyWith({
    String? id,
    FieldType? type,
    String? label,
    bool? required,
    FieldOptions? options,
  }) {
    return Field(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      required: required ?? this.required,
      options: options ?? this.options,
    );
  }
}

/// Type-specific options for fields.
class FieldOptions {
  const FieldOptions({
    this.min,
    this.max,
    this.length,
    this.dropdownOptions,
    this.calendarMode,
    this.regexPattern,
    this.regexHint,
  });

  /// Minimum value for number fields.
  final num? min;

  /// Maximum value for number fields.
  final num? max;

  /// Exact length for digits fields.
  final int? length;

  /// Options list for dropdown fields.
  final List<String>? dropdownOptions;

  /// Calendar mode for date fields.
  final CalendarMode? calendarMode;

  /// Regex pattern for regex fields.
  final String? regexPattern;

  /// User-facing description of valid format for regex fields.
  final String? regexHint;

  factory FieldOptions.fromYaml(Map<String, dynamic> yaml) {
    List<String>? dropdownOpts;
    if (yaml['options'] != null) {
      dropdownOpts = (yaml['options'] as List).cast<String>();
    }

    CalendarMode? calMode;
    if (yaml['calendar'] != null) {
      final calStr = yaml['calendar'] as String;
      calMode = CalendarMode.values.firstWhere(
        (m) => m.name == calStr.toLowerCase(),
        orElse: () => CalendarMode.gregorian,
      );
    }

    return FieldOptions(
      min: yaml['min'] as num?,
      max: yaml['max'] as num?,
      length: yaml['length'] as int?,
      dropdownOptions: dropdownOpts,
      calendarMode: calMode,
      regexPattern: yaml['regex_pattern'] as String?,
      regexHint: yaml['regex_hint'] as String?,
    );
  }

  Map<String, dynamic> toYaml() {
    final map = <String, dynamic>{};
    if (min != null) map['min'] = min;
    if (max != null) map['max'] = max;
    if (length != null) map['length'] = length;
    if (dropdownOptions != null) map['options'] = dropdownOptions;
    if (calendarMode != null) map['calendar'] = calendarMode!.name;
    if (regexPattern != null) map['regex_pattern'] = regexPattern;
    if (regexHint != null) map['regex_hint'] = regexHint;
    return map;
  }
}
