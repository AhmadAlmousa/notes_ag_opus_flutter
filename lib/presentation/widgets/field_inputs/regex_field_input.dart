import 'package:flutter/material.dart';

import '../../../data/models/field.dart';

/// A text field input with regex validation.
class RegexFieldInput extends StatefulWidget {
  const RegexFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Field field;
  final String value;
  final ValueChanged<dynamic> onChanged;
  final bool hasError;

  @override
  State<RegexFieldInput> createState() => _RegexFieldInputState();
}

class _RegexFieldInputState extends State<RegexFieldInput> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant RegexFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final pattern = widget.field.options?.regexPattern;
    if (pattern == null || pattern.isEmpty || value.isEmpty) {
      setState(() => _errorText = null);
      widget.onChanged(value);
      return;
    }

    try {
      final regex = RegExp(pattern);
      if (regex.hasMatch(value)) {
        setState(() => _errorText = null);
      } else {
        setState(() {
          _errorText = widget.field.options?.regexHint ?? 'Invalid format';
        });
      }
    } catch (_) {
      setState(() => _errorText = null);
    }
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = widget.field.options?.regexHint;

    return TextField(
      controller: _controller,
      onChanged: _validate,
      decoration: InputDecoration(
        labelText: widget.field.label,
        hintText: hint ?? 'Enter value',
        helperText: hint,
        helperMaxLines: 2,
        errorText: _errorText,
        errorMaxLines: 2,
        prefixIcon: const Icon(Icons.rule, size: 20),
        suffixIcon: widget.field.required
            ? Text(
                ' *',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError || _errorText != null
                ? Colors.red
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
