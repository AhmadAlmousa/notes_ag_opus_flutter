import 'package:flutter/material.dart';

import '../../../data/models/field.dart';

/// Password field with visibility toggle and error state support.
class PasswordFieldInput extends StatefulWidget {
  const PasswordFieldInput({
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
  State<PasswordFieldInput> createState() => _PasswordFieldInputState();
}

class _PasswordFieldInputState extends State<PasswordFieldInput> {
  late TextEditingController _controller;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(PasswordFieldInput oldWidget) {
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
      obscureText: !_isVisible,
      decoration: InputDecoration(
        labelText: widget.field.label,
        labelStyle: widget.hasError 
            ? TextStyle(color: Colors.red.shade700)
            : null,
        hintText: 'Enter ${widget.field.label.toLowerCase()}',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_isVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isVisible = !_isVisible),
        ),
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
