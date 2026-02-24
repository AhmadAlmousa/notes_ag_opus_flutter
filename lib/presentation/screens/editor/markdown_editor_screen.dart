import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note.dart';

/// Save state for markdown editor.
enum _MdSaveState { unsaved, saving, saved }

/// Markdown source editor with split-pane preview.
class MarkdownEditorScreen extends ConsumerStatefulWidget {
  const MarkdownEditorScreen({
    super.key,
    required this.category,
    required this.filename,
  });

  final String category;
  final String filename;

  @override
  ConsumerState<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends ConsumerState<MarkdownEditorScreen> {
  late TextEditingController _controller;
  Note? _note;
  String _originalContent = '';
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _showPreview = false;
  Timer? _autoSaveTimer;
  _MdSaveState _saveState = _MdSaveState.unsaved;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Final save on dispose if there are unsaved changes
    if (_hasChanges && _note != null && _controller.text != _originalContent) {
      _performSave();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _note = ref.read(noteRepoProvider).getNote(
      widget.category,
      widget.filename,
    );

    if (_note != null) {
      _originalContent = _note!.toMarkdown();
      _controller.text = _originalContent;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onTextChanged() {
    if (!_hasChanges && _controller.text != _originalContent) {
      setState(() {
        _hasChanges = true;
        _saveState = _MdSaveState.unsaved;
      });
    }
    // Restart 2-second auto-save debounce
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  /// Silently auto-saves without snackbar.
  Future<void> _autoSave() async {
    if (!mounted || _note == null) return;
    if (_controller.text == _originalContent) return;
    setState(() => _saveState = _MdSaveState.saving);
    await _performSave();
    if (mounted) setState(() => _saveState = _MdSaveState.saved);
  }

  /// Core save logic.
  Future<void> _performSave() async {
    if (_note == null) return;

    await ref.read(storageProvider).saveNote(
      widget.category,
      widget.filename,
      _controller.text,
    );

    // Clear cache so it gets reparsed
    ref.read(noteRepoProvider).clearCache();

    // Push to cloud
    ref.read(syncServiceProvider).pushDocument(
      'notes/${widget.category}/${widget.filename}',
      _controller.text,
    );

    setState(() {
      _originalContent = _controller.text;
      _hasChanges = false;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(theme),
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _autoSave(),
          },
          child: Focus(
            autofocus: true,
            child: isWide ? _buildSplitView(theme) : _buildMobileView(theme),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.code, size: 20),
          const SizedBox(width: 8),
          const Text('Source'),
          if (_saveState == _MdSaveState.saving) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
            Text('Saving...', style: TextStyle(
              fontSize: 12, color: theme.colorScheme.onSurfaceVariant,
            )),
          ] else if (_saveState == _MdSaveState.saved) ...[
            const SizedBox(width: 12),
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text('Saved', style: TextStyle(
              fontSize: 12, color: Colors.green.shade600,
            )),
          ] else if (_hasChanges) ...[
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Unsaved',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Preview toggle (mobile only)
        if (MediaQuery.of(context).size.width <= 800)
          IconButton(
            icon: Icon(
              _showPreview ? Icons.edit : Icons.visibility,
              color: _showPreview ? AppTheme.primaryColor : null,
            ),
            onPressed: () => setState(() => _showPreview = !_showPreview),
            tooltip: _showPreview ? 'Edit' : 'Preview',
          ),
      ],
    );
  }

  Widget _buildSplitView(ThemeData theme) {
    return Row(
      children: [
        // Editor
        Expanded(
          child: _buildEditor(theme),
        ),
        // Divider
        Container(
          width: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        // Preview
        Expanded(
          child: _buildPreview(theme),
        ),
      ],
    );
  }

  Widget _buildMobileView(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _showPreview
          ? _buildPreview(theme)
          : _buildEditor(theme),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: TextField(
        controller: _controller,
        onChanged: (_) => _onTextChanged(),
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: 'Enter markdown...',
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Markdown(
        data: _controller.text,
        padding: const EdgeInsets.all(16),
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          h1: theme.textTheme.headlineMedium,
          h2: theme.textTheme.headlineSmall,
          h3: theme.textTheme.titleLarge,
          p: theme.textTheme.bodyMedium,
          code: TextStyle(
            fontFamily: 'monospace',
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          codeblockDecoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
