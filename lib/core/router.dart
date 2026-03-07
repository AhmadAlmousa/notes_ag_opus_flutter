import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Eager imports — needed at/near startup
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/notes/notes_list_screen.dart';
import '../presentation/screens/notes/note_view_screen.dart';
import '../presentation/screens/editor/note_editor_screen.dart';
import '../presentation/widgets/layout/app_scaffold.dart';

// Deferred imports — loaded only when user navigates to these screens
import '../presentation/screens/templates/template_list_screen.dart'
    deferred as templates;
import '../presentation/screens/templates/template_builder_screen.dart'
    deferred as templateBuilder;
import '../presentation/screens/editor/markdown_editor_screen.dart'
    deferred as markdownEditor;
import '../presentation/screens/settings/settings_screen.dart'
    deferred as settings;
import '../presentation/screens/settings/recycle_bin_screen.dart'
    deferred as recycleBin;

/// App router configuration with go_router.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // Persistent shell for tab navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'dashboard',
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  const DashboardScreen(),
                ),
              ),
            ],
          ),
          // Branch 1: Templates
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/templates',
                name: 'templates',
                pageBuilder: (context, state) => _deferredNoTransitionPage(
                  state,
                  () => templates.loadLibrary(),
                  () => templates.TemplateListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'template-new',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildDeferredPage(
                      context,
                      state,
                      () => templateBuilder.loadLibrary(),
                      () => templateBuilder.TemplateBuilderScreen(),
                    ),
                  ),
                  GoRoute(
                    path: ':templateId',
                    name: 'template-edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildDeferredPage(
                      context,
                      state,
                      () => templateBuilder.loadLibrary(),
                      () => templateBuilder.TemplateBuilderScreen(
                        templateId: state.pathParameters['templateId'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) => _deferredNoTransitionPage(
                  state,
                  () => settings.loadLibrary(),
                  () => settings.SettingsScreen(),
                ),
              ),
              GoRoute(
                path: '/recycle-bin',
                name: 'recycleBin',
                pageBuilder: (context, state) => _buildDeferredPage(
                  context,
                  state,
                  () => recycleBin.loadLibrary(),
                  () => recycleBin.RecycleBinScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Notes (not in shell — full-screen navigation)
      GoRoute(
        path: '/notes',
        name: 'notes',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          NotesListScreen(
            category: state.uri.queryParameters['category'],
            tag: state.uri.queryParameters['tag'],
          ),
        ),
        routes: [
          GoRoute(
            path: ':category/:filename',
            name: 'note-view',
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              NoteViewScreen(
                category: state.pathParameters['category']!,
                filename: state.pathParameters['filename']!,
              ),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'note-edit',
                pageBuilder: (context, state) => _buildPage(
                  context,
                  state,
                  NoteEditorScreen(
                    category: state.pathParameters['category']!,
                    filename: state.pathParameters['filename']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'source',
                name: 'note-source',
                pageBuilder: (context, state) => _buildDeferredPage(
                  context,
                  state,
                  () => markdownEditor.loadLibrary(),
                  () => markdownEditor.MarkdownEditorScreen(
                    category: state.pathParameters['category']!,
                    filename: state.pathParameters['filename']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // Create new note (full-screen)
      GoRoute(
        path: '/new-note/:templateId',
        name: 'new-note',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          NoteEditorScreen(
            templateId: state.pathParameters['templateId']!,
            category: state.uri.queryParameters['category'],
          ),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => _buildPage(
      context,
      state,
      Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// No-transition page for tab content (instant swap, no animation).
  static NoTransitionPage<void> _noTransitionPage(
    GoRouterState state,
    Widget child,
  ) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: child,
    );
  }

  /// Deferred no-transition page for tab content.
  static NoTransitionPage<void> _deferredNoTransitionPage(
    GoRouterState state,
    Future<void> Function() loadLibrary,
    Widget Function() buildWidget,
  ) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: FutureBuilder(
        future: loadLibrary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48,
                          color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Failed to load page',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Go Home'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return buildWidget();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  /// Builds a custom page with animations (for non-shell routes).
  static CustomTransitionPage<void> _buildPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Builds a page with deferred loading.
  static CustomTransitionPage<void> _buildDeferredPage(
    BuildContext context,
    GoRouterState state,
    Future<void> Function() loadLibrary,
    Widget Function() buildWidget,
  ) {
    return _buildPage(
      context,
      state,
      FutureBuilder(
        future: loadLibrary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48,
                          color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Failed to load page',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Go Home'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return buildWidget();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
