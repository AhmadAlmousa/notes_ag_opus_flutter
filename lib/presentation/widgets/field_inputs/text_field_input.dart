import 'package:flutter/material.dart';

import '../../../data/models/field.dart';

/// Text field input widget with error state support.
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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.field.label,
        labelStyle: widget.hasError 
            ? TextStyle(color: Colors.red.shade700)
            : null,
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
        errorText: widget.hasError ? 'This field is required' : null,
        enabledBorder: widget.hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              )
            : null,
        focusedBorder: widget.hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              )
            : null,
      ),
    );
  }
}
