import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/compliance_checker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note.dart';
import '../../../data/models/template.dart';
import '../../widgets/common/note_card.dart';
import '../../widgets/common/search_bar.dart' as app;
import '../../widgets/layout/app_scaffold.dart';

/// Dashboard home screen.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  List<Template> _templates = [];
  List<Note> _recentNotes = [];
  List<String> _categories = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  bool _hasComplianceIssues = false;
  bool _isSearching = false;
  final TextEditingController _searchTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Refresh caches from file system to detect manually-added files
    await ref.read(storageProvider).refreshCaches();
    ref.read(templateRepoProvider).clearCache();
    ref.read(noteRepoProvider).clearCache();

    final appState = ref;
    final templates = appState.read(templateRepoProvider).getAll();
    final allNotes = appState.read(noteRepoProvider).getAll();
    
    // Build template map for compliance checking
    final templateMap = <String, Template>{};
    for (final template in templates) {
      templateMap[template.templateId] = template;
    }
    
    // Check compliance
    final compliance = ComplianceChecker.checkAll(allNotes, templateMap);

    if (!mounted) return;
    setState(() {
      _templates = templates;
      _recentNotes = ref.read(noteRepoProvider).getRecent(limit: 10);
      _categories = ['all', ...ref.read(noteRepoProvider).getCategories()];
      _hasComplianceIssues = !(compliance.isHealthy);
      _isLoading = false;
    });

    // Setup staggered animations
    _setupAnimations();
    _animationController.forward(from: 0);
  }

  void _setupAnimations() {
    final itemCount = _recentNotes.length + 2; // header + categories
    _itemAnimations = List.generate(itemCount, (index) {
      final startTime = 0.1 * index;
      final endTime = startTime + 0.3;
      return CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          startTime.clamp(0.0, 1.0),
          endTime.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  Animation<double> _getAnimation(int index) {
    if (index >= 0 && index < _itemAnimations.length) {
      return _itemAnimations[index];
    }
    return const AlwaysStoppedAnimation(1.0);
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'all') {
        _recentNotes = ref.read(noteRepoProvider).getRecent(limit: 10);
      } else {
        _recentNotes = ref.read(noteRepoProvider).getByCategory(category);
      }
    });
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    setState(() {
      _recentNotes = ref.read(noteRepoProvider).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reload data when remote sync changes arrive
    ref.listen(syncTriggerProvider, (_, __) => _loadData());

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      currentIndex: 0,
      hasSettingsBadge: _hasComplianceIssues,
      floatingActionButton: _buildFab(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildAnimatedItem(0, _buildHeader(context)),
                  ),

                  // Inline search bar (shown when _isSearching)
                  if (_isSearching)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: TextField(
                          controller: _searchTextController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search notes, tags, or content...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(() {
                                _isSearching = false;
                                _searchTextController.clear();
                                _onSearch('');
                              }),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onChanged: _onSearch,
                        ),
                      ),
                    ),

                  // Category chips
                  SliverToBoxAdapter(
                    child: _buildAnimatedItem(1, _buildCategoryChips(context)),
                  ),

                  // Recent notes header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Notes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.sort,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              // TODO: Sort options
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notes list
                  if (_recentNotes.isEmpty)
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
                              index + 4,
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: NoteCard(
                                  key: ValueKey(_recentNotes[index].id),
                                  note: _recentNotes[index],
                                  onTap: () => _openNote(_recentNotes[index]),
                                  templateName: ref.read(templateRepoProvider)
                                      .getById(_recentNotes[index].templateId)
                                      ?.name,
                                ),
                              ),
                            );
                          },
                          childCount: _recentNotes.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    final animation = _getAnimation(index);
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organote',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your structured data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Search icon (replaces avatar)
          IconButton(
            onPressed: () => setState(() => _isSearching = !_isSearching),
            tooltip: 'Search',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isSearching ? Icons.close : Icons.search,
                key: ValueKey(_isSearching),
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCategoryChips(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length + 1, // +1 for edit pill
        itemBuilder: (context, index) {
          // Last item = edit pill
          if (index == _categories.length) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ActionChip(
                avatar: const Icon(Icons.edit, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                onPressed: () => _showEditCategoriesDialog(context),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }

          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: EdgeInsets.only(
              right: index < _categories.length - 1 ? 8 : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: FilterChip(
                label: Text(
                  category == 'all'
                      ? 'All Notes'
                      : category[0].toUpperCase() + category.substring(1),
                ),
                selected: isSelected,
                onSelected: (_) => _onCategorySelected(category),
                backgroundColor: theme.colorScheme.surface,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditCategoriesDialog(BuildContext context) {
    final noteRepo = ref.read(noteRepoProvider);
    // Get only real categories (not 'all')
    final cats = noteRepo.getCategories();

    showDialog(
      context: context,
      builder: (ctx) {
        return _EditCategoriesDialog(
          categories: cats,
          onRename: (oldName, newName) async {
            await noteRepo.renameCategory(oldName, newName);
            _loadData();
          },
          onDelete: (name) async {
            await noteRepo.deleteCategory(name);
            _loadData();
          },
          onAdd: (name) async {
            await noteRepo.addCategory(name);
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first note from a template',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showNewNoteDialog(context),
      elevation: 4,
      child: const Icon(Icons.add, size: 28),
    );
  }

  void _showNewNoteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewNoteSheet(templates: _templates),
    );
  }

  void _openNote(Note note) {
    context.push('/notes/${note.category}/${note.filename}');
  }
}

/// Bottom sheet for creating a new note.
class _NewNoteSheet extends StatelessWidget {
  const _NewNoteSheet({required this.templates});

  final List<Template> templates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Create New Note',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: templates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.extension_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No templates yet',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/templates/new');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Template'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return _TemplateOption(
                            template: template,
                            onTap: () {
                              Navigator.pop(context);
                              context.push(
                                '/new-note/${template.templateId}',
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
  const _TemplateOption({
    required this.template,
    required this.onTap,
  });

  final Template template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.extension,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${template.fields.length} fields • ${template.layout.displayName} layout',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for editing categories (rename / delete / add).
class _EditCategoriesDialog extends StatefulWidget {
  const _EditCategoriesDialog({
    required this.categories,
    required this.onRename,
    required this.onDelete,
    required this.onAdd,
  });

  final List<String> categories;
  final Future<void> Function(String oldName, String newName) onRename;
  final Future<void> Function(String name) onDelete;
  final Future<void> Function(String name) onAdd;

  @override
  State<_EditCategoriesDialog> createState() => _EditCategoriesDialogState();
}

class _EditCategoriesDialogState extends State<_EditCategoriesDialog> {
  late List<String> _cats;

  @override
  void initState() {
    super.initState();
    _cats = List.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Categories'),
      content: SizedBox(
        width: 320,
        child: _cats.isEmpty
            ? const Center(child: Text('No categories'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _cats.length,
                itemBuilder: (context, index) {
                  final cat = _cats[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      cat[0].toUpperCase() + cat.substring(1),
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _renameCategory(cat),
                          tooltip: 'Rename',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: () => _deleteCategory(cat),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _addCategory,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final normalized = name.toLowerCase();
      if (!_cats.contains(normalized)) {
        await widget.onAdd(normalized);
        setState(() => _cats.add(normalized));
      }
    }
  }

  void _renameCategory(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New name',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      await widget.onRename(oldName, newName.toLowerCase());
      setState(() {
        final idx = _cats.indexOf(oldName);
        if (idx >= 0) _cats[idx] = newName.toLowerCase();
      });
    }
  }

  void _deleteCategory(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            'All notes in "$name" will be deleted. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.onDelete(name);
      setState(() => _cats.remove(name));
    }
  }
}
