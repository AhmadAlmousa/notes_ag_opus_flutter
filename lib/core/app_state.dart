import 'package:flutter/material.dart';

import '../data/repositories/note_repository.dart';
import '../data/repositories/template_repository.dart';
import '../data/services/storage_service.dart';

/// Global app state and dependency container.
class AppState extends ChangeNotifier {
  AppState._();

  static AppState? _instance;

  /// Gets the singleton instance.
  static AppState get instance {
    _instance ??= AppState._();
    return _instance!;
  }

  bool _initialized = false;
  bool get initialized => _initialized;

  late StorageService _storage;
  late TemplateRepository _templateRepository;
  late NoteRepository _noteRepository;

  StorageService get storage => _storage;
  TemplateRepository get templateRepository => _templateRepository;
  NoteRepository get noteRepository => _noteRepository;

  // Theme
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Initializes the app state.
  Future<void> initialize() async {
    if (_initialized) return;

    _storage = await StorageService.getInstance();
    _templateRepository = TemplateRepository(_storage);
    _noteRepository = NoteRepository(_storage);

    // Load theme preference
    final themePref = _storage.getSetting<String>('themeMode');
    if (themePref != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themePref,
        orElse: () => ThemeMode.system,
      );
    }

    // Seed with sample data if empty
    await _seedSampleData();

    _initialized = true;
    notifyListeners();
  }

  /// Sets the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.setSetting('themeMode', mode.name);
    notifyListeners();
  }

  /// Toggles between light and dark theme.
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Seeds sample data for demonstration.
  Future<void> _seedSampleData() async {
    // Only seed if no templates exist
    if (_templateRepository.getAll().isNotEmpty) return;

    // Create sample template
    const sampleTemplateContent = '''---
template_id: family_login
name: Family Login
version: 1
layout: cards
default_folder: personal
---

\`\`\`schema
display:
  preset: credentials
  primary: service
fields:
  - id: owner
    type: dropdown
    label: Owner
    required: true
    options:
      - Dad
      - Mom
      - Kids
  - id: service
    type: text
    label: Service
    required: true
  - id: username
    type: text
    label: Username
    required: true
  - id: password
    type: password
    label: Password
    required: true
  - id: created_on
    type: date
    label: Created On
    calendar: dual
actions:
  - label: Copy Password
    field: password
    type: copy
\`\`\`
''';

    await _storage.saveTemplate('family_login', sampleTemplateContent);

    // Create sample note
    const sampleNoteContent = '''---
template_id: family_login
template_version: 1
id: gmail_accounts
tags:
  - email
  - google
---

\`\`\`data
- owner: Dad
  service: Gmail
  username: dad@gmail.com
  password: MySecurePass123
  created_on: 2024-01-15|gregorian
- owner: Mom
  service: Gmail
  username: mom@gmail.com
  password: AnotherPass456
  created_on: 1445-06-21|hijri
\`\`\`
''';

    await _storage.saveNote('personal', 'gmail_accounts.md', sampleNoteContent);

    // Clear cache to pick up new data
    _templateRepository.clearCache();
    _noteRepository.clearCache();
  }
}
