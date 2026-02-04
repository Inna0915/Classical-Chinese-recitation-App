// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in this test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read widget values, and verify that the values of widget properties
// are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guyun_reader/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GuYunReaderApp());

    // Verify that the app starts correctly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
