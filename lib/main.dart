import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/fs_interop.dart';
import 'presentation/screens/setup/setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrganoteApp());
}

/// Main application widget.
class OrganoteApp extends StatefulWidget {
  const OrganoteApp({super.key});

  @override
  State<OrganoteApp> createState() => _OrganoteAppState();
}

class _OrganoteAppState extends State<OrganoteApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = AppState.instance.initialize();
    AppState.instance.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const _SplashScreen(),
          );
        }

        // Show setup screen if storage not yet configured
        if (!AppState.instance.storageConfigured) {
          return MaterialApp(
            title: 'Organote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: AppState.instance.themeMode,
            home: SetupScreen(
              onComplete: () async {
                // Determine which storage was configured
                final storageType = FileSystemInterop.currentStorageType;
                await AppState.instance.completeStorageSetup(
                  storageType == 'none' ? 'local' : storageType,
                );
                if (mounted) setState(() {});
              },
            ),
          );
        }

        return MaterialApp.router(
          title: 'Organote',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppState.instance.themeMode,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}

/// Splash screen shown during initialization.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
