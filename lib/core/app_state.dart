import 'package:flutter/material.dart';

import '../data/repositories/note_repository.dart';
import '../data/repositories/template_repository.dart';
import '../data/services/storage_service.dart';
import '../data/services/file_system_storage_service.dart';
import '../data/services/fs_interop.dart';

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

  /// Whether storage has been configured (first-run completed).
  bool _storageConfigured = false;
  bool get storageConfigured => _storageConfigured;

  late StorageService _storage;
  late TemplateRepository _templateRepository;
  late NoteRepository _noteRepository;

  StorageService get storage => _storage;
  TemplateRepository get templateRepository => _templateRepository;
  NoteRepository get noteRepository => _noteRepository;

  // Theme
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Storage info
  String get storageType => FileSystemInterop.currentStorageType;
  String? get storageDirectoryName => FileSystemInterop.directoryName;

  /// Initializes the app state.
  Future<void> initialize() async {
    if (_initialized) return;

    // Try to reconnect to a previously configured file system storage
    final reconnected = await FileSystemStorageService.tryReconnect();

    if (reconnected) {
      // Use file system storage
      final fsStorage = await FileSystemStorageService.getInstance();
      await fsStorage.refreshCaches();
      _storage = fsStorage;
      _storageConfigured = true;
    } else {
      // Check if we had a configured storage type
      final configType = FileSystemStorageService.configuredStorageType;
      if (configType == 'local') {
        // Using localStorage fallback
        _storage = await StorageService.getInstance();
        _storageConfigured = true;
      } else if (configType != 'none') {
        // Had FSA/OPFS but couldn't reconnect - fall back to localStorage
        _storage = await StorageService.getInstance();
        _storageConfigured = true;
      } else {
        // First run - no storage configured yet
        _storage = await StorageService.getInstance();
        _storageConfigured = false;
      }
    }

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

  /// Complete storage setup with the chosen type.
  Future<void> completeStorageSetup(String storageType) async {
    await FileSystemStorageService.setConfigured(storageType);
    _storageConfigured = true;

    if (storageType == 'fsa' || storageType == 'opfs') {
      final fsStorage = await FileSystemStorageService.getInstance();
      await fsStorage.refreshCaches();
      _storage = fsStorage;
    } else {
      await FileSystemStorageService.setConfigured('local');
      _storage = await StorageService.getInstance();
    }

    _templateRepository = TemplateRepository(_storage);
    _noteRepository = NoteRepository(_storage);

    // Seed sample data for new storage
    await _seedSampleData();

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
