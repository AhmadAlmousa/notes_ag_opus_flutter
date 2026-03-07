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

  /// Initialize the shared preferences from a subclass instance.
  /// This ensures trash and settings methods work when using subclasses.
  static void initPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Storage keys.
  static const String _templatesKey = 'organote_templates';
  static const String _notesKey = 'organote_notes';
  static const String _categoriesKey = 'organote_categories';
  static const String _settingsKey = 'organote_settings';
  static const String _searchIndexKey = 'organote_search_index';
  static const String _trashKey = 'organote_trash';

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

  /// Saves the full category list (used by rename/delete).
  Future<void> saveCategories(List<String> categories) async {
    await _prefs?.setString(_categoriesKey, jsonEncode(categories));
  }

  /// Removes a category from the list.
  Future<void> removeCategory(String category) async {
    final categories = getCategories();
    categories.remove(category);
    await saveCategories(categories);
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

  // ─── Trash / Recycle Bin ───

  /// Gets all trashed items as a map of "category/filename" → {content, deletedAt, expiresAt}.
  Map<String, Map<String, dynamic>> getTrash() {
    final json = _prefs?.getString(_trashKey);
    if (json == null) return {};
    final raw = jsonDecode(json) as Map;
    return raw.map((k, v) =>
        MapEntry(k as String, Map<String, dynamic>.from(v as Map)));
  }

  /// Moves a note to the trash (soft delete).
  Future<void> addToTrash(
      String category, String filename, String content) async {
    final trash = getTrash();
    final now = DateTime.now().toUtc();
    trash['$category/$filename'] = {
      'content': content,
      'category': category,
      'filename': filename,
      'deletedAt': now.toIso8601String(),
      'expiresAt': now.add(const Duration(days: 7)).toIso8601String(),
    };
    await _prefs?.setString(_trashKey, jsonEncode(trash));
  }

  /// Restores a note from the trash back to active notes.
  Future<void> restoreFromTrash(String key) async {
    final trash = getTrash();
    final item = trash[key];
    if (item == null) return;
    await saveNote(
        item['category'] as String, item['filename'] as String, item['content'] as String);
    trash.remove(key);
    await _prefs?.setString(_trashKey, jsonEncode(trash));
  }

  /// Permanently removes a note from the trash.
  Future<void> removeFromTrash(String key) async {
    final trash = getTrash();
    trash.remove(key);
    await _prefs?.setString(_trashKey, jsonEncode(trash));
  }

  /// Alias for removeFromTrash — used by the RecycleBinScreen.
  Future<void> permanentlyDeleteFromTrash(String key) => removeFromTrash(key);

  /// Purges items older than 7 days from the trash.
  Future<int> purgeExpiredTrash() async {
    final trash = getTrash();
    final now = DateTime.now().toUtc();
    final keysToRemove = <String>[];
    for (final entry in trash.entries) {
      final expiresAt = DateTime.tryParse(entry.value['expiresAt'] as String? ?? '');
      if (expiresAt != null && now.isAfter(expiresAt)) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      trash.remove(key);
    }
    if (keysToRemove.isNotEmpty) {
      await _prefs?.setString(_trashKey, jsonEncode(trash));
    }
    return keysToRemove.length;
  }
}
