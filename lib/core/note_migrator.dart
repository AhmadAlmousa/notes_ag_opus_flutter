import '../data/models/field.dart';
import '../data/models/note.dart';
import '../data/models/template.dart';
import '../data/repositories/note_repository.dart';

/// Migrates notes when their parent template is modified.
///
/// **Golden rule:** Never delete or discard any user data.
/// If a field is removed from the template, the data stays in the note.
/// If a field is renamed, copy value to the new key (keep old too).
/// If a field type changes, keep existing value as-is.
class NoteMigrator {
  const NoteMigrator._();

  /// Migrate all notes that use [oldTemplate] to be compatible with
  /// [newTemplate].
  ///
  /// Returns the number of notes migrated.
  static Future<int> migrateNotes({
    required Template? oldTemplate,
    required Template newTemplate,
    required NoteRepository noteRepo,
  }) async {
    if (oldTemplate == null) return 0;

    // Build field ID mapping: old field id → new field id
    final fieldIdMap = _buildFieldIdMap(oldTemplate.fields, newTemplate.fields);

    // Nothing changed in the field IDs — still update version
    final notes = noteRepo.getByTemplate(oldTemplate.templateId);
    if (notes.isEmpty) return 0;

    int migratedCount = 0;

    for (final note in notes) {
      final migratedRecords = <Map<String, dynamic>>[];
      bool changed = false;

      for (final record in note.records) {
        final newRecord = Map<String, dynamic>.from(record);

        // Apply field ID renames
        for (final entry in fieldIdMap.entries) {
          final oldId = entry.key;
          final newId = entry.value;

          if (oldId != newId && newRecord.containsKey(oldId)) {
            // Copy value to new key
            newRecord[newId] = newRecord[oldId];
            // Also handle custom label sub-keys
            if (newRecord.containsKey('${oldId}_label')) {
              newRecord['${newId}_label'] = newRecord['${oldId}_label'];
            }
            if (newRecord.containsKey('${oldId}_value')) {
              newRecord['${newId}_value'] = newRecord['${oldId}_value'];
            }
            changed = true;
          }
        }

        migratedRecords.add(newRecord);
      }

      // Always update the template version to match the new template
      if (note.templateVersion != newTemplate.version || changed) {
        final updatedNote = note.copyWith(
          templateVersion: newTemplate.version,
          records: changed ? migratedRecords : null,
          updatedAt: DateTime.now(),
        );
        await noteRepo.save(updatedNote);
        migratedCount++;
      }
    }

    return migratedCount;
  }

  /// Build a mapping from old field IDs to new field IDs.
  ///
  /// Strategy: match by position first, then by label similarity.
  /// If a field at the same position has the same label, map it.
  /// If IDs differ but labels match, it's a rename.
  static Map<String, String> _buildFieldIdMap(
    List<Field> oldFields,
    List<Field> newFields,
  ) {
    final map = <String, String>{};

    // First pass: match by exact ID
    final newFieldIds = newFields.map((f) => f.id).toSet();
    for (final oldField in oldFields) {
      if (newFieldIds.contains(oldField.id)) {
        map[oldField.id] = oldField.id; // Same ID, no rename
      }
    }

    // Second pass: for unmatched old fields, try position-based matching
    final unmatchedOld = oldFields.where((f) => !map.containsKey(f.id)).toList();
    final unmatchedNewIds = newFields
        .where((f) => !map.values.contains(f.id))
        .toList();

    for (final oldField in unmatchedOld) {
      // Try to find a new field with the same label
      final labelMatch = unmatchedNewIds.where(
        (nf) => nf.label.toLowerCase() == oldField.label.toLowerCase(),
      );
      if (labelMatch.isNotEmpty) {
        map[oldField.id] = labelMatch.first.id;
        unmatchedNewIds.remove(labelMatch.first);
        continue;
      }

      // Try position-based: if this old field was at index N and new field
      // at index N is unmatched, assume it's a rename
      final oldIndex = oldFields.indexOf(oldField);
      if (oldIndex < newFields.length) {
        final candidate = newFields[oldIndex];
        if (unmatchedNewIds.contains(candidate)) {
          map[oldField.id] = candidate.id;
          unmatchedNewIds.remove(candidate);
        }
      }
    }

    return map;
  }
}
