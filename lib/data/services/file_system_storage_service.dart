import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'fs_interop.dart';
import 'storage_service.dart';

/// Storage service that uses the File System Access API or OPFS
/// to store notes and templates as real .md files.
class FileSystemStorageService extends StorageService {
  FileSystemStorageService._() : super.internal();

  static FileSystemStorageService? _instance;
  static SharedPreferences? _prefs;

  /// Get the singleton instance.
  static Future<FileSystemStorageService> getInstance() async {
    if (_instance == null) {
      _instance = FileSystemStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// Storage keys for metadata (kept in SharedPreferences).
  static const String _categoriesKey = 'organote_categories';
  static const String _settingsKey = 'organote_settings';
  static const String _searchIndexKey = 'organote_search_index';
  static const String _storageTypeKey = 'organote_storage_type';

  // ─── Storage Setup ───

  /// Whether storage has been configured.
  static bool get isConfigured {
    return _prefs?.getString(_storageTypeKey) != null;
  }

  /// Get the configured storage type.
  static String get configuredStorageType {
    return _prefs?.getString(_storageTypeKey) ?? 'none';
  }

  /// Mark storage as configured.
  static Future<void> setConfigured(String type) async {
    await _prefs?.setString(_storageTypeKey, type);
  }

  /// Try to reconnect to a previously configured directory.
  static Future<bool> tryReconnect() async {
    _prefs ??= await SharedPreferences.getInstance();
    final type = _prefs?.getString(_storageTypeKey);
    if (type == null) return false;

    try {
      if (type == 'fsa' || type == 'local') {
        final name = await FileSystemInterop.reconnect();
        if (name != null) {
          await FileSystemInterop.initDirectories();
          return true;
        }
        return false;
      } else if (type == 'opfs') {
        await FileSystemInterop.useOPFS();
        await FileSystemInterop.initDirectories();
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  // ─── Template Operations ───

  @override
  Map<String, String> getTemplates() {
    // Synchronous - fall back to cached data
    final json = _prefs?.getString('organote_fs_templates_cache');
    if (json == null) return {};
    return Map<String, String>.from(jsonDecode(json) as Map);
  }

  /// Async version that reads from file system.
  Future<Map<String, String>> getTemplatesAsync() async {
    try {
      final templates = await FileSystemInterop.getAllTemplates();
      // Cache for synchronous access
      await _prefs?.setString(
          'organote_fs_templates_cache', jsonEncode(templates));
      return templates;
    } catch (e) {
      return getTemplates(); // Fall back to cache
    }
  }

  @override
  String? getTemplate(String templateId) {
    return getTemplates()[templateId];
  }

  @override
  Future<void> saveTemplate(String templateId, String markdownContent) async {
    await FileSystemInterop.writeFile(
        'templates/$templateId.md', markdownContent);
    // Update cache
    final templates = getTemplates();
    templates[templateId] = markdownContent;
    await _prefs?.setString(
        'organote_fs_templates_cache', jsonEncode(templates));
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    try {
      await FileSystemInterop.deleteFile('templates/$templateId.md');
    } catch (_) {}
    // Update cache
    final templates = getTemplates();
    templates.remove(templateId);
    await _prefs?.setString(
        'organote_fs_templates_cache', jsonEncode(templates));
  }

  // ─── Note Operations ───

  @override
  Map<String, String> getNotes() {
    // Synchronous - fall back to cached data
    final json = _prefs?.getString('organote_fs_notes_cache');
    if (json == null) return {};
    return Map<String, String>.from(jsonDecode(json) as Map);
  }

  /// Async version that reads from file system.
  Future<Map<String, String>> getNotesAsync() async {
    try {
      final notes = await FileSystemInterop.getAllNotes();
      // Cache for synchronous access
      await _prefs?.setString('organote_fs_notes_cache', jsonEncode(notes));
      return notes;
    } catch (e) {
      return getNotes(); // Fall back to cache
    }
  }

  @override
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

  @override
  String? getNote(String category, String filename) {
    return getNotes()['$category/$filename'];
  }

  @override
  Future<void> saveNote(
    String category,
    String filename,
    String markdownContent,
  ) async {
    // Ensure .md extension
    final safeFilename = filename.endsWith('.md') ? filename : '$filename.md';
    await FileSystemInterop.writeFile(
        'notes/$category/$safeFilename', markdownContent);
    // Update cache
    final notes = getNotes();
    notes['$category/$safeFilename'] = markdownContent;
    await _prefs?.setString('organote_fs_notes_cache', jsonEncode(notes));
    await _updateCategories(category);
  }

  @override
  Future<void> deleteNote(String category, String filename) async {
    try {
      await FileSystemInterop.deleteFile('notes/$category/$filename');
    } catch (_) {}
    // Update cache
    final notes = getNotes();
    notes.remove('$category/$filename');
    await _prefs?.setString('organote_fs_notes_cache', jsonEncode(notes));
  }

  // ─── Categories ───

  @override
  List<String> getCategories() {
    final json = _prefs?.getString(_categoriesKey);
    if (json == null) {
      return ['personal', 'work', 'family'];
    }
    return List<String>.from(jsonDecode(json) as List);
  }

  Future<void> _updateCategories(String category) async {
    final categories = getCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await _prefs?.setString(_categoriesKey, jsonEncode(categories));
    }
  }

  @override
  Future<void> addCategory(String category) async {
    await _updateCategories(category);
  }

  // ─── Search Index ───

  @override
  Map<String, dynamic> getSearchIndex() {
    final json = _prefs?.getString(_searchIndexKey);
    if (json == null) return {};
    return Map<String, dynamic>.from(jsonDecode(json) as Map);
  }

  @override
  Future<void> updateSearchIndex(Map<String, dynamic> index) async {
    await _prefs?.setString(_searchIndexKey, jsonEncode(index));
  }

  // ─── Settings ───

  @override
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

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs?.setString(_settingsKey, jsonEncode(settings));
  }

  @override
  T? getSetting<T>(String key) {
    return getSettings()[key] as T?;
  }

  @override
  Future<void> setSetting(String key, dynamic value) async {
    final settings = getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  @override
  Future<void> clearAll() async {
    await _prefs?.clear();
    // Note: doesn't delete files from filesystem
  }

  /// Refresh caches from file system.
  Future<void> refreshCaches() async {
    await getNotesAsync();
    await getTemplatesAsync();
  }
}
