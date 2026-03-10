import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry in the sync ledger tracking a synced file's state.
class SyncEntry {
  /// MD5 hash of the local file content at last sync.
  final String localHash;

  /// Remote Drive modifiedTime at last sync.
  final DateTime? remoteModifiedTime;

  /// Timestamp of last successful sync.
  final DateTime syncedAt;

  SyncEntry({
    required this.localHash,
    this.remoteModifiedTime,
    required this.syncedAt,
  });

  Map<String, dynamic> toJson() => {
        'localHash': localHash,
        'remoteModifiedTime': remoteModifiedTime?.toIso8601String(),
        'syncedAt': syncedAt.toIso8601String(),
      };

  factory SyncEntry.fromJson(Map<String, dynamic> json) => SyncEntry(
        localHash: json['localHash'] as String,
        remoteModifiedTime: json['remoteModifiedTime'] != null
            ? DateTime.tryParse(json['remoteModifiedTime'] as String)
            : null,
        syncedAt: DateTime.parse(json['syncedAt'] as String),
      );
}

/// Tracks the last known synced state of all files for 3-way reconciliation.
///
/// Stored in SharedPreferences as a small metadata map (path → hash + timestamps).
/// This is NOT file content — just ~100 bytes per entry.
class SyncLedger {
  static const _ledgerKey = 'organote_sync_ledger';

  SharedPreferences? _prefs;
  Map<String, SyncEntry> _entries = {};

  /// Initialize from SharedPreferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    final json = _prefs?.getString(_ledgerKey);
    if (json == null) {
      _entries = {};
      return;
    }
    try {
      final raw = jsonDecode(json) as Map<String, dynamic>;
      _entries = raw.map((k, v) =>
          MapEntry(k, SyncEntry.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      _entries = {};
    }
  }

  Future<void> _save() async {
    final raw = _entries.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs?.setString(_ledgerKey, jsonEncode(raw));
  }

  /// Get all ledger entries.
  Map<String, SyncEntry> get entries => Map.unmodifiable(_entries);

  /// Get a specific entry.
  SyncEntry? getEntry(String path) => _entries[path];

  /// Set/update an entry after a successful sync.
  Future<void> setEntry(String path, SyncEntry entry) async {
    _entries[path] = entry;
    await _save();
  }

  /// Remove an entry (file was deleted from both sides).
  Future<void> removeEntry(String path) async {
    _entries.remove(path);
    await _save();
  }

  /// Clear the entire ledger (e.g. on sign-out).
  Future<void> clear() async {
    _entries.clear();
    await _prefs?.remove(_ledgerKey);
  }

  /// Compute MD5 hash of content for comparison.
  static String hashContent(String content) {
    return md5.convert(utf8.encode(content)).toString();
  }
}
