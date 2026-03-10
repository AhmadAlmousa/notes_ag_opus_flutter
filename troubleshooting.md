

---

### 🔴 Priority 1: Critical Sync Architecture & Data Integrity (Fix Immediately)

The current sync implementation is additive-only, blind to the recycle bin, and relies on a brute-force approach. To prevent data loss, eliminate "zombie files," and ensure a perfect cross-device mirror, implement the following changes to `sync_service.dart`:

1. **Implement True Bidirectional Mirroring (The Sync Ledger):** * Create a local "Sync Ledger" (a hidden file or local database table) that tracks the last known state and `modifiedTime` of all successfully synced files.
* During `syncAll()`, execute a 3-way reconciliation algorithm comparing Local Files, Remote Drive Files, and the Sync Ledger to accurately detect additions, modifications, and deletions (tombstones).
* Do not blindly overwrite or skip missing files. If a file is in the ledger but missing locally, remove it from Google Drive. If it is in the ledger but missing remotely, delete it locally.


2. **Fix the Recycle Bin "Zombie File" Bug:** * **The Problem:** The `SyncService` ignores the `getTrash()` list. If a note is moved to the trash locally, `pullAll` immediately resurrects it by re-downloading the remote copy from Google Drive because the remote file was never explicitly deleted.
* **The Solution:** Stop storing Markdown trash payloads in `SharedPreferences`. Implement the Recycle Bin as an actual hidden `.trash/` folder locally. During the `syncAll` 3-way reconciliation, if a local file is moved to `.trash/`, the Sync Ledger must register this as a deletion. The app must then use the Drive API to update the file's remote status by executing `driveApi.files.update(fileId, drive.File()..trashed = true)`. This natively moves the file to the user's Google Drive trash bin.


3. **Implement Timestamp Delta Sync:** Stop iterating through the entire database with a basic `if (existing != content)` check. Compare the local file's `updatedAt` timestamp against the Google Drive `modifiedTime`. Only download if the remote file is newer; only upload if the local file is newer.
4. **Implement Drive API Pagination (`nextPageToken`):** The `_listFiles` and `_listFolders` methods currently max out at 100 items by default. Wrap all Drive API `list` calls in a `do-while` loop handling `nextPageToken` until it returns null to prevent silent data loss for larger vaults.
5. **Handle OAuth Token Expiration (401 Errors):** The `_driveApi` instance is currently held indefinitely after login, but Google tokens expire after 1 hour, causing background syncs to fail silently. Implement a retry mechanism: if a 401 error occurs, fetch a fresh token via `signInSilently()` and reconstruct the `DriveApi` client before retrying the request.
6. **Replace 5-Minute Polling with App Lifecycle Hooks:** Remove the `Timer.periodic` polling. Implement Flutter's `WidgetsBindingObserver` to trigger a sync when `AppLifecycleState` switches to `resumed` (pull) or `paused` (push).

---

### 🔴 Priority 2: Authentication & Cross-Platform UX Bugs

The Google Sign-In flow suffers from architectural misplacements that cause erratic popups and fractured states.

1. **Remove UI-Coupled Auth Side Effects (The Theme Bug):** In `SettingsScreen`, the `_setupWebSignIn` logic is triggered directly inside the `build()` method (`_webSignInFuture ??= _setupWebSignIn(...)`). Changing the theme rebuilds the widget tree and blindly re-triggers the auth flow. Move all auth initiation to `initState()` or a dedicated Riverpod controller.
2. **Fix Mobile Auto-Login Popups:** Update `tryReconnect` in `sync_service.dart`. Do not use `attemptLightweightAuthentication()` for mobile. Use `await _googleSignIn.signInSilently()` for iOS and Android to restore sessions without forcing an interactive popup on every launch.
3. **Fix Cross-Platform Client ID Configuration:** Ensure `_googleSignIn.initialize()` conditionally applies the `clientId` ONLY for `kIsWeb` and `Platform.isIOS`. Provide `null` for Android so it properly reads from `google-services.json`.
4. **Remove Web Auth 120-Second Time Bomb:** Remove the strict `.timeout(const Duration(seconds: 120))` on the web login `Completer`. Rely on the `google_sign_in_web` streams to definitively report success or failure without artificial race conditions.

---

### 🟡 Priority 3: State Management & Scalability

These updates will future-proof the app's performance and code maintainability as user data grows.

1. **Refactor `SyncService` to a Riverpod `AsyncNotifier`:** Eliminate the Singleton pattern (`SyncService.instance`). Implement `SyncService` as a Riverpod `AsyncNotifierProvider` that yields granular states (e.g., `disconnected`, `syncing`, `connected`, `error`). Remove manual `setState(() {})` calls from `SettingsScreen` and strictly use `ref.watch()`.
2. **Graceful Permission Handling:** If a user logs in but unchecks the Google Drive permission box, `authorizationForScopes` will fail. Update the state to reflect an "Insufficient Permissions" error and trigger a UI prompt asking the user to re-authenticate and grant Drive access.
3. **Stop Abusing `SharedPreferences` for File Storage:** `StorageService` currently serializes the entire database into JSON strings (`_prefs?.setString(...)`). This violates web limits and causes mobile memory jank. Strip `SharedPreferences` down to basic settings (theme, defaults). Rely strictly on `dart:io` and OPFS for markdown file content, and implement `sqflite`/`drift` for the search indexing layer.
4. **Batch API Requests:** Process `pushAll` and `pullAll` uploads/downloads concurrently using `Future.wait()`, batched in groups of 5-10, to dramatically speed up sync times and respect rate limits. Transition to Google Drive's `changes.list` API endpoint instead of scanning all folders manually.

---