/// Utilities for sanitizing input for filesystem and YAML safety.
class Sanitizers {
  /// Sanitizes a string for use as a filename or folder name.
  static String sanitizeForFilesystem(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Generates a unique filename for a new note.
  static String generateFilename(String templateId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitizeForFilesystem(templateId)}_$timestamp.md';
  }

  /// Generates a unique ID from a name.
  static String generateId(String name) {
    return sanitizeForFilesystem(name);
  }

  /// Quotes a YAML value if it contains special characters.
  static String quoteIfNeeded(dynamic value) {
    if (value == null) return '""';

    if (value is String) {
      if (value.isEmpty ||
          value.contains(':') ||
          value.contains('"') ||
          value.contains("'") ||
          value.contains('\n') ||
          value.contains('#') ||
          value.contains('[') ||
          value.contains(']') ||
          value.contains('{') ||
          value.contains('}') ||
          value.startsWith(' ') ||
          value.endsWith(' ') ||
          value.startsWith('-') ||
          value.startsWith('!') ||
          value.startsWith('&') ||
          value.startsWith('*') ||
          _looksLikeNumber(value) ||
          _looksLikeBoolean(value)) {
        // Use double quotes and escape internal quotes
        return '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
      }
      return value;
    }

    return value.toString();
  }

  /// Checks if a string looks like a number (would be parsed as such by YAML).
  static bool _looksLikeNumber(String value) {
    if (value.isEmpty) return false;

    // Starts with digit or minus sign followed by digit
    if (RegExp(r'^-?\d').hasMatch(value)) {
      // Check if it's actually parseable as a number
      return double.tryParse(value) != null || int.tryParse(value) != null;
    }

    return false;
  }

  /// Checks if a string looks like a boolean.
  static bool _looksLikeBoolean(String value) {
    final lower = value.toLowerCase();
    return lower == 'true' ||
        lower == 'false' ||
        lower == 'yes' ||
        lower == 'no' ||
        lower == 'on' ||
        lower == 'off';
  }

  /// Validates a template ID format.
  static bool isValidTemplateId(String id) {
    if (id.isEmpty) return false;
    // Must be lowercase letters, numbers, and underscores
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id);
  }

  /// Validates a field ID format.
  static bool isValidFieldId(String id) {
    if (id.isEmpty) return false;
    // Must be lowercase letters, numbers, and underscores
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id);
  }

  /// Converts a label to a valid ID.
  static String labelToId(String label) {
    return label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Converts a title to a filesystem-safe filename (without extension).
  static String toFilename(String title) {
    if (title.isEmpty) return 'untitled';
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
