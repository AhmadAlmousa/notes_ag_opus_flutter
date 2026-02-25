import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note.dart';
import '../../widgets/common/note_card.dart';
import '../../widgets/layout/app_scaffold.dart';

/// Notes list screen.
class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key, this.category, this.tag});

  final String? category;
  final String? tag;

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<Note> _notes = [];
  List<String> _categories = [];
  late String _selectedCategory;
  String? _activeTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category ?? 'all';
    _activeTag = widget.tag;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  @override
  void didUpdateWidget(covariant NotesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category || oldWidget.tag != widget.tag) {
      _selectedCategory = widget.category ?? 'all';
      _activeTag = widget.tag;
      _loadData();
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final noteRepo = ref.read(noteRepoProvider);
    final categories = ['all', ...noteRepo.getCategories()];
    List<Note> notes = _selectedCategory == 'all'
        ? noteRepo.getAll()
        : noteRepo.getByCategory(_selectedCategory);
    // Apply tag filter
    if (_activeTag != null && _activeTag!.isNotEmpty) {
      notes = notes.where((n) => n.tags.contains(_activeTag)).toList();
    }
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _notes = notes;
      _isLoading = false;
    });
    _animationController.forward(from: 0);
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Reload data when remote sync changes arrive
    ref.listen(syncTriggerProvider, (_, __) => _loadData());

    final theme = Theme.of(context);

    return AppScaffold(
      currentIndex: 1,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeTag != null
                              ? 'Notes tagged "#$_activeTag"'
                              : 'Files',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_activeTag != null)
                          TextButton.icon(
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Clear', style: TextStyle(fontSize: 12)),
                            onPressed: () => setState(() {
                              _activeTag = null;
                              _loadData();
                            }),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${_notes.length} note${_notes.length != 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category tabs
                SliverToBoxAdapter(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _categories.length - 1 ? 8 : 0,
                          ),
                          child: FilterChip(
                            label: Text(
                              category == 'all'
                                  ? 'All'
                                  : category[0].toUpperCase() +
                                      category.substring(1),
                            ),
                            selected: isSelected,
                            onSelected: (_) => _onCategoryChanged(category),
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Notes list
                if (_notes.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildAnimatedItem(
                            index,
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: NoteCard(
                                key: ValueKey(_notes[index].id),
                                note: _notes[index],
                                onTap: () => _openNote(_notes[index]),
                                templateName: ref.read(templateRepoProvider)
                                    .getById(_notes[index].templateId)
                                    ?.name,
                              ),
                            ),
                          );
                        },
                        childCount: _notes.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    final startTime = 0.1 * index;
    final endTime = startTime + 0.4;

    final opacity = _animationController.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(
          curve: Interval(
            startTime.clamp(0.0, 1.0),
            endTime.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: opacity,
        builder: (context, _) => Transform.translate(
          offset: Offset(0, 20 * (1 - opacity.value)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.folder_open_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedCategory == 'all'
                  ? 'No notes yet'
                  : 'No notes in ${_selectedCategory}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a note from the home screen',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNote(Note note) async {
    await context.push('/notes/${note.category}/${note.filename}');
    // Reload when returning from view/edit
    _loadData();
  }
}
