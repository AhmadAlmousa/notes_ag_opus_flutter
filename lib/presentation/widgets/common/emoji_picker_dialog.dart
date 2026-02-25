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

  /// Keyword map: emoji → list of searchable keywords
  static const _emojiKeywords = <String, List<String>>{
    // Objects
    '📝': ['note', 'memo', 'write', 'pencil', 'edit'],
    '📋': ['clipboard', 'list', 'paste', 'tasks'],
    '📎': ['paperclip', 'clip', 'attach'],
    '📌': ['pin', 'push', 'location', 'mark'],
    '📁': ['folder', 'directory', 'file'],
    '📂': ['folder', 'open', 'directory'],
    '📄': ['document', 'page', 'file', 'paper'],
    '📃': ['document', 'page', 'curl'],
    '📑': ['tabs', 'bookmark'],
    '📊': ['chart', 'bar', 'graph', 'analytics', 'stats'],
    '📈': ['chart', 'increase', 'growth', 'up', 'trending'],
    '📉': ['chart', 'decrease', 'down', 'loss'],
    '📕': ['book', 'red', 'closed', 'read'],
    '📗': ['book', 'green', 'read'],
    '📘': ['book', 'blue', 'read'],
    '📙': ['book', 'orange', 'read'],
    '📔': ['notebook', 'journal', 'diary'],
    '📒': ['ledger', 'notebook', 'yellow'],
    '📓': ['notebook', 'journal'],
    '📖': ['book', 'open', 'read'],
    '🔑': ['key', 'password', 'access', 'login', 'unlock'],
    '🔒': ['lock', 'locked', 'secure', 'password', 'private'],
    '🔓': ['unlock', 'unlocked', 'open'],
    '🔐': ['lock', 'key', 'secure', 'closed'],
    '💳': ['card', 'credit', 'payment', 'bank', 'money'],
    '💰': ['money', 'bag', 'dollar', 'rich', 'finance'],
    '💵': ['money', 'dollar', 'bill', 'cash'],
    '💸': ['money', 'wings', 'spend', 'fly'],
    '🏷️': ['tag', 'label', 'price', 'sale'],
    '📦': ['package', 'box', 'delivery', 'ship'],
    '📫': ['mailbox', 'mail', 'post', 'letter'],
    '📬': ['mailbox', 'mail', 'open'],
    '📮': ['postbox', 'mail', 'post'],
    '✉️': ['email', 'mail', 'letter', 'envelope'],
    '📧': ['email', 'mail', 'electronic'],
    '🗂️': ['dividers', 'index', 'organize', 'tabs'],
    '🗃️': ['card box', 'file', 'cabinet', 'archive'],
    '🗄️': ['cabinet', 'file', 'storage', 'archive'],
    '🗑️': ['trash', 'delete', 'bin', 'waste'],
    '📆': ['calendar', 'date', 'schedule', 'event'],
    '📅': ['calendar', 'date', 'schedule'],
    '🗓️': ['calendar', 'spiral', 'date'],
    '⏰': ['alarm', 'clock', 'time', 'wake'],
    '⏳': ['hourglass', 'time', 'wait', 'timer'],
    '🔔': ['bell', 'notification', 'alert', 'ring'],
    '🔕': ['bell', 'mute', 'silent', 'quiet'],
    '📱': ['phone', 'mobile', 'cell', 'smartphone'],
    '💻': ['laptop', 'computer', 'pc', 'work'],
    '🖥️': ['desktop', 'computer', 'monitor', 'screen'],
    '🖨️': ['printer', 'print', 'paper'],
    '⌨️': ['keyboard', 'type', 'input'],
    '🖱️': ['mouse', 'click', 'computer'],
    '🎮': ['game', 'controller', 'play', 'gaming'],
    '🕹️': ['joystick', 'game', 'arcade'],
    '💡': ['idea', 'light', 'bulb', 'bright'],
    '🔦': ['flashlight', 'torch', 'light'],
    '🔧': ['wrench', 'tool', 'fix', 'repair', 'settings'],
    '🔨': ['hammer', 'tool', 'build', 'construct'],
    '🛠️': ['tools', 'hammer', 'wrench', 'repair', 'settings'],
    '⚙️': ['gear', 'settings', 'config', 'cog'],
    // Work
    '💼': ['briefcase', 'work', 'business', 'office', 'job'],
    '👔': ['tie', 'business', 'formal', 'work'],
    '🏢': ['building', 'office', 'work', 'company'],
    '🏗️': ['construction', 'build', 'crane'],
    '🏭': ['factory', 'industry', 'manufacture'],
    '📐': ['ruler', 'triangle', 'measure', 'math'],
    '📏': ['ruler', 'straight', 'measure'],
    '✂️': ['scissors', 'cut', 'trim'],
    '🖊️': ['pen', 'write', 'ink'],
    '✏️': ['pencil', 'write', 'edit', 'draw'],
    '🖋️': ['pen', 'fountain', 'write'],
    '☎️': ['phone', 'telephone', 'call'],
    '📞': ['phone', 'receiver', 'call'],
    '📟': ['pager', 'beep'],
    '📠': ['fax', 'machine'],
    '✅': ['check', 'done', 'complete', 'yes', 'correct'],
    '❌': ['cross', 'wrong', 'no', 'error', 'delete'],
    '⭐': ['star', 'favorite', 'bookmark', 'rating'],
    // People
    '👤': ['person', 'user', 'profile', 'account', 'avatar'],
    '👥': ['people', 'group', 'team', 'users'],
    '👨': ['man', 'male', 'person'],
    '👩': ['woman', 'female', 'person'],
    '👶': ['baby', 'child', 'kid', 'infant'],
    '👴': ['old', 'man', 'elder', 'grandpa'],
    '👵': ['old', 'woman', 'elder', 'grandma'],
    '🧑': ['person', 'adult', 'human'],
    '👨‍💻': ['developer', 'programmer', 'coder', 'tech'],
    '👩‍💻': ['developer', 'programmer', 'coder', 'tech'],
    '👨‍🔬': ['scientist', 'research', 'lab'],
    '👩‍🔬': ['scientist', 'research', 'lab'],
    '👨‍🎨': ['artist', 'paint', 'create'],
    '👩‍🎨': ['artist', 'paint', 'create'],
    '👨‍⚕️': ['doctor', 'health', 'medical'],
    '👩‍⚕️': ['doctor', 'health', 'medical'],
    '👨‍🏫': ['teacher', 'professor', 'school'],
    '👩‍🏫': ['teacher', 'professor', 'school'],
    '🤝': ['handshake', 'deal', 'agree', 'meeting'],
    '👋': ['wave', 'hello', 'hi', 'bye', 'greeting'],
    '🫶': ['heart', 'hands', 'love', 'care'],
    '❤️': ['heart', 'love', 'red', 'favorite'],
    '💛': ['heart', 'yellow', 'love'],
    '💚': ['heart', 'green', 'love'],
    '💙': ['heart', 'blue', 'love'],
    '💜': ['heart', 'purple', 'love'],
    // Nature
    '🌿': ['herb', 'plant', 'nature', 'green', 'leaf'],
    '🌱': ['seedling', 'plant', 'grow', 'sprout'],
    '🌲': ['tree', 'evergreen', 'pine', 'forest'],
    '🌳': ['tree', 'deciduous', 'nature'],
    '🌴': ['palm', 'tree', 'tropical', 'beach'],
    '🌵': ['cactus', 'desert', 'plant'],
    '🌻': ['sunflower', 'flower', 'yellow'],
    '🌺': ['hibiscus', 'flower', 'tropical'],
    '🌸': ['cherry', 'blossom', 'flower', 'spring'],
    '🌷': ['tulip', 'flower', 'spring'],
    '🍀': ['clover', 'luck', 'four', 'leaf'],
    '🍁': ['maple', 'leaf', 'autumn', 'fall'],
    '🍂': ['leaves', 'fallen', 'autumn'],
    '🍃': ['leaf', 'wind', 'blow'],
    '🌾': ['rice', 'plant', 'grain', 'harvest'],
    '🐾': ['paw', 'pet', 'animal', 'print'],
    '🐶': ['dog', 'puppy', 'pet', 'animal'],
    '🐱': ['cat', 'kitten', 'pet', 'animal'],
    '🐠': ['fish', 'tropical', 'aquarium'],
    '🦋': ['butterfly', 'insect', 'nature'],
    '🐝': ['bee', 'honey', 'insect', 'buzz'],
    '🐞': ['ladybug', 'bug', 'insect'],
    '🌍': ['earth', 'globe', 'world', 'planet'],
    '🌙': ['moon', 'night', 'crescent', 'sleep'],
    '☀️': ['sun', 'sunny', 'weather', 'bright'],
    '🌈': ['rainbow', 'colors', 'weather'],
    '💧': ['water', 'drop', 'rain'],
    '🔥': ['fire', 'hot', 'flame', 'lit'],
    '❄️': ['snow', 'cold', 'ice', 'winter'],
    // Food
    '🍕': ['pizza', 'food', 'slice', 'italian'],
    '🍔': ['burger', 'hamburger', 'food', 'fast'],
    '🍟': ['fries', 'french', 'food', 'potato'],
    '🌭': ['hotdog', 'sausage', 'food'],
    '🍿': ['popcorn', 'movie', 'snack'],
    '🥗': ['salad', 'green', 'healthy', 'food'],
    '🥘': ['pan', 'food', 'cooking'],
    '🍝': ['pasta', 'spaghetti', 'noodle', 'italian'],
    '🍜': ['noodles', 'ramen', 'soup', 'asian'],
    '🍲': ['stew', 'pot', 'food', 'soup'],
    '🍛': ['curry', 'rice', 'food', 'indian'],
    '🥩': ['meat', 'steak', 'beef'],
    '🍗': ['chicken', 'leg', 'poultry'],
    '🥚': ['egg', 'breakfast', 'food'],
    '🧀': ['cheese', 'food', 'dairy'],
    '🍞': ['bread', 'toast', 'loaf', 'bakery'],
    '🥐': ['croissant', 'bread', 'french', 'pastry'],
    '🥯': ['bagel', 'bread', 'breakfast'],
    '🥖': ['baguette', 'bread', 'french'],
    '🧈': ['butter', 'dairy', 'spread'],
    '☕': ['coffee', 'hot', 'drink', 'cafe', 'morning'],
    '🍵': ['tea', 'hot', 'drink', 'cup'],
    '🫖': ['teapot', 'tea', 'drink'],
    '🥤': ['cup', 'straw', 'soda', 'drink'],
    '🧃': ['juice', 'box', 'drink'],
    '🍺': ['beer', 'drink', 'alcohol', 'pub'],
    '🍷': ['wine', 'drink', 'glass', 'red'],
    '🥂': ['champagne', 'toast', 'celebrate', 'cheers'],
    '🍽️': ['plate', 'cutlery', 'dining', 'restaurant'],
    '🥄': ['spoon', 'utensil', 'eat'],
    // Travel
    '✈️': ['airplane', 'plane', 'travel', 'flight', 'fly'],
    '🚗': ['car', 'vehicle', 'drive', 'auto'],
    '🚕': ['taxi', 'cab', 'ride'],
    '🚌': ['bus', 'transit', 'public', 'transport'],
    '🚎': ['trolleybus', 'bus', 'transit'],
    '🚆': ['train', 'rail', 'transit', 'railway'],
    '🚂': ['locomotive', 'train', 'steam'],
    '🚢': ['ship', 'cruise', 'boat', 'ocean'],
    '⛴️': ['ferry', 'boat', 'ship'],
    '🛳️': ['cruise', 'ship', 'boat', 'liner'],
    '🚀': ['rocket', 'space', 'launch', 'fast'],
    '🛸': ['ufo', 'alien', 'space', 'flying'],
    '🏠': ['house', 'home', 'building', 'residence'],
    '🏡': ['house', 'garden', 'home'],
    '🏨': ['hotel', 'building', 'stay', 'travel'],
    '🏥': ['hospital', 'medical', 'health', 'doctor'],
    '🏫': ['school', 'education', 'building'],
    '⛪': ['church', 'religion', 'christian'],
    '🕌': ['mosque', 'islam', 'religion', 'prayer', 'masjid'],
    '🕍': ['synagogue', 'religion', 'jewish'],
    '⛩️': ['shrine', 'japanese', 'shinto'],
    '🗼': ['tower', 'tokyo', 'landmark'],
    '🗽': ['statue', 'liberty', 'new york', 'america'],
    '🌉': ['bridge', 'night', 'city'],
    '🏔️': ['mountain', 'snow', 'peak'],
    '🗻': ['mount fuji', 'mountain', 'japan'],
    '🏖️': ['beach', 'umbrella', 'vacation', 'sand'],
    '🏝️': ['island', 'tropical', 'desert'],
    // Activities
    '⚽': ['soccer', 'football', 'sport', 'ball'],
    '🏀': ['basketball', 'sport', 'ball', 'hoop'],
    '🏈': ['football', 'american', 'sport'],
    '⚾': ['baseball', 'sport', 'ball'],
    '🎾': ['tennis', 'sport', 'ball', 'racket'],
    '🏐': ['volleyball', 'sport', 'ball'],
    '🏉': ['rugby', 'sport', 'ball'],
    '🎱': ['pool', 'billiard', 'eight'],
    '🏓': ['ping pong', 'table tennis', 'sport'],
    '🏸': ['badminton', 'sport', 'shuttle'],
    '🥊': ['boxing', 'sport', 'fight', 'glove'],
    '🎿': ['ski', 'winter', 'snow', 'sport'],
    '⛷️': ['skier', 'ski', 'winter', 'snow'],
    '🏂': ['snowboard', 'winter', 'snow'],
    '🤸': ['cartwheel', 'gymnastics', 'sport'],
    '🧘': ['yoga', 'meditation', 'zen', 'calm'],
    '🏋️': ['weight', 'gym', 'lift', 'exercise'],
    '🚴': ['bike', 'bicycle', 'cycling', 'ride'],
    '🏊': ['swim', 'pool', 'water'],
    '🤽': ['water polo', 'swim', 'sport'],
    '🎵': ['music', 'note', 'musical', 'song'],
    '🎶': ['music', 'notes', 'song', 'melody'],
    '🎸': ['guitar', 'music', 'rock', 'instrument'],
    '🎹': ['piano', 'music', 'keys', 'instrument'],
    '🎺': ['trumpet', 'music', 'brass', 'instrument'],
    '🎷': ['saxophone', 'music', 'jazz', 'instrument'],
    '🥁': ['drum', 'music', 'beat', 'instrument'],
    '🎨': ['art', 'paint', 'palette', 'create', 'design'],
    '🎭': ['theater', 'drama', 'masks', 'performing'],
    '🎬': ['movie', 'film', 'camera', 'action'],
    // Symbols
    '💠': ['diamond', 'shape', 'blue'],
    '🧡': ['heart', 'orange', 'love'],
    '🖤': ['heart', 'black', 'love'],
    '🤍': ['heart', 'white', 'love'],
    '🤎': ['heart', 'brown', 'love'],
    '💯': ['hundred', 'perfect', 'score', '100'],
    '⭕': ['circle', 'red', 'ring', 'zero'],
    '❗': ['exclamation', 'important', 'alert', 'warning'],
    '❓': ['question', 'help', 'what', 'ask'],
    '‼️': ['exclamation', 'double', 'important'],
    '⁉️': ['exclamation', 'question', 'interrobang'],
    '♻️': ['recycle', 'green', 'environment'],
    '🔰': ['beginner', 'symbol', 'japanese'],
    '⚠️': ['warning', 'caution', 'alert', 'danger'],
    '🚫': ['prohibited', 'no', 'forbidden', 'stop'],
    '🔴': ['red', 'circle', 'dot', 'stop'],
    '🟠': ['orange', 'circle', 'dot'],
    '🟡': ['yellow', 'circle', 'dot'],
    '🟢': ['green', 'circle', 'dot', 'go'],
    '🔵': ['blue', 'circle', 'dot'],
    '🟣': ['purple', 'circle', 'dot'],
    '⬛': ['black', 'square'],
    '⬜': ['white', 'square'],
    '✊': ['fist', 'raised', 'power', 'solidarity'],
    '👊': ['fist', 'punch', 'bump'],
    '🤞': ['crossed', 'fingers', 'luck', 'hope'],
    '✌️': ['peace', 'victory', 'two'],
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

    final query = _searchQuery.toLowerCase();

    // Filter by keyword matching and category name matching
    return emojis.where((emoji) {
      // Check keyword map
      final keywords = _emojiKeywords[emoji];
      if (keywords != null) {
        if (keywords.any((kw) => kw.contains(query))) return true;
      }
      // Check category names that contain this emoji
      for (final entry in _emojis.entries) {
        if (entry.value.contains(emoji)) {
          if (entry.key.toLowerCase().contains(query)) return true;
        }
      }
      return false;
    }).toList();
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
            // Results info
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${emojis.length} results for "$_searchQuery"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            // Grid
            Expanded(
              child: emojis.isEmpty
                  ? Center(
                      child: Text(
                        'No emojis found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : GridView.builder(
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
