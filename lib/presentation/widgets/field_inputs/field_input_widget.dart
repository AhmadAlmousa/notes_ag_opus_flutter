import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/field.dart';
import 'text_field_input.dart';
import 'password_field_input.dart';
import 'date_field_input.dart';
import 'dropdown_field_input.dart';
import 'ip_field_input.dart';
import 'regex_field_input.dart';
import 'custom_label_field_input.dart';

/// Generic field input widget that delegates to specific field types.
class FieldInputWidget extends StatelessWidget {
  const FieldInputWidget({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Field field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.password:
        return PasswordFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          hasError: hasError,
        );

      case FieldType.date:
        return DateFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          hasError: hasError,
        );

      case FieldType.dropdown:
        return DropdownFieldInput(
          field: field,
          value: value?.toString(),
          onChanged: onChanged,
          hasError: hasError,
        );

      case FieldType.boolean:
        return _BooleanFieldInput(
          field: field,
          value: value == true || value == 'true',
          onChanged: onChanged,
          hasError: hasError,
        );

      case FieldType.number:
        return TextFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          hasError: hasError,
        );

      case FieldType.digits:
        return TextFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          maxLength: field.options?.length,
          hasError: hasError,
        );

      case FieldType.url:
        return TextFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          keyboardType: TextInputType.url,
          prefixIcon: Icons.link,
          hasError: hasError,
        );

      case FieldType.ip:
        return IpFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          hasError: hasError,
        );

      case FieldType.text:
        return TextFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          hasError: hasError,
        );

      case FieldType.regex:
        return RegexFieldInput(
          field: field,
          value: value?.toString() ?? '',
          onChanged: onChanged,
          hasError: hasError,
        );

      case FieldType.customLabel:
        // Custom label stores two values: {fieldId}_label and {fieldId}_value
        // The parent passes the whole record map as value for this field type
        final labelVal = (value is Map ? value['label']?.toString() : null) ?? '';
        final textVal = (value is Map ? value['value']?.toString() : null) ?? '';
        return CustomLabelFieldInput(
          field: field,
          labelValue: labelVal,
          textValue: textVal,
          onLabelChanged: (l) => onChanged({'label': l, 'value': (value is Map ? value['value']?.toString() : null) ?? ''}),
          onValueChanged: (v) => onChanged({'label': (value is Map ? value['label']?.toString() : null) ?? '', 'value': v}),
          hasError: hasError,
        );
    }
  }
}

class _BooleanFieldInput extends StatelessWidget {
  const _BooleanFieldInput({
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Field field;
  final bool value;
  final ValueChanged<dynamic> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError 
              ? Colors.red 
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: hasError ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: hasError ? Colors.red.shade700 : null,
                ),
              ),
              if (field.required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Switch(
            value: value,
            onChanged: (v) => onChanged(v),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
