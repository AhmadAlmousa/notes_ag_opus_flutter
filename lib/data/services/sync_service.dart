import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'storage_service.dart';

/// Callback type for notifying the UI about remote changes.
typedef OnRemoteChange = void Function();

/// Google Drive sync service.
///
/// Stores notes and templates as .md files inside an "Organote" folder
/// in the user's Google Drive.  Conflict resolution: last-write-wins
/// based on file `modifiedTime`.
class SyncService {
  SyncService._();

  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
    // Web client ID — read from google-services.json on Android automatically.
    // For web, also set via <meta name="google-signin-client_id"> in index.html.
    clientId: '498575043406-dbci3jfmenn1rpgaojakg232m7filvav.apps.googleusercontent.com',
  );

  drive.DriveApi? _driveApi;
  StorageService? _storage;
  String? _rootFolderId; // "Organote" folder ID
  bool _connected = false;

  /// Callback invoked when a remote change is received and applied locally.
  OnRemoteChange? onRemoteChange;

  /// Whether the service is connected (signed in with a valid Drive client).
  bool get isConnected => _connected;

  /// Currently signed-in account email.
  String? get accountEmail => _googleSignIn.currentUser?.email;

  // ── Authentication ──────────────────────────────────────────────────

  /// Sign in to Google and initialize Drive API.
  Future<bool> signIn({required StorageService storage}) async {
    _storage = storage;
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false; // user cancelled

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      _driveApi = drive.DriveApi(httpClient);
      _rootFolderId = await _getOrCreateFolder('Organote');
      _connected = true;
      return true;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return false;
    }
  }

  /// Try to silently reconnect (e.g., on app restart).
  Future<bool> tryReconnect({required StorageService storage}) async {
    _storage = storage;
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      _driveApi = drive.DriveApi(httpClient);
      _rootFolderId = await _getOrCreateFolder('Organote');
      _connected = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sign out and disconnect.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _rootFolderId = null;
    _connected = false;
  }

  // ── Push operations ─────────────────────────────────────────────────

  /// Push a single document to Google Drive.
  /// [path] is e.g. "notes/personal/myfile.md" or "templates/family_login.md".
  Future<void> pushDocument(String path, String content) async {
    if (_driveApi == null || _rootFolderId == null) return;
    try {
      final parentId = await _ensureFolderPath(path);
      final fileName = path.split('/').last;

      final existing = await _findFile(fileName, parentId);
      final media = drive.Media(
        Stream.value(utf8.encode(content)),
        utf8.encode(content).length,
      );

      if (existing != null) {
        // Update existing file
        await _driveApi!.files.update(
          drive.File()..modifiedTime = DateTime.now().toUtc(),
          existing.id!,
          uploadMedia: media,
        );
      } else {
        // Create new file
        await _driveApi!.files.create(
          drive.File()
            ..name = fileName
            ..parents = [parentId]
            ..mimeType = 'text/markdown'
            ..modifiedTime = DateTime.now().toUtc(),
          uploadMedia: media,
        );
      }
    } catch (e) {
      debugPrint('pushDocument error: $e');
    }
  }

  /// Push a deletion to Google Drive.
  Future<void> pushDeletion(String path) async {
    if (_driveApi == null || _rootFolderId == null) return;
    try {
      final parentId = await _ensureFolderPath(path);
      final fileName = path.split('/').last;
      final existing = await _findFile(fileName, parentId);
      if (existing != null) {
        await _driveApi!.files.delete(existing.id!);
      }
    } catch (e) {
      debugPrint('pushDeletion error: $e');
    }
  }

  /// Push all local notes and templates to Drive.
  Future<void> pushAll() async {
    if (_driveApi == null || _storage == null) return;

    // Push templates
    final templates = _storage!.getTemplates();
    for (final entry in templates.entries) {
      await pushDocument('templates/${entry.key}.md', entry.value);
    }

    // Push notes
    final notes = _storage!.getNotes();
    for (final entry in notes.entries) {
      final path = 'notes/${entry.key}';
      final safePath = path.endsWith('.md') ? path : '$path.md';
      await pushDocument(safePath, entry.value);
    }
  }

  /// Pull all remote docs from Drive and overwrite local.
  Future<void> pullAll() async {
    if (_driveApi == null || _storage == null || _rootFolderId == null) return;

    try {
      // Pull templates
      final templatesFolderId = await _findFolder('templates', _rootFolderId!);
      if (templatesFolderId != null) {
        final templateFiles = await _listFiles(templatesFolderId);
        for (final file in templateFiles) {
          final content = await _downloadFile(file.id!);
          if (content != null && file.name != null) {
            final templateId = file.name!.replaceAll('.md', '');
            await _storage!.saveTemplate(templateId, content);
          }
        }
      }

      // Pull notes (recursive — category folders)
      final notesFolderId = await _findFolder('notes', _rootFolderId!);
      if (notesFolderId != null) {
        // List category folders
        final categoryFolders = await _listFolders(notesFolderId);
        for (final catFolder in categoryFolders) {
          final category = catFolder.name ?? 'unknown';
          final noteFiles = await _listFiles(catFolder.id!);
          for (final file in noteFiles) {
            final content = await _downloadFile(file.id!);
            if (content != null && file.name != null) {
              await _storage!.saveNote(category, file.name!, content);
            }
          }
        }
      }

      // Notify UI
      onRemoteChange?.call();
    } catch (e) {
      debugPrint('pullAll error: $e');
    }
  }

  /// Full bidirectional sync.
  Future<void> syncAll() async {
    await pushAll();
    await pullAll();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Get or create the "Organote" root folder.
  Future<String> _getOrCreateFolder(String name,
      {String? parentId}) async {
    final parent = parentId ?? 'root';
    final q = "name = '$name' and mimeType = 'application/vnd.google-apps.folder'"
        " and '$parent' in parents and trashed = false";
    final result = await _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    // Create folder
    final folder = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [parent];
    final created = await _driveApi!.files.create(folder);
    return created.id!;
  }

  /// Find a sub-folder by name.
  Future<String?> _findFolder(String name, String parentId) async {
    final q = "name = '$name' and mimeType = 'application/vnd.google-apps.folder'"
        " and '$parentId' in parents and trashed = false";
    final result = await _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }
    return null;
  }

  /// Find a file by name inside a folder.
  Future<drive.File?> _findFile(String name, String parentId) async {
    final q = "name = '$name' and '$parentId' in parents"
        " and mimeType != 'application/vnd.google-apps.folder'"
        " and trashed = false";
    final result = await _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime)',
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first;
    }
    return null;
  }

  /// List all non-folder files in a folder.
  Future<List<drive.File>> _listFiles(String parentId) async {
    final q = "'$parentId' in parents"
        " and mimeType != 'application/vnd.google-apps.folder'"
        " and trashed = false";
    final result = await _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime)',
    );
    return result.files ?? [];
  }

  /// List all sub-folders in a folder.
  Future<List<drive.File>> _listFolders(String parentId) async {
    final q = "'$parentId' in parents"
        " and mimeType = 'application/vnd.google-apps.folder'"
        " and trashed = false";
    final result = await _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    return result.files ?? [];
  }

  /// Ensure all intermediate folders in a path exist (relative to Organote).
  /// Returns the parent folder ID where the file should be placed.
  Future<String> _ensureFolderPath(String path) async {
    final parts = path.split('/');
    if (parts.length <= 1) return _rootFolderId!;

    // Remove the file name — keep only folder segments
    final folders = parts.sublist(0, parts.length - 1);
    String currentParent = _rootFolderId!;
    for (final folder in folders) {
      currentParent = await _getOrCreateFolder(folder, parentId: currentParent);
    }
    return currentParent;
  }

  /// Download a file's text content by ID.
  Future<String?> _downloadFile(String fileId) async {
    try {
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
    } catch (e) {
      debugPrint('downloadFile error: $e');
      return null;
    }
  }

  /// Dispose and clean up.
  void dispose() {
    signOut();
    _instance = null;
  }
}
