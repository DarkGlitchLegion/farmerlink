import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

/// Lets a user choose an image and returns the Base64 data URL expected by the API.
class ImageFilePickerField extends StatefulWidget {
  const ImageFilePickerField({
    super.key,
    required this.imageData,
    required this.onChanged,
    this.existingImage,
    this.label = 'Image',
    this.required = false,
  });

  final String? imageData;
  final String? existingImage;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool required;

  @override
  State<ImageFilePickerField> createState() => _ImageFilePickerFieldState();
}

class _ImageFilePickerFieldState extends State<ImageFilePickerField> {
  final ImagePicker _picker = ImagePicker();
  String? _error;

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType =
          file.mimeType ??
          switch (extension) {
            'png' => 'image/png',
            'jpg' || 'jpeg' => 'image/jpeg',
            'webp' => 'image/webp',
            'gif' => 'image/gif',
            _ => '',
          };
      if (!const {
        'image/png',
        'image/jpeg',
        'image/webp',
        'image/gif',
      }.contains(mimeType)) {
        setState(() => _error = 'Choose a PNG, JPEG, WebP, or GIF image.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        setState(() => _error = 'Choose an image no larger than 5 MiB.');
        return;
      }
      setState(() => _error = null);
      widget.onChanged('data:$mimeType;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open that image. Try another.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingImage = (widget.existingImage ?? '').isNotEmpty;
    final data = widget.imageData;
    final bytes = _decodeDataUrl(data);
    final hasImage = bytes != null || hasExistingImage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.label}${widget.required ? ' *' : ''}'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                if (bytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasExistingImage
                          ? Icons.image_outlined
                          : Icons.add_photo_alternate_outlined,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bytes != null
                        ? 'Image selected'
                        : hasExistingImage
                        ? 'An image is already saved'
                        : 'Choose an image from your files',
                  ),
                ),
                IconButton(
                  tooltip: hasImage ? 'Replace image' : 'Choose image',
                  onPressed: _pickImage,
                  icon: const Icon(Icons.folder_open_outlined),
                ),
                if (hasImage)
                  IconButton(
                    tooltip: 'Remove image',
                    onPressed: () {
                      setState(() => _error = null);
                      widget.onChanged(null);
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Uint8List? _decodeDataUrl(String? value) {
    if (value == null || !value.startsWith('data:image/')) return null;
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(value.substring(comma + 1));
    } on FormatException {
      return null;
    }
  }
}
