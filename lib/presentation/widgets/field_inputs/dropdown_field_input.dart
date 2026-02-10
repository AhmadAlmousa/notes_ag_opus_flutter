import 'package:flutter/material.dart';

import '../../../data/models/field.dart';

/// Dropdown field input widget with error state support.
class DropdownFieldInput extends StatelessWidget {
  const DropdownFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Field field;
  final String? value;
  final ValueChanged<dynamic> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final options = field.options?.dropdownOptions ?? [];

    return DropdownButtonFormField<String>(
      value: value?.isNotEmpty == true ? value : null,
      decoration: InputDecoration(
        labelText: field.label,
        labelStyle: hasError 
            ? TextStyle(color: Colors.red.shade700)
            : null,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle),
        errorText: hasError ? 'This field is required' : null,
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              )
            : null,
        focusedBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              )
            : null,
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (v) => onChanged(v),
      hint: Text('Select ${field.label.toLowerCase()}'),
    );
  }
}
