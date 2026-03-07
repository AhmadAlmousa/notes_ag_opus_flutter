import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _clientId = '498575043406-dbci3jfmenn1rpgaojakg232m7filvav.apps.googleusercontent.com';
  static const _driveScopes = [drive.DriveApi.driveFileScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;
  drive.DriveApi? _driveApi;
  StorageService? _storage;
  String? _rootFolderId; // "Organote" folder ID
  bool _connected = false;
  String? _currentEmail;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  Timer? _pollTimer;
  Timer? _syncDebounceTimer;
  static const _pollInterval = Duration(minutes: 5);
  static const _syncDebounce = Duration(seconds: 5);
  static const _maxRetries = 3;

  /// Folder ID cache to avoid repeated Drive API lookups and race conditions.
  final Map<String, String> _folderIdCache = {};

  /// In-flight folder creation locks to prevent duplicate creation from concurrent calls.
  final Map<String, Completer<String>> _folderLocks = {};

  /// Sequential push lock to prevent concurrent pushDocument race conditions.
  Completer<void>? _pushLock;

  /// Last authentication error message for UI display.
  String? _lastAuthError;

  static const _rootFolderIdKey = 'organote_drive_root_folder_id';

  /// Callback invoked when a remote change is received and applied locally.
  OnRemoteChange? onRemoteChange;

  /// Whether the service is connected (signed in with a valid Drive client).
  bool get isConnected => _connected;

  /// Currently signed-in account email.
  String? get accountEmail => _currentEmail;

  /// Last auth error (if any) — for displaying to the user.
  String? get lastAuthError => _lastAuthError;

  // ── Initialization (v7 requirement) ─────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(
      clientId: _clientId,
      // serverClientId is NOT supported on web — omit it there
      serverClientId: kIsWeb ? null : _clientId,
    );
    _initialized = true;
  }

  /// Obtain an authenticated HTTP client from a GoogleSignInAccount.
  Future<bool> _obtainDriveClientFrom(GoogleSignInAccount account) async {
    try {
      _currentEmail = account.email;

      // Get authorization for Drive scopes
      final authClient = account.authorizationClient;

      // First try without prompting
      var authorization = await authClient.authorizationForScopes(_driveScopes);
      if (authorization == null) {
        // Prompt user for scope authorization
        // This opens a popup on web which may be blocked by COOP headers
        try {
          authorization = await authClient.authorizeScopes(_driveScopes);
        } catch (e) {
          // On web with COOP headers, the popup is blocked.
          _lastAuthError = 'Drive authorization popup was blocked. '
              'If you are using a reverse proxy, remove the '
              'Cross-Origin-Opener-Policy header to allow sync.';
          debugPrint('[Sync] Authorization popup blocked (COOP): $e');
          return false;
        }
      }

      if (authorization == null) {
        _lastAuthError = 'Drive authorization was denied.';
        return false;
      }

      // Build the googleapis HTTP client via the extension
      final httpClient = authorization.authClient(scopes: _driveScopes);

      _driveApi = drive.DriveApi(httpClient);
      _rootFolderId = await _getOrCreateFolder('Organote');
      _connected = true;
      _lastAuthError = null;
      return true;
    } catch (e) {
      _lastAuthError = 'Drive client error: $e';
      debugPrint('[Sync] Drive client error: $e');
      return false;
    }
  }

  // ── Authentication ──────────────────────────────────────────────────

  /// Sign in to Google and initialize Drive API.
  Future<bool> signIn({required StorageService storage}) async {
    _storage = storage;
    try {
      await _ensureInitialized();

      if (kIsWeb) {
        // On web, authenticate() is not supported.
        final completer = Completer<bool>();
        _authSubscription?.cancel();
        _authSubscription = _googleSignIn.authenticationEvents.listen(
          (event) async {
            if (event is GoogleSignInAuthenticationEventSignIn) {
              final account = event.user;
              final result = await _obtainDriveClientFrom(account);
              if (result) {
                startPolling();
                // Initial push on sign-in
                Future.microtask(() => pushAll());
              }
              if (!completer.isCompleted) completer.complete(result);
            }
          },
          onError: (e) {
            debugPrint('Auth stream error: $e');
            if (!completer.isCompleted) completer.complete(false);
          },
        );
        _googleSignIn.attemptLightweightAuthentication();
        return await completer.future.timeout(
          const Duration(seconds: 120),
          onTimeout: () => false,
        );
      }

      // Non-web: use standard authenticate()
      final account = await _googleSignIn.authenticate(
        scopeHint: _driveScopes,
      );

      final result = await _obtainDriveClientFrom(account);
      if (result) {
        startPolling();
        // Initial push on sign-in
        Future.microtask(() => pushAll());
      }
      return result;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In cancelled by user');
        return false;
      }
      debugPrint('Google Sign-In failed: $e');
      return false;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return false;
    }
  }

  /// Try to silently reconnect (e.g., on app restart).
  Future<bool> tryReconnect({required StorageService storage}) async {
    _storage = storage;
    try {
      await _ensureInitialized();

      // On web, don't auto-trigger the sign-in UI.
      // attemptLightweightAuthentication() shows the FedCM prompt which
      // is disorienting on page load. User must explicitly click sign-in.
      if (kIsWeb) return false;

      final maybeFuture = _googleSignIn.attemptLightweightAuthentication();
      if (maybeFuture == null) return false;

      final account = await maybeFuture;
      if (account == null) return false;

      final result = await _obtainDriveClientFrom(account);
      if (result) startPolling();
      return result;
    } catch (_) {
      return false;
    }
  }

  /// Sign out and disconnect.
  Future<void> signOut() async {
    stopPolling();
    _syncDebounceTimer?.cancel();
    await _googleSignIn.signOut();
    _driveApi = null;
    _rootFolderId = null;
    _connected = false;
    _currentEmail = null;
  }

  // ── Polling ─────────────────────────────────────────────────────────

  /// Start periodic remote change polling.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => pullAll());
    debugPrint('[Sync] Polling started (every ${_pollInterval.inMinutes}m)');
  }

  /// Stop periodic polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    debugPrint('[Sync] Polling stopped');
  }

  /// Schedule a debounced pull after a push to detect concurrent edits.
  void _scheduleSyncAfterPush() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounce, () => pullAll());
  }

  // ── Push operations ─────────────────────────────────────────────────

  /// Acquire sequential push lock to avoid folder-creation race conditions.
  Future<void> _acquirePushLock() async {
    while (_pushLock != null) {
      await _pushLock!.future;
    }
    _pushLock = Completer<void>();
  }

  void _releasePushLock() {
    final lock = _pushLock;
    _pushLock = null;
    lock?.complete();
  }

  /// Push a single document to Google Drive with retry.
  Future<void> pushDocument(String path, String content) async {
    if (_driveApi == null || _rootFolderId == null) return;

    await _acquirePushLock();
    try {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          final parentId = await _ensureFolderPath(path);
          final fileName = path.split('/').last;

          final existing = await _findFile(fileName, parentId);
          final media = drive.Media(
            Stream.value(utf8.encode(content)),
            utf8.encode(content).length,
          );

          if (existing != null) {
            await _driveApi!.files.update(
              drive.File()..modifiedTime = DateTime.now().toUtc(),
              existing.id!,
              uploadMedia: media,
            );
          } else {
            await _driveApi!.files.create(
              drive.File()
                ..name = fileName
                ..parents = [parentId]
                ..mimeType = 'text/markdown'
                ..modifiedTime = DateTime.now().toUtc(),
              uploadMedia: media,
            );
          }

          debugPrint('[Sync] Pushed: $path');
          _scheduleSyncAfterPush();
          return; // Success — exit retry loop
        } catch (e) {
          debugPrint('[Sync] pushDocument attempt ${attempt + 1} failed: $e');
          if (attempt < _maxRetries - 1) {
            await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          }
        }
      }
    } finally {
      _releasePushLock();
    }
  }

  /// Push a deletion to Google Drive with retry.
  Future<void> pushDeletion(String path) async {
    if (_driveApi == null || _rootFolderId == null) return;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final parentId = await _ensureFolderPath(path);
        final fileName = path.split('/').last;
        final existing = await _findFile(fileName, parentId);
        if (existing != null) {
          await _driveApi!.files.delete(existing.id!);
        }
        debugPrint('[Sync] Deleted remotely: $path');
        return;
      } catch (e) {
        debugPrint('[Sync] pushDeletion attempt ${attempt + 1} failed: $e');
        if (attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        }
      }
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
      bool hasChanges = false;

      // Pull templates
      final templatesFolderId = await _findFolder('templates', _rootFolderId!);
      if (templatesFolderId != null) {
        final templateFiles = await _listFiles(templatesFolderId);
        for (final file in templateFiles) {
          final content = await _downloadFile(file.id!);
          if (content != null && file.name != null) {
            final templateId = file.name!.replaceAll('.md', '');
            final existing = _storage!.getTemplates()[templateId];
            if (existing != content) {
              await _storage!.saveTemplate(templateId, content);
              hasChanges = true;
            }
          }
        }
      }

      // Pull notes (recursive — category folders)
      final notesFolderId = await _findFolder('notes', _rootFolderId!);
      if (notesFolderId != null) {
        final categoryFolders = await _listFolders(notesFolderId);
        for (final catFolder in categoryFolders) {
          final category = catFolder.name ?? 'unknown';
          final noteFiles = await _listFiles(catFolder.id!);
          for (final file in noteFiles) {
            final content = await _downloadFile(file.id!);
            if (content != null && file.name != null) {
              final existing = _storage!.getNote(category, file.name!);
              if (existing != content) {
                await _storage!.saveNote(category, file.name!, content);
                hasChanges = true;
              }
            }
          }
        }
      }

      // Only notify UI if something actually changed
      if (hasChanges) {
        debugPrint('[Sync] Remote changes detected and applied');
        try {
          onRemoteChange?.call();
        } catch (e) {
          debugPrint('[Sync] onRemoteChange callback error: $e');
        }
      }
    } catch (e) {
      debugPrint('[Sync] pullAll error: $e');
    }
  }

  /// Full bidirectional sync.
  Future<void> syncAll() async {
    await pushAll();
    await pullAll();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// Get or create the "Organote" root folder. Uses cache + locks to prevent duplicates.
  Future<String> _getOrCreateFolder(String name,
      {String? parentId}) async {
    final parent = parentId ?? 'root';
    final cacheKey = '$parent/$name';

    // Check cache first
    if (_folderIdCache.containsKey(cacheKey)) {
      return _folderIdCache[cacheKey]!;
    }

    // If another call is already creating this folder, wait for it
    if (_folderLocks.containsKey(cacheKey)) {
      return _folderLocks[cacheKey]!.future;
    }

    // Take the lock
    final completer = Completer<String>();
    _folderLocks[cacheKey] = completer;

    try {
      final q = "name = '$name' and mimeType = 'application/vnd.google-apps.folder'"
          " and '$parent' in parents and trashed = false";
      final result = await _driveApi!.files.list(
        q: q,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        final folderId = result.files!.first.id!;
        _folderIdCache[cacheKey] = folderId;
        completer.complete(folderId);
        return folderId;
      }

      // Create folder
      final folder = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [parent];
      final created = await _driveApi!.files.create(folder);
      final newId = created.id!;
      _folderIdCache[cacheKey] = newId;

      // Persist root folder ID if this is the Organote folder
      if (name == 'Organote' && parent == 'root') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_rootFolderIdKey, newId);
      }

      completer.complete(newId);
      return newId;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _folderLocks.remove(cacheKey);
    }
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
      debugPrint('[Sync] downloadFile error: $e');
      return null;
    }
  }

  /// Dispose and clean up.
  void dispose() {
    stopPolling();
    _syncDebounceTimer?.cancel();
    signOut();
    _instance = null;
  }
}
