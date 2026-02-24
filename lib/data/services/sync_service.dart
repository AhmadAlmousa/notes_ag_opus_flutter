import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';
import '../../core/utils/markdown_parser.dart';

/// Callback type for notifying the UI about remote changes.
typedef OnRemoteChange = void Function();

/// Sync service that pushes local changes to Supabase and listens
/// for remote changes via Realtime WebSockets.
///
/// Conflict resolution: Last Write Wins (based on `updated_at`).
class SyncService {
  SyncService._();

  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SupabaseClient? _client;
  RealtimeChannel? _channel;
  StorageService? _storage;
  String _deviceId = '';
  bool _initialized = false;
  bool _connected = false;

  /// Callback invoked when a remote change is received and applied locally.
  OnRemoteChange? onRemoteChange;

  /// Whether the sync service is currently connected to Supabase.
  bool get isConnected => _connected;

  /// Whether the sync service has been initialized.
  bool get isInitialized => _initialized;

  /// The device ID used for this session.
  String get deviceId => _deviceId;

  /// Initialize the Supabase client and generate a device ID.
  Future<void> init({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required StorageService storage,
  }) async {
    if (_initialized) return;

    _storage = storage;
    _deviceId = _generateDeviceId();

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _client = Supabase.instance.client;
    _initialized = true;
  }

  /// Connect and start listening for remote changes.
  Future<void> connect() async {
    if (!_initialized || _client == null) return;
    if (_connected) return;

    // Subscribe to Realtime changes on the documents table
    _channel = _client!.channel('documents-sync');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'documents',
          callback: _onPostgresChange,
        )
        .subscribe((status, [error]) {
      _connected = status == RealtimeSubscribeStatus.subscribed;
    });
  }

  /// Disconnect from Realtime.
  void disconnect() {
    _channel?.unsubscribe();
    _channel = null;
    _connected = false;
  }

  /// Full sync: pull all remote docs and overwrite local.
  Future<void> pullAll() async {
    if (_client == null || _storage == null) return;

    try {
      final response = await _client!
          .from('documents')
          .select()
          .eq('deleted', false)
          .order('updated_at', ascending: false);

      for (final row in response) {
        final id = row['id'] as String;
        final content = row['content'] as String;

        _applyRemoteDocument(id, content);
      }
    } catch (e) {
      // Silently fail — offline is fine
    }
  }

  /// Push a single document to Supabase.
  Future<void> pushDocument(String id, String content) async {
    if (_client == null) return;

    try {
      await _client!.from('documents').upsert({
        'id': id,
        'content': content,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'device_id': _deviceId,
        'deleted': false,
      });
    } catch (e) {
      // Silently fail — will sync on next push
    }
  }

  /// Push a deletion to Supabase (soft-delete).
  Future<void> pushDeletion(String id) async {
    if (_client == null) return;

    try {
      await _client!.from('documents').upsert({
        'id': id,
        'content': '',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'device_id': _deviceId,
        'deleted': true,
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Push all local notes and templates to Supabase (full upload).
  Future<void> pushAll() async {
    if (_client == null || _storage == null) return;

    try {
      // Push notes
      final notes = _storage!.getNotes();
      for (final entry in notes.entries) {
        await pushDocument('notes/${entry.key}', entry.value);
      }

      // Push templates
      final templates = _storage!.getTemplates();
      for (final entry in templates.entries) {
        await pushDocument('templates/${entry.key}', entry.value);
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Handle incoming Postgres change events.
  void _onPostgresChange(PostgresChangePayload payload) {
    if (_storage == null) return;

    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;

    final remoteDeviceId = newRecord['device_id'] as String? ?? '';

    // Ignore changes from this device
    if (remoteDeviceId == _deviceId) return;

    final id = newRecord['id'] as String? ?? '';
    final content = newRecord['content'] as String? ?? '';
    final deleted = newRecord['deleted'] as bool? ?? false;

    if (id.isEmpty) return;

    if (deleted) {
      _applyRemoteDeletion(id);
    } else {
      _applyRemoteDocument(id, content);
    }

    // Notify UI to refresh
    onRemoteChange?.call();
  }

  /// Apply a remote document to local storage.
  void _applyRemoteDocument(String id, String content) {
    if (_storage == null || content.isEmpty) return;

    if (id.startsWith('notes/')) {
      final path = id.substring('notes/'.length);
      final parts = path.split('/');
      if (parts.length >= 2) {
        final category = parts[0];
        final filename = parts.sublist(1).join('/');
        _storage!.saveNote(category, filename, content);
      }
    } else if (id.startsWith('templates/')) {
      final templateId = id.substring('templates/'.length);
      _storage!.saveTemplate(templateId, content);
    }
  }

  /// Apply a remote deletion to local storage.
  void _applyRemoteDeletion(String id) {
    if (_storage == null) return;

    if (id.startsWith('notes/')) {
      final path = id.substring('notes/'.length);
      final parts = path.split('/');
      if (parts.length >= 2) {
        final category = parts[0];
        final filename = parts.sublist(1).join('/');
        _storage!.deleteNote(category, filename);
      }
    } else if (id.startsWith('templates/')) {
      final templateId = id.substring('templates/'.length);
      _storage!.deleteTemplate(templateId);
    }
  }

  /// Generate a short random device ID for this session.
  String _generateDeviceId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Dispose and clean up.
  void dispose() {
    disconnect();
    _instance = null;
    _initialized = false;
  }
}
