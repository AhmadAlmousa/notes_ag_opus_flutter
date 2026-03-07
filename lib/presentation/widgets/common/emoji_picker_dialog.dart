import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple emoji input dialog — lets the user type or paste any emoji.
/// On mobile, hints the OS to open the emoji keyboard.
class EmojiPickerDialog extends StatefulWidget {
  const EmojiPickerDialog({super.key, this.currentEmoji});

  final String? currentEmoji;

  /// Shows the dialog and returns the selected emoji, or null if cancelled.
  static Future<String?> show(BuildContext context, {String? currentEmoji}) {
    return showDialog<String>(
      context: context,
      builder: (_) => EmojiPickerDialog(currentEmoji: currentEmoji),
    );
  }

  @override
  State<EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends State<EmojiPickerDialog> {
  late TextEditingController _controller;
  String? _preview;

  // Quick-access emojis for convenience
  static const _quickEmojis = [
    '📝', '📋', '📁', '📊', '🔑', '💼', '🏠', '⭐', '❤️', '🔥',
    '✅', '❌', '⚙️', '💡', '📱', '💻', '🎯', '🎨', '📌', '🔔',
    '👤', '👥', '📦', '🌍', '☕', '🍕', '🚗', '✈️', '🎵', '📸',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentEmoji ?? '');
    _preview = widget.currentEmoji;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extract the first emoji character (which may be multi-codepoint).
  String? _extractFirstEmoji(String text) {
    if (text.isEmpty) return null;
    final runes = text.runes.toList();
    if (runes.isEmpty) return null;
    // Take first emoji (may be multi-codepoint with ZWJ sequences)
    // Simple approach: take first grapheme cluster
    final chars = text.characters;
    if (chars.isEmpty) return null;
    return chars.first;
  }

  void _onTextChanged(String value) {
    final emoji = _extractFirstEmoji(value);
    setState(() => _preview = emoji);
  }

  void _selectEmoji(String emoji) {
    Navigator.pop(context, emoji);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Text('Choose Emoji'),
          const Spacer(),
          if (widget.currentEmoji != null)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Remove'),
            ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input for typing/pasting emoji
            Row(
              children: [
                // Preview
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _preview ?? '?',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onTextChanged,
                    // Hint the OS to show emoji keyboard on mobile
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      // Allow only emoji characters (no ASCII letters/digits)
                      FilteringTextInputFormatter.deny(
                        RegExp(r'[a-zA-Z0-9\s]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Type or paste emoji',
                      helperText: 'Use your emoji keyboard (😊)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick pick section
            Text(
              'Quick Pick',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: _quickEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _quickEmojis[index];
                  return InkWell(
                    onTap: () => _selectEmoji(emoji),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _preview != null
              ? () => Navigator.pop(context, _preview)
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}
