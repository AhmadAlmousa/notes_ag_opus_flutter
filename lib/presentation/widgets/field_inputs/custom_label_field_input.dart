import 'package:flutter/material.dart';

import '../../../data/models/field.dart';

/// A field where the user provides both a custom label and a value.
/// Stores as `{fieldId}_label` and `{fieldId}_value` in the record.
class CustomLabelFieldInput extends StatefulWidget {
  const CustomLabelFieldInput({
    super.key,
    required this.field,
    required this.labelValue,
    required this.textValue,
    required this.onLabelChanged,
    required this.onValueChanged,
    this.hasError = false,
  });

  final Field field;
  final String labelValue;
  final String textValue;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onValueChanged;
  final bool hasError;

  @override
  State<CustomLabelFieldInput> createState() => _CustomLabelFieldInputState();
}

class _CustomLabelFieldInputState extends State<CustomLabelFieldInput> {
  late TextEditingController _labelController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.labelValue);
    _valueController = TextEditingController(text: widget.textValue);
  }

  @override
  void didUpdateWidget(covariant CustomLabelFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labelValue != widget.labelValue &&
        widget.labelValue != _labelController.text) {
      _labelController.text = widget.labelValue;
    }
    if (oldWidget.textValue != widget.textValue &&
        widget.textValue != _valueController.text) {
      _valueController.text = widget.textValue;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.hasError
              ? Colors.red
              : theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label_outline, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.field.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.field.required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Label input
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _labelController,
                  onChanged: widget.onLabelChanged,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    hintText: 'Enter label name',
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 10),
              // Value input
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _valueController,
                  onChanged: widget.onValueChanged,
                  decoration: InputDecoration(
                    labelText: 'Value',
                    hintText: 'Enter value',
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
