// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dus_case_camp/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DusCaseCampApp());

    // Verify that the splash screen is displayed.
    // Since we don't know the exact content of SplashScreen, we just check if the app builds without crashing.
    // And maybe check for a widget that we know exists or just that it pumped successfully.
    // For now, just pumping the app is enough to verify it doesn't crash on start.
    expect(find.byType(DusCaseCampApp), findsOneWidget);
  });
}
