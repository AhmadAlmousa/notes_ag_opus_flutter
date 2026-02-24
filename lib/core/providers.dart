import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/note_repository.dart';
import '../data/repositories/template_repository.dart';
import '../data/services/storage_service.dart';
import '../data/services/file_system_storage_service.dart';
import '../data/services/fs_interop.dart';
import '../data/services/sync_service.dart';

/// Result of app initialization — contains resolved services.
class AppInit {
  const AppInit({
    required this.storage,
    required this.noteRepository,
    required this.templateRepository,
    required this.storageConfigured,
    required this.themeMode,
  });

  final StorageService storage;
  final NoteRepository noteRepository;
  final TemplateRepository templateRepository;
  final bool storageConfigured;
  final ThemeMode themeMode;
}

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

/// Performs first-run initialization (reconnect storage, load prefs, seed data).
final appInitProvider = FutureProvider<AppInit>((ref) async {
  StorageService storage;
  bool storageConfigured = false;

  final reconnected = await FileSystemStorageService.tryReconnect();

  if (reconnected) {
    final fsStorage = await FileSystemStorageService.getInstance();
    await fsStorage.refreshCaches();
    storage = fsStorage;
    storageConfigured = true;
  } else {
    final configType = FileSystemStorageService.configuredStorageType;
    if (configType == 'local') {
      storage = await StorageService.getInstance();
      storageConfigured = true;
    } else if (configType != 'none') {
      storage = await StorageService.getInstance();
      storageConfigured = true;
    } else {
      storage = await StorageService.getInstance();
      storageConfigured = false;
    }
  }

  final templateRepo = TemplateRepository(storage);
  final noteRepo = NoteRepository(storage);

  // Seed sample data if empty
  if (templateRepo.getAll().isEmpty) {
    await _seedSampleData(storage, templateRepo, noteRepo);
  }

  // Load theme preference
  final themePref = storage.getSetting<String>('themeMode');
  final themeMode = themePref != null
      ? ThemeMode.values.firstWhere(
          (m) => m.name == themePref,
          orElse: () => ThemeMode.system,
        )
      : ThemeMode.system;

  return AppInit(
    storage: storage,
    noteRepository: noteRepo,
    templateRepository: templateRepo,
    storageConfigured: storageConfigured,
    themeMode: themeMode,
  );
});

// ---------------------------------------------------------------------------
// Derived providers — only valid after appInit completes
// ---------------------------------------------------------------------------

/// Whether the user has completed initial storage setup.
final storageConfiguredProvider = Provider<bool>((ref) {
  final init = ref.watch(appInitProvider);
  return init.whenData((v) => v.storageConfigured).value ?? false;
});

/// Note repository.
final noteRepoProvider = Provider<NoteRepository>((ref) {
  final init = ref.watch(appInitProvider);
  return init.requireValue.noteRepository;
});

/// Template repository.
final templateRepoProvider = Provider<TemplateRepository>((ref) {
  final init = ref.watch(appInitProvider);
  return init.requireValue.templateRepository;
});

/// Active storage service.
final storageProvider = Provider<StorageService>((ref) {
  final init = ref.watch(appInitProvider);
  return init.requireValue.storage;
});

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final init = ref.watch(appInitProvider);
    final data = init.requireValue;
    // Load saved preference
    final themePref = data.storage.getSetting<String>('themeMode');
    return themePref != null
        ? ThemeMode.values.firstWhere(
            (m) => m.name == themePref,
            orElse: () => ThemeMode.system,
          )
        : data.themeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final init = ref.read(appInitProvider);
    await init.requireValue.storage.setSetting('themeMode', mode.name);
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ---------------------------------------------------------------------------
// Storage info (read-only)
// ---------------------------------------------------------------------------

final storageTypeProvider = Provider<String>((ref) {
  return FileSystemInterop.currentStorageType;
});

final storageDirectoryNameProvider = Provider<String?>((ref) {
  return FileSystemInterop.directoryName;
});

// ---------------------------------------------------------------------------
// Sync
// ---------------------------------------------------------------------------

/// The SyncService singleton.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

/// Incremented on each remote change — screens watch this to rebuild.
final syncTriggerProvider = NotifierProvider<SyncTriggerNotifier, int>(
  SyncTriggerNotifier.new,
);

class SyncTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

/// Whether sync is currently connected.
final syncStatusProvider = NotifierProvider<SyncStatusNotifier, bool>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setConnected(bool value) => state = value;
}

/// Initialize Supabase sync from saved credentials.
/// Returns true if sync was started successfully.
Future<bool> initSync(WidgetRef ref) async {
  final storage = ref.read(storageProvider);
  final useEnv = storage.getSetting<bool>('sync_use_env') ?? false;

  String? url;
  String? key;

  if (useEnv) {
    // Read from compile-time env (--dart-define)
    url = const String.fromEnvironment('SUPABASE_URL');
    key = const String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty) url = null;
    if (key != null && key.isEmpty) key = null;
  } else {
    url = storage.getSetting<String>('sync_supabase_url');
    key = storage.getSetting<String>('sync_supabase_key');
  }

  if (url == null || key == null || url.isEmpty || key.isEmpty) {
    return false;
  }

  try {
    final syncService = ref.read(syncServiceProvider);
    await syncService.init(
      supabaseUrl: url,
      supabaseAnonKey: key,
      storage: storage,
    );

    // Wire up remote change callback
    syncService.onRemoteChange = () {
      // Clear repo caches so fresh data is loaded
      try {
        ref.read(noteRepoProvider).clearCache();
        ref.read(templateRepoProvider).clearCache();
      } catch (_) {}
      // Trigger UI rebuild
      ref.read(syncTriggerProvider.notifier).trigger();
    };

    // Initial sync: pull remote data
    await syncService.pullAll();

    // Connect to Realtime
    await syncService.connect();

    ref.read(syncStatusProvider.notifier).setConnected(true);
    return true;
  } catch (e) {
    debugPrint('Sync init failed: $e');
    return false;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Complete storage setup and refresh providers.
Future<void> completeStorageSetup(WidgetRef ref, String storageType) async {
  await FileSystemStorageService.setConfigured(storageType);

  StorageService storage;
  if (storageType == 'fsa' || storageType == 'opfs') {
    final fsStorage = await FileSystemStorageService.getInstance();
    await fsStorage.refreshCaches();
    storage = fsStorage;
  } else {
    await FileSystemStorageService.setConfigured('local');
    storage = await StorageService.getInstance();
  }

  final templateRepo = TemplateRepository(storage);
  final noteRepo = NoteRepository(storage);

  // Seed sample data
  if (templateRepo.getAll().isEmpty) {
    await _seedSampleData(storage, templateRepo, noteRepo);
  }

  // Invalidate to trigger rebuild with new storage
  ref.invalidate(appInitProvider);
}

/// Seeds sample data for demonstration.
Future<void> _seedSampleData(
  StorageService storage,
  TemplateRepository templateRepo,
  NoteRepository noteRepo,
) async {
  const sampleTemplateContent = '''---
template_id: family_login
name: Family Login
version: 1
layout: cards
default_folder: personal
---

\`\`\`schema
display:
  preset: credentials
  primary: service
fields:
  - id: owner
    type: dropdown
    label: Owner
    required: true
    options:
      - Dad
      - Mom
      - Kids
  - id: service
    type: text
    label: Service
    required: true
  - id: username
    type: text
    label: Username
    required: true
  - id: password
    type: password
    label: Password
    required: true
  - id: created_on
    type: date
    label: Created On
    calendar: dual
actions:
  - label: Copy Password
    field: password
    type: copy
\`\`\`
''';

  await storage.saveTemplate('family_login', sampleTemplateContent);

  const sampleNoteContent = '''---
template_id: family_login
template_version: 1
id: gmail_accounts
tags:
  - email
  - google
---

\`\`\`data
- owner: Dad
  service: Gmail
  username: dad@gmail.com
  password: MySecurePass123
  created_on: 2024-01-15|gregorian
- owner: Mom
  service: Gmail
  username: mom@gmail.com
  password: AnotherPass456
  created_on: 1445-06-21|hijri
\`\`\`
''';

  await storage.saveNote('personal', 'gmail_accounts.md', sampleNoteContent);

  // Clear cache to pick up new data
  templateRepo.clearCache();
  noteRepo.clearCache();
}
