import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/file_system_storage_service.dart';
import 'data/services/fs_interop.dart';
import 'l10n/app_localizations.dart';
import 'presentation/screens/setup/restore_access_screen.dart';
import 'presentation/screens/setup/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Dart Error: $error\n$stack');
    // Prevents app from crashing entirely (white screen) in release mode
    return true; 
  };

  runApp(const ProviderScope(child: OrganoteApp()));
}

/// Localization delegates shared across all MaterialApp instances.
const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const _supportedLocales = [
  Locale('en'),
  Locale('ar'),
];

/// Main application widget.
class OrganoteApp extends ConsumerWidget {
  const OrganoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(appInitProvider);

    return initAsync.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: _supportedLocales,
        home: const _SplashScreen(),
      ),
      error: (error, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: _supportedLocales,
        home: Scaffold(
          body: Center(child: Text('Initialization error: $error')),
        ),
      ),
      data: (init) {
        // Show setup screen if storage not yet configured
        if (!init.storageConfigured) {
          return MaterialApp(
            title: 'Organote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: init.themeMode,
            localizationsDelegates: _localizationsDelegates,
            supportedLocales: _supportedLocales,
            home: SetupScreen(
              onComplete: () async {
                final storageType = FileSystemInterop.currentStorageType;
                await completeStorageSetup(
                  ref,
                  storageType == 'none' ? 'local' : storageType,
                );
              },
            ),
          );
        }

        // Show restore screen if FSA needs user gesture to re-grant permission
        if (FileSystemStorageService.needsUserActivation) {
          return MaterialApp(
            title: 'Organote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: init.themeMode,
            localizationsDelegates: _localizationsDelegates,
            supportedLocales: _supportedLocales,
            home: RestoreAccessScreen(
              onRestored: () {
                ref.invalidate(appInitProvider);
              },
            ),
          );
        }

        final themeMode = ref.watch(themeModeProvider);
        final isOled = ref.watch(isOledModeProvider);
        final locale = ref.watch(localeProvider);

        // Start sync in background safely via Riverpod (never re-fires on rebuild)
        ref.watch(syncInitProvider);

        return _SyncLifecycleObserver(
          child: MaterialApp.router(
            title: 'Organote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: isOled ? AppTheme.oledTheme : AppTheme.darkTheme,
            themeMode: themeMode,
            locale: locale,
            localizationsDelegates: _localizationsDelegates,
            supportedLocales: _supportedLocales,
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}

/// P1.6: Lifecycle observer that triggers sync on app foreground/background.
/// Uses ConsumerStatefulWidget for a stable ref that never unmounts.
class _SyncLifecycleObserver extends ConsumerStatefulWidget {
  const _SyncLifecycleObserver({required this.child});
  final Widget child;

  @override
  ConsumerState<_SyncLifecycleObserver> createState() =>
      _SyncLifecycleObserverState();
}

class _SyncLifecycleObserverState extends ConsumerState<_SyncLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final syncService = ref.read(syncServiceProvider);
    if (!syncService.isConnected) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint('[Lifecycle] App resumed → pulling remote changes');
      syncService.pullAll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint('[Lifecycle] App pausing → pushing local changes');
      syncService.pushAll();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Splash screen shown during initialization with real progress steps.
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  static const _stepOrder = [
    'Starting...',
    'Connecting storage...',
    'Loading templates...',
    'Seeding sample data...',
    'Applying preferences...',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentStep = ref.watch(initProgressProvider);
    final stepIndex = _stepOrder.indexOf(currentStep).clamp(0, _stepOrder.length - 1);
    final progress = (stepIndex + 1) / _stepOrder.length;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.note_alt_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Organote',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Progress bar
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: AppTheme.primaryColor,
                          minHeight: 4,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      currentStep,
                      key: ValueKey(currentStep),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
