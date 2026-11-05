import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class Base64ImagePreview extends StatelessWidget {
  const Base64ImagePreview({
    super.key,
    required this.data,
    this.label,
    this.height = 180,
  });

  final String? data;
  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = data?.trim() ?? '';
    if (value.isEmpty) return const SizedBox.shrink();

    final bytes = _decode(value);
    final Widget image = bytes != null
        ? Image.memory(
            bytes,
            width: double.infinity,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _unavailable(context),
          )
        : value.startsWith('http://') || value.startsWith('https://')
        ? Image.network(
            value,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _unavailable(context),
          )
        : _unavailable(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: height,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: image,
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decode(String value) {
    var encoded = value;
    if (value.startsWith('data:')) {
      final comma = value.indexOf(',');
      if (comma < 0 || !value.substring(0, comma).endsWith(';base64')) {
        return null;
      }
      encoded = value.substring(comma + 1);
    }
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  Widget _unavailable(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: Theme.of(context).hintColor),
        const SizedBox(height: 4),
        Text(
          'Image unavailable',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ],
    ),
  );
}
