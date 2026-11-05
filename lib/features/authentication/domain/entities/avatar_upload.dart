import 'dart:typed_data';

class AvatarUpload {
  const AvatarUpload({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}
