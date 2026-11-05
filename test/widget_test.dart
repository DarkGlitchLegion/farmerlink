import 'package:farmerlink/features/onboarding/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FarmerLink splash displays its brand message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));

    expect(find.text('FarmerLink'), findsOneWidget);
    expect(
      find.text('From Farm to Table, Connecting Communities.'),
      findsOneWidget,
    );
    expect(find.text('MADE FOR FARMERS IN DAVAO DEL NORTE'), findsOneWidget);
  });
}
