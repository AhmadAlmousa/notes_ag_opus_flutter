import 'package:flutter/material.dart';

import '../../../data/models/field.dart';

/// Text field input widget with real-time validation support.
class TextFieldInput extends StatefulWidget {
  const TextFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.maxLength,
    this.hasError = false,
  });

  final Field field;
  final String value;
  final ValueChanged<dynamic> onChanged;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final int? maxLength;
  final bool hasError;

  @override
  State<TextFieldInput> createState() => _TextFieldInputState();
}

class _TextFieldInputState extends State<TextFieldInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(TextFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final v = value ?? '';
    // Required field check
    if (widget.field.required && v.trim().isEmpty) {
      return '${widget.field.label} is required';
    }
    // Number range validation
    if (widget.keyboardType == TextInputType.number && v.isNotEmpty) {
      final num? parsed = num.tryParse(v);
      if (parsed == null) {
        return 'Enter a valid number';
      }
      if (widget.field.options?.min != null && parsed < widget.field.options!.min!) {
        return 'Minimum value is ${widget.field.options!.min}';
      }
      if (widget.field.options?.max != null && parsed > widget.field.options!.max!) {
        return 'Maximum value is ${widget.field.options!.max}';
      }
    }
    // Digits length validation
    if (widget.maxLength != null && v.isNotEmpty && v.length != widget.maxLength) {
      return 'Must be exactly ${widget.maxLength} digits';
    }
    // URL validation
    if (widget.keyboardType == TextInputType.url && v.isNotEmpty) {
      final uri = Uri.tryParse(v);
      if (uri == null || !uri.hasScheme) {
        return 'Enter a valid URL (e.g. https://...)';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      validator: _validate,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.field.label,
        hintText: 'Enter ${widget.field.label.toLowerCase()}',
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,
        suffixIcon: widget.field.required
            ? Icon(
                Icons.star,
                size: 10,
                color: Colors.red.shade400,
              )
            : null,
        counterText: '',
      ),
    );
  }
}
