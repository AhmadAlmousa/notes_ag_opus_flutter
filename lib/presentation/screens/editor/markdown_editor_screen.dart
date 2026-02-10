import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note.dart';

/// Markdown source editor with split-pane preview.
class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({
    super.key,
    required this.category,
    required this.filename,
  });

  final String category;
  final String filename;

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  late TextEditingController _controller;
  Note? _note;
  String _originalContent = '';
  bool _isLoading = true;
  bool _hasChanges = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _note = AppState.instance.noteRepository.getNote(
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
      });
    }
  }

  Future<void> _save() async {
    if (_note == null) return;

    // For now, save the raw markdown
    await AppState.instance.storage.saveNote(
      widget.category,
      widget.filename,
      _controller.text,
    );

    // Clear cache so it gets reparsed
    AppState.instance.noteRepository.clearCache();

    setState(() {
      _originalContent = _controller.text;
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
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
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
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
          if (_hasChanges)
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
        // Save button
        TextButton.icon(
          onPressed: _hasChanges ? _save : null,
          icon: const Icon(Icons.save),
          label: const Text('Save'),
          style: TextButton.styleFrom(
            foregroundColor:
                _hasChanges ? AppTheme.primaryColor : theme.disabledColor,
          ),
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
