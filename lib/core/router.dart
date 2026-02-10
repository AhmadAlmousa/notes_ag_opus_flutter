import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/templates/template_list_screen.dart';
import '../presentation/screens/templates/template_builder_screen.dart';
import '../presentation/screens/notes/notes_list_screen.dart';
import '../presentation/screens/notes/note_view_screen.dart';
import '../presentation/screens/editor/note_editor_screen.dart';
import '../presentation/screens/editor/markdown_editor_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

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
      // Dashboard
      GoRoute(
        path: '/',
        name: 'dashboard',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const DashboardScreen(),
        ),
      ),

      // Templates
      GoRoute(
        path: '/templates',
        name: 'templates',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const TemplateListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'template-new',
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              const TemplateBuilderScreen(),
            ),
          ),
          GoRoute(
            path: ':templateId',
            name: 'template-edit',
            pageBuilder: (context, state) => _buildPage(
              context,
              state,
              TemplateBuilderScreen(
                templateId: state.pathParameters['templateId'],
              ),
            ),
          ),
        ],
      ),

      // Notes
      GoRoute(
        path: '/notes',
        name: 'notes',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          NotesListScreen(
            category: state.uri.queryParameters['category'],
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
                pageBuilder: (context, state) => _buildPage(
                  context,
                  state,
                  MarkdownEditorScreen(
                    category: state.pathParameters['category']!,
                    filename: state.pathParameters['filename']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // Create new note
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

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPage(
          context,
          state,
          const SettingsScreen(),
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

  /// Builds a custom page with animations.
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
}
