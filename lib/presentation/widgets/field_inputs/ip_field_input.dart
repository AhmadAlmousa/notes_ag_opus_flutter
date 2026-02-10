import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/field.dart';

/// IP Address field input with auto-formatting dots after each octet.
class IpFieldInput extends StatefulWidget {
  const IpFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Field field;
  final String value;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  State<IpFieldInput> createState() => _IpFieldInputState();
}

class _IpFieldInputState extends State<IpFieldInput> {
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant IpFieldInput oldWidget) {
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

  void _onChanged(String value) {
    // Format IP address with automatic dots
    final formatted = _formatIpAddress(value);
    
    if (formatted != value) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    widget.onChanged(formatted);
  }

  String _formatIpAddress(String input) {
    // Remove any non-digit characters except dots
    String cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Split by dots and process each octet
    List<String> octets = cleaned.split('.');
    List<String> result = [];
    
    for (int i = 0; i < octets.length && i < 4; i++) {
      String octet = octets[i];
      
      // Limit octet length to 3 digits
      if (octet.length > 3) {
        octet = octet.substring(0, 3);
      }
      
      // Limit octet value to 255
      if (octet.isNotEmpty) {
        int value = int.tryParse(octet) ?? 0;
        if (value > 255) {
          octet = '255';
        }
      }
      
      result.add(octet);
      
      // Auto-add dot after 3 digits or when value > 25 (likely complete)
      if (octet.length == 3 && i < 3 && octets.length == i + 1) {
        // User typed 3 digits, add dot automatically
        result.add('');
      }
    }
    
    return result.join('.');
  }

  bool _isValidIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = widget.value.isEmpty || _isValidIp(widget.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              LengthLimitingTextInputFormatter(15), // xxx.xxx.xxx.xxx = 15 chars
            ],
            decoration: InputDecoration(
              labelText: widget.field.label,
              hintText: '192.168.1.1',
              prefixIcon: const Icon(Icons.dns),
              suffixIcon: widget.value.isNotEmpty
                  ? Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? Colors.green : Colors.orange,
                      size: 20,
                    )
                  : null,
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
          ),
        ),
        if (_hasFocus && widget.value.isNotEmpty && !isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              'Enter a valid IP address (e.g., 192.168.1.1)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
