import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme/app_theme.dart';
import '../../../data/models/field.dart';
import '../../../data/services/fs_interop.dart';

/// Multi-image input widget for the note editor.
///
/// Stores value as a JSON-encoded list of image references:
///   - `"assets/<uuid>_<filename>"` for uploaded files
///   - `"https://..."` for URL-based images
class ImageFieldInput extends StatefulWidget {
  const ImageFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Field field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool hasError;

  @override
  State<ImageFieldInput> createState() => _ImageFieldInputState();
}

class _ImageFieldInputState extends State<ImageFieldInput> {
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _images = _parseImages(widget.value);
  }

  @override
  void didUpdateWidget(covariant ImageFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _images = _parseImages(widget.value);
    }
  }

  List<String> _parseImages(dynamic value) {
    if (value == null || value.toString().isEmpty) return [];
    if (value is List) return value.cast<String>();
    try {
      final decoded = jsonDecode(value.toString());
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    // Single image path
    return [value.toString()];
  }

  void _emitChange() {
    widget.onChanged(jsonEncode(_images));
  }

  Future<void> _pickFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      for (final file in result.files) {
        if (file.path == null && file.bytes == null) continue;

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeName = file.name.replaceAll(RegExp(r'[^\w.\-]'), '_');
        final assetPath = 'assets/${timestamp}_$safeName';

        if (!kIsWeb && file.path != null) {
          // Native: copy file bytes
          final bytes = await File(file.path!).readAsBytes();
          await FileSystemInterop.writeBytes(assetPath, bytes);
        } else if (file.bytes != null) {
          // Web: use bytes directly
          await FileSystemInterop.writeBytes(assetPath, file.bytes!);
        }

        _images.add(assetPath);
      }

      setState(() {});
      _emitChange();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _addFromUrl() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
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

    if (url != null && url.isNotEmpty) {
      setState(() => _images.add(url));
      _emitChange();
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
    _emitChange();
  }

  Widget _buildImageWidget(String ref, {double? width, double? height}) {
    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      return Image.network(
        ref,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorIcon(width, height),
      );
    }
    // Local asset
    final absPath = FileSystemInterop.getAbsolutePath(ref);
    if (absPath != null && !kIsWeb) {
      return Image.file(
        File(absPath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorIcon(width, height),
      );
    }
    return _errorIcon(width, height);
  }

  Widget _errorIcon(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Row(
          children: [
            Text(
              widget.field.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: widget.hasError ? Colors.red.shade700 : null,
              ),
            ),
            if (widget.field.required)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const Spacer(),
            Text(
              '${_images.length} image${_images.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Image thumbnails
        if (_images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageWidget(
                        _images[index],
                        width: 100,
                        height: 100,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        if (_images.isNotEmpty) const SizedBox(height: 8),

        // Add buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromDevice,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(
                    color: widget.hasError
                        ? Colors.red
                        : AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addFromUrl,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('URL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(
                    color: widget.hasError
                        ? Colors.red
                        : AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
