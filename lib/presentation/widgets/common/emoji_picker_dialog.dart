import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Emoji picker dialog – shows a curated grid of emojis organized by category.
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
  String _searchQuery = '';
  int _selectedCategory = 0;

  static const _categories = [
    ('All', '🔍'),
    ('Objects', '📦'),
    ('Work', '💼'),
    ('People', '👤'),
    ('Nature', '🌿'),
    ('Food', '🍕'),
    ('Travel', '✈️'),
    ('Activities', '⚽'),
    ('Symbols', '💠'),
  ];

  static const _emojis = <String, List<String>>{
    'Objects': [
      '📝', '📋', '📎', '📌', '📁', '📂', '📄', '📃', '📑', '📊',
      '📈', '📉', '📕', '📗', '📘', '📙', '📔', '📒', '📓', '📖',
      '🔑', '🔒', '🔓', '🔐', '💳', '💰', '💵', '💸', '🏷️', '📦',
      '📫', '📬', '📮', '✉️', '📧', '🗂️', '🗃️', '🗄️', '🗑️', '📆',
      '📅', '🗓️', '⏰', '⏳', '🔔', '🔕', '📱', '💻', '🖥️', '🖨️',
      '⌨️', '🖱️', '🎮', '🕹️', '💡', '🔦', '🔧', '🔨', '🛠️', '⚙️',
    ],
    'Work': [
      '💼', '👔', '🏢', '🏗️', '🏭', '📐', '📏', '✂️', '🖊️', '✏️',
      '🖋️', '📝', '📊', '📋', '📌', '📎', '🗂️', '🗃️', '📁', '📂',
      '💻', '🖥️', '📱', '☎️', '📞', '📟', '📠', '✅', '❌', '⭐',
    ],
    'People': [
      '👤', '👥', '👨', '👩', '👶', '👴', '👵', '🧑', '👨‍💻', '👩‍💻',
      '👨‍🔬', '👩‍🔬', '👨‍🎨', '👩‍🎨', '👨‍⚕️', '👩‍⚕️', '👨‍🏫', '👩‍🏫', '🤝', '👋',
      '✊', '👊', '🤞', '✌️', '🫶', '❤️', '💛', '💚', '💙', '💜',
    ],
    'Nature': [
      '🌿', '🌱', '🌲', '🌳', '🌴', '🌵', '🌻', '🌺', '🌸', '🌷',
      '🍀', '🍁', '🍂', '🍃', '🌾', '🐾', '🐶', '🐱', '🐠', '🦋',
      '🐝', '🐞', '🌍', '🌙', '⭐', '☀️', '🌈', '💧', '🔥', '❄️',
    ],
    'Food': [
      '🍕', '🍔', '🍟', '🌭', '🍿', '🥗', '🥘', '🍝', '🍜', '🍲',
      '🍛', '🥩', '🍗', '🥚', '🧀', '🍞', '🥐', '🥯', '🥖', '🧈',
      '☕', '🍵', '🫖', '🥤', '🧃', '🍺', '🍷', '🥂', '🍽️', '🥄',
    ],
    'Travel': [
      '✈️', '🚗', '🚕', '🚌', '🚎', '🚆', '🚂', '🚢', '⛴️', '🛳️',
      '🚀', '🛸', '🏠', '🏡', '🏢', '🏨', '🏥', '🏫', '🏗️', '⛪',
      '🕌', '🕍', '⛩️', '🗼', '🗽', '🌉', '🏔️', '🗻', '🏖️', '🏝️',
    ],
    'Activities': [
      '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸',
      '🥊', '🎿', '⛷️', '🏂', '🤸', '🧘', '🏋️', '🚴', '🏊', '🤽',
      '🎵', '🎶', '🎸', '🎹', '🎺', '🎷', '🥁', '🎨', '🎭', '🎬',
    ],
    'Symbols': [
      '💠', '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎',
      '💯', '✅', '❌', '⭕', '❗', '❓', '‼️', '⁉️', '♻️', '🔰',
      '⚠️', '🚫', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '⬛', '⬜',
    ],
  };

  List<String> get _filteredEmojis {
    List<String> emojis;
    if (_selectedCategory == 0) {
      // All
      emojis = _emojis.values.expand((list) => list).toSet().toList();
    } else {
      final categoryName = _categories[_selectedCategory].$1;
      emojis = _emojis[categoryName] ?? [];
    }

    if (_searchQuery.isEmpty) return emojis;

    // For emoji search, just return all (search by category name is hard)
    return emojis;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emojis = _filteredEmojis;

    return AlertDialog(
      title: Row(
        children: [
          const Text('Choose Icon'),
          const Spacer(),
          if (widget.currentEmoji != null)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Remove'),
            ),
        ],
      ),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          children: [
            // Search
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search emojis...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Category tabs
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final (name, emoji) = _categories[index];
                  final isSelected = index == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(
                        '$emoji ${index == 0 ? name : ''}',
                        style: TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = index),
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  final isSelected = emoji == widget.currentEmoji;
                  return InkWell(
                    onTap: () => Navigator.pop(context, emoji),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryColor, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
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
      ],
    );
  }
}
