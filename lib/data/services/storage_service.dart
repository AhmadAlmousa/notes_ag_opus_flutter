import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting data using web storage.
class StorageService {
  StorageService._();
  StorageService.internal();
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  /// Gets the singleton instance.
  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// Storage keys.
  static const String _templatesKey = 'organote_templates';
  static const String _notesKey = 'organote_notes';
  static const String _categoriesKey = 'organote_categories';
  static const String _settingsKey = 'organote_settings';
  static const String _searchIndexKey = 'organote_search_index';

  // Templates
  /// Gets all templates as a map of templateId -> markdown content.
  Map<String, String> getTemplates() {
    final json = _prefs?.getString(_templatesKey);
    if (json == null) return {};
    return Map<String, String>.from(jsonDecode(json) as Map);
  }

  /// Gets a single template by ID.
  String? getTemplate(String templateId) {
    return getTemplates()[templateId];
  }

  /// Saves a template.
  Future<void> saveTemplate(String templateId, String markdownContent) async {
    final templates = getTemplates();
    templates[templateId] = markdownContent;
    await _prefs?.setString(_templatesKey, jsonEncode(templates));
  }

  /// Deletes a template.
  Future<void> deleteTemplate(String templateId) async {
    final templates = getTemplates();
    templates.remove(templateId);
    await _prefs?.setString(_templatesKey, jsonEncode(templates));
  }

  // Notes
  /// Gets all notes as a map of "category/filename" -> markdown content.
  Map<String, String> getNotes() {
    final json = _prefs?.getString(_notesKey);
    if (json == null) return {};
    return Map<String, String>.from(jsonDecode(json) as Map);
  }

  /// Gets notes for a specific category.
  Map<String, String> getNotesByCategory(String category) {
    final allNotes = getNotes();
    final categoryNotes = <String, String>{};
    for (final entry in allNotes.entries) {
      if (entry.key.startsWith('$category/')) {
        categoryNotes[entry.key] = entry.value;
      }
    }
    return categoryNotes;
  }

  /// Gets a single note.
  String? getNote(String category, String filename) {
    return getNotes()['$category/$filename'];
  }

  /// Saves a note.
  Future<void> saveNote(
    String category,
    String filename,
    String markdownContent,
  ) async {
    final notes = getNotes();
    notes['$category/$filename'] = markdownContent;
    await _prefs?.setString(_notesKey, jsonEncode(notes));
    await _updateCategories(category);
  }

  /// Deletes a note.
  Future<void> deleteNote(String category, String filename) async {
    final notes = getNotes();
    notes.remove('$category/$filename');
    await _prefs?.setString(_notesKey, jsonEncode(notes));
  }

  // Categories
  /// Gets all categories.
  List<String> getCategories() {
    final json = _prefs?.getString(_categoriesKey);
    if (json == null) {
      return ['personal', 'work', 'family'];
    }
    return List<String>.from(jsonDecode(json) as List);
  }

  /// Adds a category if it doesn't exist.
  Future<void> _updateCategories(String category) async {
    final categories = getCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await _prefs?.setString(_categoriesKey, jsonEncode(categories));
    }
  }

  /// Adds a new category.
  Future<void> addCategory(String category) async {
    await _updateCategories(category);
  }

  // Search Index
  /// Gets the search index.
  Map<String, dynamic> getSearchIndex() {
    final json = _prefs?.getString(_searchIndexKey);
    if (json == null) return {};
    return Map<String, dynamic>.from(jsonDecode(json) as Map);
  }

  /// Updates the search index.
  Future<void> updateSearchIndex(Map<String, dynamic> index) async {
    await _prefs?.setString(_searchIndexKey, jsonEncode(index));
  }

  // Settings
  /// Gets app settings.
  Map<String, dynamic> getSettings() {
    final json = _prefs?.getString(_settingsKey);
    if (json == null) {
      return {
        'themeMode': 'system',
        'defaultCategory': 'personal',
      };
    }
    return Map<String, dynamic>.from(jsonDecode(json) as Map);
  }

  /// Saves app settings.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs?.setString(_settingsKey, jsonEncode(settings));
  }

  /// Gets a specific setting.
  T? getSetting<T>(String key) {
    return getSettings()[key] as T?;
  }

  /// Sets a specific setting.
  Future<void> setSetting(String key, dynamic value) async {
    final settings = getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  /// Clears all data (for testing/reset).
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  /// Refresh caches from underlying storage (e.g., re-read files from disk).
  /// No-op for SharedPreferences-based storage; overridden by FileSystemStorageService.
  Future<void> refreshCaches() async {
    // No-op — SharedPreferences is always in sync
  }
}
