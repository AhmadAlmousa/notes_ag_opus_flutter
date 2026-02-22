import '../models/note.dart';
import '../services/storage_service.dart';
import '../../core/utils/markdown_parser.dart';
import '../../core/utils/sanitizers.dart';

/// Repository for note CRUD operations.
class NoteRepository {
  NoteRepository(this._storage);

  final StorageService _storage;

  /// Cache of parsed notes.
  final Map<String, Note> _cache = {};

  /// Gets all notes.
  List<Note> getAll() {
    final notes = _storage.getNotes();
    final result = <Note>[];

    for (final entry in notes.entries) {
      final parts = entry.key.split('/');
      if (parts.length >= 2) {
        final category = parts[0];
        final filename = parts.sublist(1).join('/');
        final note = _parseNote(category, filename, entry.value);
        if (note != null) {
          result.add(note);
        }
      }
    }

    return result;
  }

  /// Gets notes by category.
  List<Note> getByCategory(String category) {
    final notes = _storage.getNotesByCategory(category);
    final result = <Note>[];

    for (final entry in notes.entries) {
      final parts = entry.key.split('/');
      if (parts.length >= 2) {
        final filename = parts.sublist(1).join('/');
        final note = _parseNote(category, filename, entry.value);
        if (note != null) {
          result.add(note);
        }
      }
    }

    return result;
  }

  /// Gets notes by template ID.
  List<Note> getByTemplate(String templateId) {
    return getAll().where((n) => n.templateId == templateId).toList();
  }

  /// Gets a specific note.
  Note? getNote(String category, String filename) {
    final cacheKey = '$category/$filename';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final content = _storage.getNote(category, filename);
    if (content == null) return null;

    return _parseNote(category, filename, content);
  }

  /// Saves a note.
  Future<void> save(Note note) async {
    final markdown = note.toMarkdown();
    await _storage.saveNote(note.category, note.filename, markdown);

    // Update cache
    _cache['${note.category}/${note.filename}'] = note;

    // Update search index
    await _updateSearchIndex(note);
  }

  /// Deletes a note.
  Future<void> delete(String category, String filename) async {
    await _storage.deleteNote(category, filename);
    _cache.remove('$category/$filename');
  }

  /// Creates a new note for a template.
  Note createNew({
    required String templateId,
    required String category,
    String? title,
    String? icon,
    int templateVersion = 1,
    List<String> tags = const [],
  }) {
    final String filename;
    if (title != null && title.isNotEmpty) {
      final base = Sanitizers.labelToId(title);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filename = '${base}_$timestamp.md';
    } else {
      filename = Sanitizers.generateFilename(templateId);
    }
    return Note(
      id: filename.replaceAll('.md', ''),
      templateId: templateId,
      templateVersion: templateVersion,
      category: category,
      filename: filename,
      title: title,
      icon: icon,
      tags: tags,
      records: [{}], // Start with one empty record
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Searches notes by query.
  List<Note> search(String query) {
    final lowerQuery = query.toLowerCase();
    final results = <Note>[];

    for (final note in getAll()) {
      // Search in filename
      if (note.filename.toLowerCase().contains(lowerQuery)) {
        results.add(note);
        continue;
      }

      // Search in tags
      if (note.tags.any((t) => t.toLowerCase().contains(lowerQuery))) {
        results.add(note);
        continue;
      }

      // Search in records
      for (final record in note.records) {
        bool found = false;
        for (final value in record.values) {
          if (value.toString().toLowerCase().contains(lowerQuery)) {
            results.add(note);
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    return results;
  }

  /// Gets all categories.
  List<String> getCategories() {
    return _storage.getCategories();
  }

  /// Adds a new category.
  Future<void> addCategory(String name) async {
    await _storage.addCategory(name);
  }

  /// Gets recent notes.
  List<Note> getRecent({int limit = 10}) {
    final all = getAll();
    // Sort by updated time (newest first)
    all.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? DateTime(1970);
      final bTime = b.updatedAt ?? b.createdAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    return all.take(limit).toList();
  }

  /// Clears the cache.
  void clearCache() {
    _cache.clear();
  }

  /// Renames a category – moves all notes from old to new.
  Future<void> renameCategory(String oldName, String newName) async {
    final notes = getByCategory(oldName);
    for (final note in notes) {
      final updatedNote = note.copyWith(category: newName);
      // Save under new category
      await _storage.saveNote(
          updatedNote.category, updatedNote.filename, updatedNote.toMarkdown());
      _cache['${updatedNote.category}/${updatedNote.filename}'] = updatedNote;
      // Delete old
      await _storage.deleteNote(oldName, note.filename);
      _cache.remove('$oldName/${note.filename}');
    }
  }

  /// Deletes a category and all its notes.
  Future<void> deleteCategory(String name) async {
    final notes = getByCategory(name);
    for (final note in notes) {
      await delete(name, note.filename);
    }
  }

  Note? _parseNote(String category, String filename, String content) {
    final parsed = MarkdownParser.parseNote(content);
    if (parsed == null) return null;

    final (frontmatter, data) = parsed;
    final note = Note.fromYaml(
      frontmatter: frontmatter,
      data: data,
      category: category,
      filename: filename,
    );

    _cache['$category/$filename'] = note;
    return note;
  }

  Future<void> _updateSearchIndex(Note note) async {
    // Simple search index: store searchable text for each note
    final index = _storage.getSearchIndex();
    final searchText = <String>[];

    searchText.add(note.filename);
    if (note.title != null) searchText.add(note.title!);
    searchText.addAll(note.tags);
    for (final record in note.records) {
      for (final value in record.values) {
        searchText.add(value.toString());
      }
    }

    index['${note.category}/${note.filename}'] = searchText.join(' ');
    await _storage.updateSearchIndex(index);
  }
}
