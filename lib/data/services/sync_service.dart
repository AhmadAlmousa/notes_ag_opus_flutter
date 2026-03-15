import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' show AccessDeniedException;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class _TokenAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _TokenAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }
  
  @override
  void close() {
    _inner.close();
    super.close();
  }
}

import 'storage_service.dart';
import 'sync_ledger.dart';
import 'fs_interop.dart';

/// Callback type for notifying the UI about remote changes.
typedef OnRemoteChange = void Function();

/// Granular sync state for reactive UI updates.
enum SyncState {
  /// Not signed in.
  disconnected,
  /// Authentication in progress.
  connecting,
  /// Signed in and idle.
  connected,
  /// Actively syncing files.
  syncing,
  /// An error occurred (check lastAuthError for details).
  error,
}

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
  String? _currentEmail;
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

  /// Sequential sync lock to prevent concurrent syncAll race conditions.
  Completer<void>? _syncLock;

  /// Lock for pushAll specifically to prevent overlap
  Completer<void>? _pushAllLock;

  /// Last authentication error message for UI display.
  String? _lastAuthError;

  static const _rootFolderIdKey = 'organote_drive_root_folder_id';

  /// Callback invoked when a remote change is received and applied locally.
  OnRemoteChange? onRemoteChange;

  /// P3.1: Reactive state notifier — screens watch this via syncStateProvider.
  final ValueNotifier<SyncState> stateNotifier =
      ValueNotifier(SyncState.disconnected);

  /// Whether the service is connected (signed in with a valid Drive client).
  bool get isConnected => stateNotifier.value == SyncState.connected ||
      stateNotifier.value == SyncState.syncing;

  /// Currently signed-in account email.
  String? get accountEmail => _currentEmail;

  /// Last auth error (if any) — for displaying to the user.
  String? get lastAuthError => _lastAuthError;

  // ── Initialization (v7 requirement) ─────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // P2.3: On Android, clientId must be null — reads from google-services.json.
    // On web and iOS, pass the OAuth client ID explicitly.
    await _googleSignIn.initialize(
      clientId: kIsWeb ? _clientId : null,
      serverClientId: _clientId,
    );
    _initialized = true;
  }

  /// Obtain an authenticated HTTP client from a GoogleSignInAccount.
  /// When [silent] is true (e.g., during tryReconnect), skip the interactive
  /// authorizeScopes() popup. If scopes aren't granted, return false gracefully.
  Future<bool> _obtainDriveClientFrom(
    GoogleSignInAccount account, {
    bool silent = false,
  }) async {
    try {
      _currentEmail = account.email;

      // Get authorization for Drive scopes
      final authClient = account.authorizationClient;

      // First try without prompting
      var authorization = await authClient.authorizationForScopes(_driveScopes);
      if (authorization == null) {
        if (silent) {
          // During silent reconnect, don't show popup
          debugPrint('[Sync] Silent auth: scopes not granted, skipping');
          return false;
        }
        // Prompt user for scope authorization
        try {
          authorization = await authClient.authorizeScopes(_driveScopes);
        } catch (e) {
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
      stateNotifier.value = SyncState.connected;
      _lastAuthError = null;
      return true;
    } catch (e) {
      _lastAuthError = 'Drive client error: $e';
      debugPrint('[Sync] Drive client error: $e');
      return false;
    }
  }

  Future<bool> _webAuthorize({bool silent = false}) async {
    try {
      const tokenKey = 'drive_auth_token';
      const expiryKey = 'drive_auth_expiry';

      // 1. Try restoring from cache on silent reauth
      if (silent && _storage != null) {
        final cachedToken = _storage!.getSetting<String>(tokenKey);
        final expiryStr = _storage!.getSetting<String>(expiryKey);
        if (cachedToken != null && expiryStr != null) {
          final expiry = DateTime.tryParse(expiryStr);
          if (expiry != null && DateTime.now().toUtc().add(const Duration(minutes: 5)).isBefore(expiry)) {
            debugPrint('[Sync] Restored cached token (expires $expiry)');
            _driveApi = drive.DriveApi(_TokenAuthClient(cachedToken));
            _currentEmail = _storage!.getSetting<String>('drive_auth_email') ?? 'Web User';
            _rootFolderId = await _getOrCreateFolder('Organote');
            stateNotifier.value = SyncState.connected;
            _lastAuthError = null;
            return true;
          }
        }
        debugPrint('[Sync] Silent auth failed: Cache empty or expired');
        return false; // Prevent popup blocker crash
      }

      final authClient = _googleSignIn.authorizationClient;
      final scopes = List<String>.from(_driveScopes)..add('email');
      
      GoogleSignInClientAuthorization? authz;
      
      if (silent) {
        authz = await authClient.authorizationForScopes(scopes);
      } else {
        authz = await authClient.authorizeScopes(scopes);
      }
      
      if (authz == null) {
        if (!silent) _lastAuthError = 'Drive authorization was denied.';
        return false;
      }
      
      final httpClient = authz.authClient(scopes: scopes);
      _driveApi = drive.DriveApi(httpClient);
      
      try {
        final response = await httpClient.get(Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _currentEmail = data['email'];
        }
      } catch (_) {
        _currentEmail = 'Web User';
      }
      
      if (_storage != null) {
        await _storage!.setSetting(tokenKey, authz.accessToken);
        // Google access tokens live for 3600 seconds
        await _storage!.setSetting(expiryKey, DateTime.now().toUtc().add(const Duration(seconds: 3500)).toIso8601String());
        await _storage!.setSetting('drive_auth_email', _currentEmail);
      }

      _rootFolderId = await _getOrCreateFolder('Organote');
      stateNotifier.value = SyncState.connected;
      _lastAuthError = null;
      return true;
    } catch (e) {
      if (!silent) {
        _lastAuthError = 'Drive authorization error: $e';
        debugPrint('[Sync] Web auth error: $e');
      }
      return false;
    }
  }

  // ── Authentication ──────────────────────────────────────────────────

  /// Sign in to Google and initialize Drive API.
  Future<bool> signIn({required StorageService storage}) async {
    _storage = storage;
    stateNotifier.value = SyncState.connecting;
    try {
      await _ensureInitialized();

      if (kIsWeb) {
        final result = await _webAuthorize(silent: false);
        if (!result) {
          stateNotifier.value = SyncState.error;
        }
        return result;
      }

      // Use standard authenticate for OTHER platforms.
      final account = await _googleSignIn.authenticate(
        scopeHint: _driveScopes,
      );
      
      if (account != null) {
        final result = await _obtainDriveClientFrom(account, silent: false);
        if (!result) {
          stateNotifier.value = SyncState.error;
        }
        return result;
      } else {
        stateNotifier.value = SyncState.disconnected;
        return false;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In cancelled by user');
        stateNotifier.value = SyncState.disconnected;
        return false;
      }
      debugPrint('Google Sign-In failed: $e');
      stateNotifier.value = SyncState.error;
      _lastAuthError = 'Sign-in failed: $e';
      return false;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      stateNotifier.value = SyncState.error;
      _lastAuthError = 'Sign-in failed: $e';
      return false;
    }
  }

  /// Try to silently reconnect (e.g., on app restart).
  Future<bool> tryReconnect({required StorageService storage}) async {
    _storage = storage;
    try {
      await _ensureInitialized();

      if (kIsWeb) {
        return await _webAuthorize(silent: true);
      }

      final maybeFuture = _googleSignIn.attemptLightweightAuthentication();
      if (maybeFuture == null) return false;

      final account = await maybeFuture;
      if (account == null) return false;

      // silent: true prevents authorizeScopes popup
      return await _obtainDriveClientFrom(account, silent: true);
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
    stateNotifier.value = SyncState.disconnected;
    _currentEmail = null;
  }

  // ── Polling (P1.6: kept as no-ops, lifecycle hooks drive sync) ──────

  /// Start periodic remote change polling.
  /// P1.6: No-op — sync is now triggered by app lifecycle hooks.
  void startPolling() {
    debugPrint('[Sync] Polling disabled — using lifecycle hooks');
  }

  /// Stop periodic polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Schedule a debounced pull after a push to detect concurrent edits.
  void _scheduleSyncAfterPush() {
    if (stateNotifier.value == SyncState.syncing || _syncLock != null) return;
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounce, () {
      if (stateNotifier.value != SyncState.syncing) {
        pullAll();
      }
    });
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
  Future<void> pushDocument(String path, String content, {bool skipSync = false}) async {
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
            await _withRetryOn401(() => _driveApi!.files.update(
              drive.File()..modifiedTime = DateTime.now().toUtc(),
              existing.id!,
              uploadMedia: media,
            ));
          } else {
            await _withRetryOn401(() => _driveApi!.files.create(
              drive.File()
                ..name = fileName
                ..parents = [parentId]
                ..mimeType = 'text/markdown'
                ..modifiedTime = DateTime.now().toUtc(),
              uploadMedia: media,
            ));
          }

          debugPrint('[Sync] Pushed: $path');
          if (!skipSync) {
            _scheduleSyncAfterPush();
          }
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
          await _withRetryOn401(() => _driveApi!.files.delete(existing.id!));
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
  /// P3.4: Batched in groups of 5 using Future.wait().
  Future<void> pushAll() async {
    if (_driveApi == null || _storage == null) return;
    if (_syncLock != null || _pushAllLock != null) {
      debugPrint('[Sync] pushAll cancelled: already syncing/pushing');
      return;
    }

    _pushAllLock = Completer<void>();
    try {
      final tasks = <MapEntry<String, String>>[];


    // Collect templates
    final templates = _storage!.getTemplates();
    for (final entry in templates.entries) {
      tasks.add(MapEntry('templates/${entry.key}.md', entry.value));
    }

    // Collect notes
    final notes = _storage!.getNotes();
    for (final entry in notes.entries) {
      final path = 'notes/${entry.key}';
      final safePath = path.endsWith('.md') ? path : '$path.md';
      tasks.add(MapEntry(safePath, entry.value));
    }

    // Process sequentially to avoid _pushLock bottlenecks
    for (final task in tasks) {
      await pushDocument(task.key, task.value, skipSync: true);
    }
    _scheduleSyncAfterPush();
    } finally {
      final lock = _pushAllLock;
      _pushAllLock = null;
      lock?.complete();
    }
  }

  /// Pull all remote docs from Drive and overwrite local.
  /// Now delegates to syncAll() for proper reconciliation.
  Future<void> pullAll() async {
    if (_syncLock != null) {
      debugPrint('[Sync] pullAll cancelled: sync already in progress');
      return;
    }
    await syncAll();
  }

  /// P1.1: Full bidirectional sync with 3-way reconciliation.
  ///
  /// Compares local files, remote Drive files, and the sync ledger to:
  /// - Download new/updated remote files
  /// - Upload new/updated local files
  /// - Delete files removed on either side
  /// - Handle trash zombies (P1.2)
  /// - Skip unchanged files via timestamp comparison (P1.3)
  Future<void> syncAll() async {
    if (_driveApi == null || _storage == null || _rootFolderId == null) return;

    if (_syncLock != null) {
      debugPrint('[Sync] syncAll overlapped - waiting for current sync...');
      await _syncLock!.future;
      return;
    }
    
    if (_pushAllLock != null) {
      // wait for pushAll to finish to avoid conflicts
      await _pushAllLock!.future;
    }

    _syncLock = Completer<void>();

    final wasState = stateNotifier.value;
    stateNotifier.value = SyncState.syncing;
    try {
      final ledger = SyncLedger();
      await ledger.init();
      bool hasChanges = false;

      // ── Build local manifest ──
      final localFiles = <String, String>{}; // path → content
      final templates = _storage!.getTemplates();
      for (final e in templates.entries) {
        localFiles['templates/${e.key}.md'] = e.value;
      }
      final notes = _storage!.getNotes();
      for (final e in notes.entries) {
        final path = 'notes/${e.key}';
        localFiles[path.endsWith('.md') ? path : '$path.md'] = e.value;
      }

      // ── Build remote manifest ──
      final remoteFiles = <String, drive.File>{}; // path → Drive file

      // Templates
      final templatesFolderId = await _findFolder('templates', _rootFolderId!);
      if (templatesFolderId != null) {
        final files = await _listFiles(templatesFolderId);
        for (final f in files) {
          if (f.name != null) remoteFiles['templates/${f.name}'] = f;
        }
      }

      // Notes (recursive category folders)
      final notesFolderId = await _findFolder('notes', _rootFolderId!);
      if (notesFolderId != null) {
        final catFolders = await _listFolders(notesFolderId);
        for (final cat in catFolders) {
          final catName = cat.name ?? 'unknown';
          final catFiles = await _listFiles(cat.id!);
          for (final f in catFiles) {
            if (f.name != null) remoteFiles['notes/$catName/${f.name}'] = f;
          }
        }
      }

      // ── Get trash list for zombie detection (P1.2) ──
      final trashKeys = _storage!.getTrash().keys.map((k) {
        final p = 'notes/$k';
        return p.endsWith('.md') ? p : '$p.md';
      }).toSet();

      // ── All paths across all 3 sources ──
      final allPaths = <String>{
        ...localFiles.keys,
        ...remoteFiles.keys,
        ...ledger.entries.keys,
      };

      for (final path in allPaths) {
        final localContent = localFiles[path];
        final remoteFile = remoteFiles[path];
        final ledgerEntry = ledger.getEntry(path);

        final localHash = localContent != null
            ? SyncLedger.hashContent(localContent)
            : null;
        final remoteModTime = remoteFile?.modifiedTime;

        // ── Case 1: In remote, NOT in ledger → new remote file ──
        if (remoteFile != null && ledgerEntry == null && localContent == null) {
          // P1.2: If this file is in local trash, trash it on Drive instead
          if (trashKeys.contains(path)) {
            try {
              await _withRetryOn401(() => _driveApi!.files.update(
                drive.File()..trashed = true,
                remoteFile.id!,
              ));
              debugPrint('[Sync] Trashed on Drive (zombie): $path');
            } catch (e) {
              debugPrint('[Sync] Failed to trash on Drive: $e');
            }
            continue;
          }

          // Download new remote file
          final content = await _downloadFile(remoteFile.id!);
          if (content != null) {
            await _saveToStorage(path, content);
            await ledger.setEntry(path, SyncEntry(
              localHash: SyncLedger.hashContent(content),
              remoteModifiedTime: remoteModTime,
              syncedAt: DateTime.now().toUtc(),
            ));
            hasChanges = true;
            debugPrint('[Sync] Downloaded new: $path');
          }
        }

        // ── Case 2: In local, NOT in ledger → new local file ──
        else if (localContent != null && ledgerEntry == null && remoteFile == null) {
          await pushDocument(path, localContent);
          await ledger.setEntry(path, SyncEntry(
            localHash: localHash!,
            remoteModifiedTime: DateTime.now().toUtc(),
            syncedAt: DateTime.now().toUtc(),
          ));
          debugPrint('[Sync] Uploaded new: $path');
        }

        // ── Case 3: In both local and remote ──
        else if (localContent != null && remoteFile != null) {
          // P1.3: Delta sync — compare timestamps
          final localChanged = ledgerEntry == null || localHash != ledgerEntry.localHash;
          final remoteChanged = ledgerEntry == null ||
              (remoteModTime != null &&
                  ledgerEntry.remoteModifiedTime != null &&
                  remoteModTime.isAfter(ledgerEntry.remoteModifiedTime!));

          if (remoteChanged && !localChanged) {
            // Remote is newer → download
            final content = await _downloadFile(remoteFile.id!);
            if (content != null) {
              await _saveToStorage(path, content);
              await ledger.setEntry(path, SyncEntry(
                localHash: SyncLedger.hashContent(content),
                remoteModifiedTime: remoteModTime,
                syncedAt: DateTime.now().toUtc(),
              ));
              hasChanges = true;
              debugPrint('[Sync] Updated from remote: $path');
            }
          } else if (localChanged && !remoteChanged) {
            // Local is newer → upload
            await pushDocument(path, localContent);
            await ledger.setEntry(path, SyncEntry(
              localHash: localHash!,
              remoteModifiedTime: DateTime.now().toUtc(),
              syncedAt: DateTime.now().toUtc(),
            ));
            debugPrint('[Sync] Updated to remote: $path');
          } else if (localChanged && remoteChanged) {
            // Conflict — last-write-wins based on modifiedTime
            if (remoteModTime != null && ledgerEntry?.syncedAt != null &&
                remoteModTime.isAfter(ledgerEntry!.syncedAt)) {
              final content = await _downloadFile(remoteFile.id!);
              if (content != null) {
                await _saveToStorage(path, content);
                await ledger.setEntry(path, SyncEntry(
                  localHash: SyncLedger.hashContent(content),
                  remoteModifiedTime: remoteModTime,
                  syncedAt: DateTime.now().toUtc(),
                ));
                hasChanges = true;
                debugPrint('[Sync] Conflict resolved (remote wins): $path');
              }
            } else {
              await pushDocument(path, localContent);
              await ledger.setEntry(path, SyncEntry(
                localHash: localHash!,
                remoteModifiedTime: DateTime.now().toUtc(),
                syncedAt: DateTime.now().toUtc(),
              ));
              debugPrint('[Sync] Conflict resolved (local wins): $path');
            }
          }
          // else: neither changed → skip (P1.3 delta sync)
        }

        // ── Case 4: In ledger, MISSING from local → local deletion ──
        else if (ledgerEntry != null && localContent == null && remoteFile != null) {
          // File was deleted locally → delete from Drive
          try {
            await _withRetryOn401(() => _driveApi!.files.update(
              drive.File()..trashed = true,
              remoteFile.id!,
            ));
            debugPrint('[Sync] Trashed on Drive (local deletion): $path');
            await ledger.removeEntry(path);
          } catch (e) {
            debugPrint('[Sync] Failed to trash on Drive: $e');
          }
        }

        // ── Case 5: In ledger, MISSING from remote → remote deletion ──
        else if (ledgerEntry != null && remoteFile == null && localContent != null) {
          // File was deleted remotely → delete locally
          await _deleteFromStorage(path);
          await ledger.removeEntry(path);
          hasChanges = true;
          debugPrint('[Sync] Deleted locally (remote deletion): $path');
        }

        // ── Case 6: In ledger only → deleted from both ──
        else if (ledgerEntry != null && localContent == null && remoteFile == null) {
          await ledger.removeEntry(path);
        }
      }

      // ── Asset reconciliation (binary files) ──
      try {
        final localAssets = await FileSystemInterop.listAssets();
        final assetsFolderId = await _findFolder('assets', _rootFolderId!);

        // Build remote asset manifest
        final remoteAssets = <String, drive.File>{};
        if (assetsFolderId != null) {
          final files = await _listFiles(assetsFolderId);
          for (final f in files) {
            if (f.name != null) remoteAssets[f.name!] = f;
          }
        }

        final allAssetNames = <String>{
          ...localAssets.keys,
          ...remoteAssets.keys,
        };

        for (final name in allAssetNames) {
          final localSize = localAssets[name];
          final remoteFile = remoteAssets[name];

          if (remoteFile != null && localSize == null) {
            // New remote asset → download
            final bytes = await _downloadBinaryFile(remoteFile.id!);
            if (bytes != null) {
              await FileSystemInterop.writeBytes('assets/$name', bytes);
              hasChanges = true;
              debugPrint('[Sync] Downloaded asset: $name');
            }
          } else if (localSize != null && remoteFile == null) {
            // New local asset → upload
            await pushAsset(name);
            hasChanges = true;
          }
          // Both exist: skip (assets rarely change; could add size comparison)
        }
      } catch (e) {
        debugPrint('[Sync] Asset sync error (non-fatal): $e');
      }

      if (hasChanges) {
        debugPrint('[Sync] Reconciliation complete — changes applied');
        try {
          onRemoteChange?.call();
        } catch (e) {
          debugPrint('[Sync] onRemoteChange callback error: $e');
        }
      } else {
        debugPrint('[Sync] Reconciliation complete — no changes');
      }
      stateNotifier.value = SyncState.connected;
    } catch (e) {
      debugPrint('[Sync] syncAll error: $e');
      stateNotifier.value = SyncState.error;
      _lastAuthError = 'Sync failed: $e';
    } finally {
      final lock = _syncLock;
      _syncLock = null;
      lock?.complete();
    }
  }

  /// Save content to the correct storage location based on path.
  Future<void> _saveToStorage(String path, String content) async {
    if (path.startsWith('templates/')) {
      final templateId = path
          .replaceFirst('templates/', '')
          .replaceAll('.md', '');
      await _storage!.saveTemplate(templateId, content);
    } else if (path.startsWith('notes/')) {
      final parts = path.replaceFirst('notes/', '').split('/');
      if (parts.length >= 2) {
        final category = parts.first;
        final filename = parts.sublist(1).join('/');
        await _storage!.saveNote(category, filename, content);
      }
    }
  }

  /// Delete content from the correct storage location based on path.
  Future<void> _deleteFromStorage(String path) async {
    if (path.startsWith('templates/')) {
      final templateId = path
          .replaceFirst('templates/', '')
          .replaceAll('.md', '');
      await _storage!.deleteTemplate(templateId);
    } else if (path.startsWith('notes/')) {
      final parts = path.replaceFirst('notes/', '').split('/');
      if (parts.length >= 2) {
        final category = parts.first;
        final filename = parts.sublist(1).join('/');
        await _storage!.deleteNote(category, filename);
      }
    }
  }

  /// Push a binary asset to Drive (images, etc.)
  Future<void> pushAsset(String fileName) async {
    if (_driveApi == null || _rootFolderId == null) return;

    try {
      final bytes = await FileSystemInterop.readBytes('assets/$fileName');
      final assetsFolderId = await _getOrCreateFolder('assets',
          parentId: _rootFolderId);

      // Determine mimeType from extension
      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = _mimeTypeForExtension(ext);

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
      );

      final existing = await _findFile(fileName, assetsFolderId);
      if (existing != null) {
        await _withRetryOn401(() => _driveApi!.files.update(
          drive.File()..modifiedTime = DateTime.now().toUtc(),
          existing.id!,
          uploadMedia: media,
        ));
      } else {
        await _withRetryOn401(() => _driveApi!.files.create(
          drive.File()
            ..name = fileName
            ..parents = [assetsFolderId]
            ..mimeType = mimeType
            ..modifiedTime = DateTime.now().toUtc(),
          uploadMedia: media,
        ));
      }
      debugPrint('[Sync] Pushed asset: $fileName');
    } catch (e) {
      debugPrint('[Sync] pushAsset error: $e');
    }
  }

  /// Download a binary file by ID — returns raw bytes.
  Future<List<int>?> _downloadBinaryFile(String fileId) async {
    try {
      final response = await _withRetryOn401(() => _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      )) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      return bytes;
    } catch (e) {
      debugPrint('[Sync] Download binary failed: $e');
      return null;
    }
  }

  /// Get mimeType from file extension.
  String _mimeTypeForExtension(String ext) {
    switch (ext) {
      case 'png': return 'image/png';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'svg': return 'image/svg+xml';
      case 'pdf': return 'application/pdf';
      default: return 'application/octet-stream';
    }
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
      final result = await _withRetryOn401(() => _driveApi!.files.list(
        q: q,
        spaces: 'drive',
        $fields: 'files(id, name)',
      ));

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
      final created = await _withRetryOn401(() => _driveApi!.files.create(folder));
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
    final result = await _withRetryOn401(() => _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name)',
    ));
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
    final result = await _withRetryOn401(() => _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime)',
    ));
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first;
    }
    return null;
  }

  /// List all non-folder files in a folder.
  /// P1.4: Paginated with nextPageToken to handle >100 files.
  Future<List<drive.File>> _listFiles(String parentId) async {
    final allFiles = <drive.File>[];
    String? pageToken;
    do {
      final result = await _withRetryOn401(() => _driveApi!.files.list(
        q: "'$parentId' in parents"
            " and mimeType != 'application/vnd.google-apps.folder'"
            " and trashed = false",
        pageToken: pageToken,
        pageSize: 100,
        spaces: 'drive',
        $fields: 'nextPageToken, files(id, name, modifiedTime)',
      ));
      allFiles.addAll(result.files ?? []);
      pageToken = result.nextPageToken;
    } while (pageToken != null);
    return allFiles;
  }

  /// List all sub-folders in a folder.
  /// P1.4: Paginated with nextPageToken.
  Future<List<drive.File>> _listFolders(String parentId) async {
    final allFolders = <drive.File>[];
    String? pageToken;
    do {
      final result = await _withRetryOn401(() => _driveApi!.files.list(
        q: "'$parentId' in parents"
            " and mimeType = 'application/vnd.google-apps.folder'"
            " and trashed = false",
        pageToken: pageToken,
        pageSize: 100,
        spaces: 'drive',
        $fields: 'nextPageToken, files(id, name)',
      ));
      allFolders.addAll(result.files ?? []);
      pageToken = result.nextPageToken;
    } while (pageToken != null);
    return allFolders;
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
      final response = await _withRetryOn401(() => _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      )) as drive.Media;

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

  /// P1.5: Retry a Drive API call on 401 (token expired).
  /// Re-authenticates silently and reconstructs the DriveApi client.
  Future<T> _withRetryOn401<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AccessDeniedException catch (_) {
      debugPrint('[Sync] 401 — attempting token refresh...');
      try {
        if (kIsWeb) {
          await _webAuthorize(silent: true);
        } else {
          // attemptLightweightAuthentication is non-interactive on all platforms
          final maybeFuture = _googleSignIn.attemptLightweightAuthentication();
          final account = maybeFuture != null ? await maybeFuture : null;
          if (account != null) {
            await _obtainDriveClientFrom(account, silent: true);
          }
        }
        return await action();
      } catch (retryError) {
        debugPrint('[Sync] Token refresh failed: $retryError');
        rethrow;
      }
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
