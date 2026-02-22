import 'dart:js_interop';

/// Dart interop bindings for the organoteFS JavaScript helper.
/// This provides access to File System Access API and OPFS fallback.

@JS('organoteFS.isFileSystemAccessSupported')
external bool _isFileSystemAccessSupported();

@JS('organoteFS.isOPFSSupported')
external bool _isOPFSSupported();

@JS('organoteFS.getBestStorageType')
external String _getBestStorageType();

@JS('organoteFS.pickDirectory')
external JSPromise<JSString> _pickDirectory();

@JS('organoteFS.useOPFS')
external JSPromise<JSString> _useOPFS();

@JS('organoteFS.reconnect')
external JSPromise<JSString?> _reconnect();

@JS('organoteFS.getStorageType')
external String _getStorageType();

@JS('organoteFS.getDirectoryName')
external String? _getDirectoryName();

@JS('organoteFS.writeFile')
external JSPromise _writeFile(String path, String content);

@JS('organoteFS.readFile')
external JSPromise<JSString> _readFile(String path);

@JS('organoteFS.deleteFile')
external JSPromise _deleteFile(String path);

@JS('organoteFS.fileExists')
external JSPromise<JSBoolean> _fileExists(String path);

@JS('organoteFS.directoryExists')
external JSPromise<JSBoolean> _directoryExists(String path);

@JS('organoteFS.getAllNotes')
external JSPromise<JSObject> _getAllNotes();

@JS('organoteFS.getAllTemplates')
external JSPromise<JSObject> _getAllTemplates();

@JS('organoteFS.initDirectories')
external JSPromise _initDirectories();

@JS('organoteFS.disconnect')
external JSPromise _disconnect();

// JS Object.keys and Object.entries helpers
@JS('Object.keys')
external JSArray<JSString> _objectKeys(JSObject obj);

@JS('Object.entries')
external JSArray<JSArray<JSAny>> _objectEntries(JSObject obj);

/// High-level Dart API for file system operations.
class FileSystemInterop {
  const FileSystemInterop._();

  /// Check if File System Access API is available.
  static bool get isFileSystemAccessSupported {
    try {
      return _isFileSystemAccessSupported();
    } catch (_) {
      return false;
    }
  }

  /// Check if OPFS is available.
  static bool get isOPFSSupported {
    try {
      return _isOPFSSupported();
    } catch (_) {
      return false;
    }
  }

  /// Get the best available storage type: 'fsa', 'opfs', or 'none'.
  static String get bestStorageType {
    try {
      return _getBestStorageType();
    } catch (_) {
      return 'none';
    }
  }

  /// Get the currently active storage type.
  static String get currentStorageType {
    try {
      return _getStorageType();
    } catch (_) {
      return 'none';
    }
  }

  /// Get the current directory name.
  static String? get directoryName {
    try {
      return _getDirectoryName();
    } catch (_) {
      return null;
    }
  }

  /// Pick a directory using File System Access API.
  /// Returns the directory name on success.
  static Future<String> pickDirectory() async {
    final result = await _pickDirectory().toDart;
    return result.toDart;
  }

  /// Use OPFS (Origin Private File System) for storage.
  /// Returns the storage name.
  static Future<String> useOPFS() async {
    final result = await _useOPFS().toDart;
    return result.toDart;
  }

  /// Try to reconnect to a previously saved directory.
  /// Returns directory name if successful, null otherwise.
  static Future<String?> reconnect() async {
    final result = await _reconnect().toDart;
    return result?.toDart;
  }

  /// Initialize notes/ and templates/ directories.
  static Future<void> initDirectories() async {
    await _initDirectories().toDart;
  }

  /// Write content to a file path (e.g., "notes/personal/myfile.md").
  static Future<void> writeFile(String path, String content) async {
    await _writeFile(path, content).toDart;
  }

  /// Read content from a file path.
  static Future<String> readFile(String path) async {
    final result = await _readFile(path).toDart;
    return result.toDart;
  }

  /// Delete a file at the given path.
  static Future<void> deleteFile(String path) async {
    await _deleteFile(path).toDart;
  }

  /// Check if a file exists.
  static Future<bool> fileExists(String path) async {
    final result = await _fileExists(path).toDart;
    return result.toDart;
  }

  /// Check if a directory exists.
  static Future<bool> directoryExists(String path) async {
    final result = await _directoryExists(path).toDart;
    return result.toDart;
  }

  /// Get all notes as a Map of "category/filename" -> markdown content.
  static Future<Map<String, String>> getAllNotes() async {
    final jsObj = await _getAllNotes().toDart;
    return _jsObjectToMap(jsObj);
  }

  /// Get all templates as a Map of "templateId" -> markdown content.
  static Future<Map<String, String>> getAllTemplates() async {
    final jsObj = await _getAllTemplates().toDart;
    return _jsObjectToMap(jsObj);
  }

  /// Disconnect from current storage.
  static Future<void> disconnect() async {
    await _disconnect().toDart;
  }

  /// Convert a JSObject to a Dart Map<String, String>.
  static Map<String, String> _jsObjectToMap(JSObject obj) {
    final map = <String, String>{};
    final keys = _objectKeys(obj);
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i].toDart;
      // Access property using JS interop
      final value = (obj as JSAny).dartify();
      if (value is Map) {
        for (final entry in value.entries) {
          map[entry.key.toString()] = entry.value.toString();
        }
        return map;
      }
    }
    return map;
  }
}
