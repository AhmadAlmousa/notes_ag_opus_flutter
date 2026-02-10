import 'package:yaml/yaml.dart';

/// Utilities for parsing markdown files with YAML frontmatter and code blocks.
class MarkdownParser {
  /// Parses a template markdown file.
  /// Returns (frontmatter, schema) or null if parsing fails.
  static (Map<String, dynamic>, Map<String, dynamic>)? parseTemplate(
    String content,
  ) {
    final frontmatter = extractFrontmatter(content);
    if (frontmatter == null) return null;

    final schema = extractCodeBlock(content, 'schema');
    if (schema == null) return null;

    return (frontmatter, schema);
  }

  /// Parses a note markdown file.
  /// Returns (frontmatter, data) or null if parsing fails.
  static (Map<String, dynamic>, List<dynamic>)? parseNote(String content) {
    final frontmatter = extractFrontmatter(content);
    if (frontmatter == null) return null;

    final dataBlock = extractCodeBlock(content, 'data');
    if (dataBlock == null) {
      // Notes might have empty data
      return (frontmatter, <dynamic>[]);
    }

    // Data block should be a list of records
    if (dataBlock is List) {
      return (frontmatter, dataBlock);
    } else if (dataBlock is Map) {
      // Single record, wrap in list
      return (frontmatter, [dataBlock]);
    }

    return (frontmatter, <dynamic>[]);
  }

  /// Extracts YAML frontmatter from markdown content.
  static Map<String, dynamic>? extractFrontmatter(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty || lines[0].trim() != '---') return null;

    final endIndex = lines.indexWhere(
      (line) => line.trim() == '---',
      1,
    );
    if (endIndex == -1) return null;

    final yamlContent = lines.sublist(1, endIndex).join('\n');
    try {
      final yaml = loadYaml(yamlContent);
      return _yamlToMap(yaml);
    } catch (_) {
      return null;
    }
  }

  /// Extracts a code block with specified language tag.
  static dynamic extractCodeBlock(String content, String language) {
    final pattern = RegExp(
      '```$language\\s*\\n([\\s\\S]*?)\\n```',
      multiLine: true,
    );
    final match = pattern.firstMatch(content);
    if (match == null) return null;

    final blockContent = match.group(1);
    if (blockContent == null) return null;

    try {
      final yaml = loadYaml(blockContent);
      if (yaml is YamlList) {
        return yaml.map((e) => _yamlToMap(e)).toList();
      }
      return _yamlToMap(yaml);
    } catch (_) {
      return null;
    }
  }

  /// Converts YamlMap to regular Map recursively.
  static Map<String, dynamic> _yamlToMap(dynamic yaml) {
    if (yaml == null) return {};
    if (yaml is! YamlMap && yaml is! Map) return {};

    final map = <String, dynamic>{};
    for (final entry in (yaml as Map).entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is YamlMap || value is Map) {
        map[key] = _yamlToMap(value);
      } else if (value is YamlList || value is List) {
        map[key] = _yamlListToList(value);
      } else {
        map[key] = value;
      }
    }
    return map;
  }

  /// Converts YamlList to regular List recursively.
  static List<dynamic> _yamlListToList(dynamic yaml) {
    if (yaml == null) return [];
    if (yaml is! YamlList && yaml is! List) return [];

    return (yaml as List).map((item) {
      if (item is YamlMap || item is Map) {
        return _yamlToMap(item);
      } else if (item is YamlList || item is List) {
        return _yamlListToList(item);
      }
      return item;
    }).toList();
  }
}
