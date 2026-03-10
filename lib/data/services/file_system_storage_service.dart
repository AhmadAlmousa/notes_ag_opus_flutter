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
      // Also initialize parent StorageService._prefs so trash methods work
      StorageService.initPrefs(_prefs!);
    }
    return _instance!;
  }

  /// Storage keys for metadata (kept in SharedPreferences).
  static const String _categoriesKey = 'organote_categories';
  static const String _settingsKey = 'organote_settings';
  static const String _searchIndexKey = 'organote_search_index';
  static const String _storageTypeKey = 'organote_storage_type';

  /// P3.3: In-memory caches — reads hit these instead of deserializing from SharedPreferences.
  Map<String, String>? _templatesCache;
  Map<String, String>? _notesCache;

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

  /// Whether the FSA handle needs a user gesture to re-grant permission.
  static bool needsUserActivation = false;

  /// Try to reconnect to a previously configured directory.
  /// If reconnect returns 'NEEDS_ACTIVATION', sets [needsUserActivation] = true
  /// and returns false. The app should then show a RestoreAccessScreen.
  static Future<bool> tryReconnect() async {
    _prefs ??= await SharedPreferences.getInstance();
    final type = _prefs?.getString(_storageTypeKey);
    if (type == null) return false;

    try {
      if (type == 'fsa' || type == 'local') {
        final name = await FileSystemInterop.reconnect();
        if (name == 'NEEDS_ACTIVATION') {
          needsUserActivation = true;
          return false;
        }
        if (name != null) {
          needsUserActivation = false;
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
    // P3.3: Return in-memory cache if populated
    if (_templatesCache != null) return Map.from(_templatesCache!);
    // Fallback: deserialize from SharedPreferences backup
    final json = _prefs?.getString('organote_fs_templates_cache');
    if (json == null) return {};
    _templatesCache = Map<String, String>.from(jsonDecode(json) as Map);
    return Map.from(_templatesCache!);
  }

  /// Async version that reads from file system.
  Future<Map<String, String>> getTemplatesAsync() async {
    try {
      final templates = await FileSystemInterop.getAllTemplates();
      _templatesCache = templates;
      // Persist to SharedPreferences as backup
      await _prefs?.setString(
          'organote_fs_templates_cache', jsonEncode(templates));
      return templates;
    } catch (e) {
      return getTemplates();
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
    // Update in-memory cache
    _templatesCache ??= {};
    _templatesCache![templateId] = markdownContent;
    // Backup to SharedPreferences
    await _prefs?.setString(
        'organote_fs_templates_cache', jsonEncode(_templatesCache));
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    try {
      await FileSystemInterop.deleteFile('templates/$templateId.md');
    } catch (_) {}
    _templatesCache?.remove(templateId);
    await _prefs?.setString(
        'organote_fs_templates_cache', jsonEncode(_templatesCache ?? {}));
  }

  // ─── Note Operations ───

  @override
  Map<String, String> getNotes() {
    // P3.3: Return in-memory cache if populated
    if (_notesCache != null) return Map.from(_notesCache!);
    // Fallback: deserialize from SharedPreferences backup
    final json = _prefs?.getString('organote_fs_notes_cache');
    if (json == null) return {};
    _notesCache = Map<String, String>.from(jsonDecode(json) as Map);
    return Map.from(_notesCache!);
  }

  /// Async version that reads from file system.
  Future<Map<String, String>> getNotesAsync() async {
    try {
      final notes = await FileSystemInterop.getAllNotes();
      _notesCache = notes;
      // Backup to SharedPreferences
      await _prefs?.setString('organote_fs_notes_cache', jsonEncode(notes));
      return notes;
    } catch (e) {
      return getNotes();
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
    final safeFilename = filename.endsWith('.md') ? filename : '$filename.md';
    await FileSystemInterop.writeFile(
        'notes/$category/$safeFilename', markdownContent);
    // Update in-memory cache
    _notesCache ??= {};
    _notesCache!['$category/$safeFilename'] = markdownContent;
    // Backup to SharedPreferences
    await _prefs?.setString('organote_fs_notes_cache', jsonEncode(_notesCache));
  }

  @override
  Future<void> deleteNote(String category, String filename) async {
    try {
      await FileSystemInterop.deleteFile('notes/$category/$filename');
    } catch (_) {}
    _notesCache?.remove('$category/$filename');
    await _prefs?.setString(
        'organote_fs_notes_cache', jsonEncode(_notesCache ?? {}));
  }

  // ─── Categories ───

  @override
  List<String> getCategories() {
    // Static defaults
    final defaults = <String>{'personal', 'work', 'family'};

    // Derive categories from actual note paths in the cache
    final notes = getNotes();
    final fromNotes = <String>{};
    for (final key in notes.keys) {
      final parts = key.split('/');
      if (parts.length >= 2) {
        fromNotes.add(parts.first);
      }
    }

    // Combine defaults + filesystem categories, defaults first
    final result = [...defaults];
    for (final cat in fromNotes) {
      if (!result.contains(cat)) {
        result.add(cat);
      }
    }
    return result;
  }

  @override
  Future<void> addCategory(String category) async {
    // No-op: categories are derived from filesystem.
    // A category appears when a note is saved in that folder.
  }

  @override
  Future<void> saveCategories(List<String> categories) async {
    // No-op: categories are derived from filesystem.
  }

  @override
  Future<void> removeCategory(String category) async {
    final categories = getCategories();
    categories.remove(category);
    await saveCategories(categories);
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
