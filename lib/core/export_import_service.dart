import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/repositories/note_repository.dart';
import '../data/services/storage_service.dart';

/// Service for exporting and importing notes as zip files.
class ExportImportService {
  const ExportImportService._();

  /// Export all notes as a zip file download.
  static Future<void> exportNotesToZip(
    BuildContext context, {
    required StorageService storage,
  }) async {
    try {
      final notes = storage.getNotes();
      final templates = storage.getTemplates();

      if (notes.isEmpty && templates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No notes or templates to export')),
        );
        return;
      }

      // Create archive
      final archive = Archive();

      // Add notes to archive, organized by category
      for (final entry in notes.entries) {
        final path = 'notes/${entry.key}'; // notes/category/filename
        final content = utf8.encode(entry.value);
        archive.addFile(ArchiveFile(
          path,
          content.length,
          content,
        ));
      }

      // Add templates to archive
      for (final entry in templates.entries) {
        final path = 'templates/${entry.key}.md';
        final content = utf8.encode(entry.value);
        archive.addFile(ArchiveFile(
          path,
          content.length,
          content,
        ));
      }

      // Encode to zip
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create zip file')),
        );
        return;
      }

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final filename = 'organote_backup_$timestamp.zip';

      // Save file (triggers download in browser)
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: Uint8List.fromList(zipData),
        mimeType: MimeType.zip,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${notes.length} notes and ${templates.length} templates'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Import notes from a zip file.
  static Future<void> importFromZip(
    BuildContext context, {
    required StorageService storage,
    required NoteRepository noteRepo,
  }) async {
    try {
      // Pick zip file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file')),
        );
        return;
      }

      // Decode zip
      final archive = ZipDecoder().decodeBytes(file.bytes!);
      
      int notesImported = 0;
      int templatesImported = 0;

      for (final archiveFile in archive) {
        if (archiveFile.isFile) {
          final content = utf8.decode(archiveFile.content as List<int>);
          final path = archiveFile.name;

          if (path.startsWith('notes/')) {
            // Extract category/filename from path
            final relativePath = path.substring('notes/'.length);
            final parts = relativePath.split('/');
            if (parts.length >= 2) {
              final category = parts[0];
              final filename = parts.sublist(1).join('/');
              await storage.saveNote(category, filename, content);
              notesImported++;
            }
          } else if (path.startsWith('templates/')) {
            // Extract templateId from path
            final relativePath = path.substring('templates/'.length);
            final templateId = relativePath.replaceAll('.md', '');
            await storage.saveTemplate(templateId, content);
            templatesImported++;
          }
        }
      }

      // Clear caches to reload data
      noteRepo.clearCache();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $notesImported notes and $templatesImported templates'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
