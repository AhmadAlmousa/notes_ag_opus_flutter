import '../models/template.dart';
import '../services/storage_service.dart';
import '../../core/utils/markdown_parser.dart';

/// Repository for template CRUD operations.
class TemplateRepository {
  TemplateRepository(this._storage);

  final StorageService _storage;

  /// Cache of parsed templates.
  final Map<String, Template> _cache = {};

  /// Gets all templates.
  List<Template> getAll() {
    final templates = _storage.getTemplates();
    final result = <Template>[];

    for (final entry in templates.entries) {
      final template = _parseTemplate(entry.key, entry.value);
      if (template != null) {
        result.add(template);
      }
    }

    // Sort by name
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Gets a template by ID.
  Template? getById(String templateId) {
    // Check cache first
    if (_cache.containsKey(templateId)) {
      return _cache[templateId];
    }

    final content = _storage.getTemplate(templateId);
    if (content == null) return null;

    return _parseTemplate(templateId, content);
  }

  /// Saves a template.
  Future<void> save(Template template) async {
    final markdown = template.toMarkdown();
    await _storage.saveTemplate(template.templateId, markdown);

    // Update cache
    _cache[template.templateId] = template;
  }

  /// Deletes a template.
  Future<void> delete(String templateId) async {
    await _storage.deleteTemplate(templateId);
    _cache.remove(templateId);
  }

  /// Checks if a template ID is available.
  bool isIdAvailable(String templateId) {
    return !_storage.getTemplates().containsKey(templateId);
  }

  /// Creates a new template with default values.
  Template createNew({
    String? templateId,
    String? name,
  }) {
    return Template(
      templateId: templateId ?? 'new_template',
      name: name ?? 'New Template',
      version: 1,
      layout: TemplateLayout.cards,
      fields: [],
      actions: [],
    );
  }

  /// Increments version when updating a template.
  Template incrementVersion(Template template) {
    return template.copyWith(version: template.version + 1);
  }

  /// Clears the cache.
  void clearCache() {
    _cache.clear();
  }

  Template? _parseTemplate(String templateId, String content) {
    final parsed = MarkdownParser.parseTemplate(content);
    if (parsed == null) return null;

    final (frontmatter, schema) = parsed;
    final template = Template.fromYaml(
      frontmatter: frontmatter,
      schema: schema,
    );

    _cache[templateId] = template;
    return template;
  }
}
