/// A note that stores structured data based on a template.
class Note {
  const Note({
    required this.id,
    required this.templateId,
    this.templateVersion = 1,
    required this.category,
    required this.filename,
    this.title,
    this.icon,
    this.tags = const [],
    this.records = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String templateId;
  final int templateVersion;
  final String category;
  final String filename;
  final String? title;
  final String? icon;
  final List<String> tags;
  final List<Map<String, dynamic>> records;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Creates a Note from parsed YAML frontmatter and data block.
  factory Note.fromYaml({
    required Map<String, dynamic> frontmatter,
    required List<dynamic> data,
    required String category,
    required String filename,
  }) {
    return Note(
      id: frontmatter['id'] as String? ?? filename.replaceAll('.md', ''),
      templateId: frontmatter['template_id'] as String? ?? '',
      templateVersion: frontmatter['template_version'] as int? ?? 1,
      category: category,
      filename: filename,
      title: frontmatter['title'] as String?,
      icon: frontmatter['icon'] as String?,
      tags: (frontmatter['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      records: data.map((r) => Map<String, dynamic>.from(r as Map)).toList(),
    );
  }

  /// Converts note to markdown file content.
  String toMarkdown() {
    final buffer = StringBuffer();

    // Frontmatter
    buffer.writeln('---');
    buffer.writeln('template_id: $templateId');
    buffer.writeln('template_version: $templateVersion');
    buffer.writeln('id: $id');
    if (title != null && title!.isNotEmpty) {
      buffer.writeln('title: $title');
    }
    if (icon != null && icon!.isNotEmpty) {
      buffer.writeln('icon: $icon');
    }
    if (tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in tags) {
        buffer.writeln('  - $tag');
      }
    }
    buffer.writeln('---');
    buffer.writeln();

    // Data block
    buffer.writeln('```data');
    for (final record in records) {
      buffer.write('- ');
      var first = true;
      for (final entry in record.entries) {
        if (!first) {
          buffer.write('  ');
        }
        buffer.writeln('${entry.key}: ${_formatValue(entry.value)}');
        first = false;
      }
    }
    buffer.writeln('```');

    return buffer.toString();
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is String) {
      // Quote if contains special characters
      if (value.contains(':') ||
          value.contains('"') ||
          value.contains('\n') ||
          value.startsWith(' ') ||
          value.endsWith(' ')) {
        return '"${value.replaceAll('"', '\\"')}"';
      }
      return value;
    }
    return value.toString();
  }

  Note copyWith({
    String? id,
    String? templateId,
    int? templateVersion,
    String? category,
    String? filename,
    String? title,
    String? icon,
    List<String>? tags,
    List<Map<String, dynamic>>? records,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateVersion: templateVersion ?? this.templateVersion,
      category: category ?? this.category,
      filename: filename ?? this.filename,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      records: records ?? this.records,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns display title based on title, primary field, or filename.
  String getDisplayTitle([String? primaryField]) {
    // Prefer explicit title
    if (title != null && title!.isNotEmpty) return title!;

    if (records.isEmpty) return filename.replaceAll('.md', '');
    final firstRecord = records.first;

    if (primaryField != null && firstRecord.containsKey(primaryField)) {
      return firstRecord[primaryField].toString();
    }

    // Try common fields
    for (final key in ['name', 'title', 'service', 'label']) {
      if (firstRecord.containsKey(key)) {
        return firstRecord[key].toString();
      }
    }

    return filename.replaceAll('.md', '');
  }
}
