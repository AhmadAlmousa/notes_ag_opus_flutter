import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Native IO implementation of FileSystemInterop.
/// Used on Android, iOS, Windows, Linux, and macOS.
class FileSystemInterop {
  const FileSystemInterop._();

  static String? _rootPath;
  static const String _prefsKey = 'organote_io_root_path';

  /// Check if File System Access API is available (web only).
  static bool get isFileSystemAccessSupported => false;

  /// Check if OPFS is available (web only).
  static bool get isOPFSSupported => false;

  /// Get the best available storage type.
  static String get bestStorageType => 'local';

  /// Get the currently active storage type.
  static String get currentStorageType => _rootPath != null ? 'local' : 'none';

  /// Get the current directory name.
  static String? get directoryName {
    if (_rootPath == null) return null;
    return p.basename(_rootPath!);
  }

  /// Set the root directory from a picked path and save to prefs.
  static Future<String> setRootPath(String path) async {
    _rootPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
    return p.basename(path);
  }

  /// Pick a directory — on native, this is called from the setup screen
  /// which passes us a path from file_picker. We just store it.
  static Future<String> pickDirectory() async {
    // This is a no-op stub; the actual picking is done via file_picker
    // in the setup screen, which then calls setRootPath().
    throw UnsupportedError(
      'Use file_picker to pick directory, then call FileSystemInterop.setRootPath()',
    );
  }

  /// Use OPFS (web only stub — no-op on native).
  static Future<String> useOPFS() async {
    throw UnsupportedError('OPFS is only available on web');
  }

  /// Try to reconnect to a previously saved directory.
  static Future<String?> reconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && Directory(saved).existsSync()) {
      _rootPath = saved;
      return p.basename(saved);
    }
    return null;
  }

  /// Initialize notes/ and templates/ directories.
  static Future<void> initDirectories() async {
    if (_rootPath == null) return;
    final notesDir = Directory(p.join(_rootPath!, 'notes'));
    final templatesDir = Directory(p.join(_rootPath!, 'templates'));
    if (!notesDir.existsSync()) await notesDir.create(recursive: true);
    if (!templatesDir.existsSync()) await templatesDir.create(recursive: true);
  }

  /// Write content to a file path (e.g., "notes/personal/myfile.md").
  static Future<void> writeFile(String path, String content) async {
    if (_rootPath == null) throw StateError('No root path configured');
    final file = File(p.join(_rootPath!, path));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Read content from a file path.
  static Future<String> readFile(String path) async {
    if (_rootPath == null) throw StateError('No root path configured');
    final file = File(p.join(_rootPath!, path));
    return await file.readAsString();
  }

  /// Delete a file at the given path.
  static Future<void> deleteFile(String path) async {
    if (_rootPath == null) return;
    final file = File(p.join(_rootPath!, path));
    if (file.existsSync()) await file.delete();
  }

  /// Check if a file exists.
  static Future<bool> fileExists(String path) async {
    if (_rootPath == null) return false;
    return File(p.join(_rootPath!, path)).existsSync();
  }

  /// Check if a directory exists.
  static Future<bool> directoryExists(String path) async {
    if (_rootPath == null) return false;
    return Directory(p.join(_rootPath!, path)).existsSync();
  }

  /// Get all notes as a Map of "category/filename" → markdown content.
  static Future<Map<String, String>> getAllNotes() async {
    if (_rootPath == null) return {};
    final notesDir = Directory(p.join(_rootPath!, 'notes'));
    if (!notesDir.existsSync()) return {};

    final map = <String, String>{};
    await for (final entity in notesDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final relative = p.relative(entity.path, from: notesDir.path);
        // Normalize to forward slashes for cross-platform
        final key = relative.replaceAll('\\', '/');
        map[key] = await entity.readAsString();
      }
    }
    return map;
  }

  /// Get all templates as a Map of "templateId" → markdown content.
  static Future<Map<String, String>> getAllTemplates() async {
    if (_rootPath == null) return {};
    final templatesDir = Directory(p.join(_rootPath!, 'templates'));
    if (!templatesDir.existsSync()) return {};

    final map = <String, String>{};
    await for (final entity in templatesDir.list()) {
      if (entity is File && entity.path.endsWith('.md')) {
        final name = p.basenameWithoutExtension(entity.path);
        map[name] = await entity.readAsString();
      }
    }
    return map;
  }

  /// Disconnect from current storage.
  static Future<void> disconnect() async {
    _rootPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
