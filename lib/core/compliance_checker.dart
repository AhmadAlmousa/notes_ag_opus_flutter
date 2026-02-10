import '../data/models/field.dart';
import '../data/models/note.dart';
import '../data/models/template.dart';

/// Compliance check result for a single note.
class ComplianceResult {
  const ComplianceResult({
    required this.isCompliant,
    required this.note,
    this.missingFields = const [],
    this.templateMismatch = false,
  });

  final bool isCompliant;
  final Note note;
  final List<String> missingFields;
  final bool templateMismatch;

  String get summary {
    if (isCompliant) return 'Compliant';
    if (templateMismatch) return 'Template version mismatch';
    if (missingFields.isNotEmpty) {
      return 'Missing: ${missingFields.join(', ')}';
    }
    return 'Non-compliant';
  }
}

/// Overall system compliance status.
class SystemCompliance {
  const SystemCompliance({
    required this.totalNotes,
    required this.compliantNotes,
    required this.nonCompliantNotes,
    required this.issues,
  });

  final int totalNotes;
  final int compliantNotes;
  final int nonCompliantNotes;
  final List<ComplianceResult> issues;

  bool get isHealthy => nonCompliantNotes == 0;
  
  double get compliancePercent => 
      totalNotes > 0 ? (compliantNotes / totalNotes) * 100 : 100;

  String get statusText {
    if (isHealthy) return 'All $totalNotes notes compliant';
    return '$nonCompliantNotes of $totalNotes notes need attention';
  }
}

/// Utility class for checking note compliance against templates.
class ComplianceChecker {
  const ComplianceChecker._();

  /// Check a single note against its template.
  static ComplianceResult checkNote(Note note, Template? template) {
    if (template == null) {
      return ComplianceResult(
        isCompliant: false,
        note: note,
        templateMismatch: true,
      );
    }

    // Check template version
    if (note.templateVersion < template.version) {
      // Note was created with older template version
      // This is a soft warning, not a hard failure
    }

    // Check required fields in all records
    final missingFields = <String>[];
    
    for (final field in template.fields) {
      if (field.required) {
        for (int i = 0; i < note.records.length; i++) {
          final record = note.records[i];
          final value = record[field.id];
          
          if (value == null || value.toString().isEmpty) {
            final fieldName = note.records.length > 1
                ? '${field.label} (Record ${i + 1})'
                : field.label;
            if (!missingFields.contains(fieldName)) {
              missingFields.add(fieldName);
            }
          }
        }
      }
    }

    return ComplianceResult(
      isCompliant: missingFields.isEmpty,
      note: note,
      missingFields: missingFields,
    );
  }

  /// Check all notes against their templates.
  static SystemCompliance checkAll(
    List<Note> notes,
    Map<String, Template> templateMap,
  ) {
    final issues = <ComplianceResult>[];
    int compliant = 0;
    int nonCompliant = 0;

    for (final note in notes) {
      final template = templateMap[note.templateId];
      final result = checkNote(note, template);
      
      if (result.isCompliant) {
        compliant++;
      } else {
        nonCompliant++;
        issues.add(result);
      }
    }

    return SystemCompliance(
      totalNotes: notes.length,
      compliantNotes: compliant,
      nonCompliantNotes: nonCompliant,
      issues: issues,
    );
  }
}
