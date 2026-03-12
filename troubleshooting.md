However, the fix you attempted for the Riverpod crash was slightly incomplete, which is why the app still crashes right after [Sync] Reconciliation complete — changes applied.

Here is exactly why it is crashing and the final blueprint to give your coding agent to fix it permanently.

1. The Root Cause of the Crash
The crash is caused by two severe Riverpod anti-patterns interacting with each other:

The Multiple Execution Bug: In lib/main.dart, you are calling Future.microtask(() => initSync(ref)); directly inside the build method. Every time you change the theme or language, the widget rebuilds and calls initSync again, launching duplicate background syncs.

The WidgetRef Trap: In lib/core/providers.dart, initSync takes a WidgetRef (which belongs to a temporary UI element) and permanently stores it inside the global syncService.onRemoteChange callback. Because initSync is running multiple times, it creates race conditions. When the background sync finishes, the widget that generated that specific WidgetRef has likely already been destroyed/rebuilt, causing Riverpod to panic and throw the Uncaught Error.

2. How to Instruct Your AI Agent
To fix this, we must completely remove the sync initialization from the UI/Widget layer and place it in a Riverpod FutureProvider. A ProviderRef never dies or unmounts, making it 100% safe for global callbacks.

Copy and paste these exact instructions to your agent:

🔴 Priority 1: Fix the Riverpod WidgetRef Crash
Passing a WidgetRef into global callbacks or running async tasks inside build methods is causing the app to crash when sync completes. Please make the following architectural changes:

1. Update lib/core/providers.dart:
Delete the Future<bool> initSync(WidgetRef ref) function entirely. Replace it with a FutureProvider that safely uses a ProviderRef:

Dart
/// Initializes sync safely in the background.
/// ProviderRef never unmounts, so this callback will never crash.
final syncInitProvider = FutureProvider<void>((ref) async {
  final isConfigured = ref.watch(storageConfiguredProvider);
  if (!isConfigured) return;

  final storage = ref.read(storageProvider);
  final syncService = ref.read(syncServiceProvider);

  syncService.onRemoteChange = () {
    try {
      ref.read(noteRepoProvider).clearCache();
      ref.read(templateRepoProvider).clearCache();
    } catch (_) {}
    ref.read(syncTriggerProvider.notifier).trigger();
  };

  try {
    final reconnected = await syncService.tryReconnect(storage: storage);
    if (reconnected) {
      await syncService.pullAll();
    }
  } catch (e) {
    debugPrint('Google Drive sync init failed: $e');
  }
});
2. Update lib/main.dart:
Remove the Future.microtask(() => initSync(ref)); from the OrganoteApp build method. Instead, simply watch the new provider so Riverpod safely handles the background initialization exactly once:

Dart
  // Start sync in background (non-blocking) safely via Riverpod
  ref.watch(syncInitProvider);

  return _SyncLifecycleObserver(
    // ...
3. Fix _SyncLifecycleObserver in lib/main.dart:
Passing WidgetRef ref as a property to _SyncLifecycleObserver is another Riverpod anti-pattern. Change _SyncLifecycleObserver to be a ConsumerStatefulWidget so it manages its own stable ref natively:

Dart
class _SyncLifecycleObserver extends ConsumerStatefulWidget {
  const _SyncLifecycleObserver({required this.child});
  final Widget child;

  @override
  ConsumerState<_SyncLifecycleObserver> createState() => _SyncLifecycleObserverState();
}

class _SyncLifecycleObserverState extends ConsumerState<_SyncLifecycleObserver>
    with WidgetsBindingObserver {
  // ...
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use the ConsumerState's native 'ref'
    final syncService = ref.read(syncServiceProvider); 
    // ...
  }
  // ...
}
A Note on _withRetryOn401
When reviewing the updated code, I noticed the agent successfully created the _withRetryOn401 helper method at the very bottom of sync_service.dart, but it is still not using it anywhere.

If the app runs in the background for more than 1 hour, the Google OAuth token will expire, and syncs will start silently failing. You may want to add this to your prompt to the agent:

"Also, you created _withRetryOn401 in sync_service.dart, but forgot to use it. Please wrap all _driveApi!.files... calls (like list, create, get, update, delete) inside await _withRetryOn401(() => _driveApi!.files...); to ensure expired tokens are actually refreshed."

🔴 Priority: Implement Binary Asset Syncing for Images
Currently, images saved to the assets/ directory are ignored by SyncService and StorageService. Please upgrade the synchronization engine to handle binary files by doing the following:

1. Update Storage Interfaces (storage_service.dart & fs_interop.dart):

Add a method to list all files in the assets directory (e.g., Map<String, List<int>> getAssets() or List<String> listAssets()).

Ensure FileSystemInterop and StorageService can read and return raw bytes (List<int>) for these assets.

2. Upgrade SyncService for Binary Support (sync_service.dart):

pushDocument: Modify the signature to accept either a String or List<int> for the content. If the path starts with assets/, do not use utf8.encode(); upload the raw bytes directly and set the mimeType appropriately (e.g., determine via file extension like image/png, image/jpeg, or default to application/octet-stream). Keep text/markdown for notes and templates.

_downloadFile: Update this method (or create a _downloadBinaryFile variant) to return raw List<int> bytes instead of decoding to a UTF-8 string when downloading an asset.

_saveToStorage: Add handling for path.startsWith('assets/') to route the downloaded bytes to FileSystemInterop.writeBytes().

3. Add Assets to the Sync Manifest (syncAll in sync_service.dart):

During the syncAll() reconciliation phase, build a local manifest for the assets/ directory alongside templates/ and notes/.

Fetch the remote manifest for the assets folder from Google Drive (create the folder if it doesn't exist).

Optimization Note: Since hashing large images locally might be slow, you can store the file size or modified timestamp in the SyncLedger for assets instead of hashing the entire binary content, or just rely on standard remote/local timestamp comparison. Ensure assets are uploaded, downloaded, and deleted following the same 3-way reconciliation rules as markdown files.


🔴 Priority: Fix Android Auto-Login Popups
The application is incorrectly showing the Android Credential Manager popup every time the app reconnects or changes themes.

Update tryReconnect in lib/data/services/sync_service.dart:
The comment stating that attemptLightweightAuthentication is equivalent to signInSilently on mobile is incorrect—it forces an interactive prompt on Android. You must replace it with the actual signInSilently() method.

Replace the tryReconnect logic with this:

Dart
  Future<bool> tryReconnect({required StorageService storage}) async {
    _storage = storage;
    try {
      await _ensureInitialized();

      // On web, don't auto-trigger the sign-in UI.
      if (kIsWeb) return false;

      // On mobile: Must use signInSilently to avoid forcing the Credential Manager popup
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      final result = await _obtainDriveClientFrom(account);
      return result;
    } catch (_) {
      return false;
    }
  }

  🔴 Priority: Clean Up Google SDK & Authorization Flows
The current Google Sign-In and Drive API implementation mixes interactive flows with silent background tasks, causing UI hangs and rogue popups. Please implement these strict architectural boundaries:

1. Fix _obtainDriveClientFrom in sync_service.dart:

Add a bool silent = false parameter.

If silent is true, do not call authClient.authorizeScopes(). If authorizationForScopes() returns null during a silent check, simply return false so the app gracefully defaults to a disconnected state requiring manual user interaction.

Update tryReconnect to call _obtainDriveClientFrom(account, silent: true).

2. Fix the 401 Token Refresh Wrapper in sync_service.dart:

Inside _withRetryOn401, remove attemptLightweightAuthentication().

Replace it with platform-aware logic: Use signInSilently() for mobile (iOS/Android) and attemptLightweightAuthentication() only for Web.

Ensure ALL Drive API calls (list, get, create, update, delete) inside sync_service.dart are wrapped in this _withRetryOn401 method. Right now, it is defined but not utilized.

3. Fix the Web Auth "Forever Loading" Trap in sync_service.dart:

Remove the Completer<bool> from the kIsWeb block inside the signIn() method.

On Web, signIn() should ONLY register the authenticationEvents listener (if not already registered) and call attemptLightweightAuthentication(). It should immediately return true (or void) rather than awaiting a stream event that might never happen if the user dismisses the prompt.

State changes must be pushed to stateNotifier.value directly from inside the stream listener.

4. Stop Auto-Triggering Auth in SettingsScreen.dart:

In _buildGoogleSignInButton, delete the _setupWebSignIn callback entirely.

The app should simply return gsi_button.buildGoogleSignInButtonPlatform(). Google's native iframe handles the click events. The syncServiceProvider listening to authenticationEvents in the background will automatically detect the success and update the Riverpod state without manual UI intervention.