import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_state.dart';
import '../../../core/compliance_checker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note.dart';
import '../../../data/models/template.dart';
import '../../widgets/common/note_card.dart';
import '../../widgets/common/search_bar.dart' as app;
import '../../widgets/layout/app_scaffold.dart';

/// Dashboard home screen.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  List<Template> _templates = [];
  List<Note> _recentNotes = [];
  List<String> _categories = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  SystemCompliance? _compliance;

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
    final appState = AppState.instance;
    final templates = appState.templateRepository.getAll();
    final allNotes = appState.noteRepository.getAll();
    
    // Build template map for compliance checking
    final templateMap = <String, Template>{};
    for (final template in templates) {
      templateMap[template.templateId] = template;
    }
    
    // Check compliance
    final compliance = ComplianceChecker.checkAll(allNotes, templateMap);

    setState(() {
      _templates = templates;
      _recentNotes = appState.noteRepository.getRecent(limit: 10);
      _categories = ['all', ...appState.noteRepository.getCategories()];
      _compliance = compliance;
      _isLoading = false;
    });

    // Setup staggered animations
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    final itemCount = _recentNotes.length + 3; // header + search + categories
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
        _recentNotes = AppState.instance.noteRepository.getRecent(limit: 10);
      } else {
        _recentNotes = AppState.instance.noteRepository.getByCategory(category);
      }
    });
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    setState(() {
      _recentNotes = AppState.instance.noteRepository.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      currentIndex: 0,
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
                    child: _buildAnimatedItem(
                      0,
                      _buildHeader(context),
                    ),
                  ),

                  // Compliance status
                  SliverToBoxAdapter(
                    child: _buildAnimatedItem(
                      1,
                      _buildComplianceStatus(context),
                    ),
                  ),

                  // Search bar
                  SliverToBoxAdapter(
                    child: _buildAnimatedItem(
                      2,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: app.AppSearchBar(
                          onSearch: _onSearch,
                          hintText: 'Search notes, tags, or content...',
                        ),
                      ),
                    ),
                  ),

                  // Category chips
                  SliverToBoxAdapter(
                    child: _buildAnimatedItem(
                      3,
                      _buildCategoryChips(context),
                    ),
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
                                  note: _recentNotes[index],
                                  onTap: () => _openNote(_recentNotes[index]),
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
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceStatus(BuildContext context) {
    final theme = Theme.of(context);
    final compliance = _compliance;
    final isHealthy = compliance?.isHealthy ?? true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: isHealthy ? null : () => _showComplianceDetails(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHealthy 
                  ? theme.colorScheme.outline.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.3),
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                color: isHealthy ? Colors.green.shade500 : Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  compliance?.statusText ?? 'Checking compliance...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isHealthy ? null : Colors.orange.shade800,
                  ),
                ),
              ),
              if (!isHealthy)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.orange.shade600,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplianceDetails(BuildContext context) {
    final theme = Theme.of(context);
    final compliance = _compliance;
    if (compliance == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
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
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Compliance Issues',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: compliance.issues.length,
                itemBuilder: (context, index) {
                  final issue = compliance.issues[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.note.getDisplayTitle(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          issue.summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openNote(issue.note);
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Note'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
        itemCount: _categories.length,
        itemBuilder: (context, index) {
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
