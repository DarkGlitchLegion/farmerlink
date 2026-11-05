import 'package:farmerlink/core/widgets/base64_image_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Base64 image data as an image instead of text', (
    tester,
  ) async {
    const encoded = 'data:image/png;base64,iVBORw0KGgo=';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Base64ImagePreview(label: 'Image', data: encoded),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    expect(find.textContaining('base64'), findsNothing);
    expect(find.textContaining('iVBORw0KGgo='), findsNothing);
  });
}
