// Integration test for XfutebolApp.
//
// This test runs on a real device/simulator with the actual Rust bridge.
//
// To run:
//   flutter test integration_test/app_test.dart -d <device_id>
//
// Or to run on macOS:
//   flutter test integration_test/app_test.dart -d macos

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

import 'package:xfutebol_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize the Rust bridge before running tests
    await XfutebolBridge.init();
  });

  testWidgets('XfutebolApp smoke test', (WidgetTester tester) async {
    // Build the app widget and trigger a frame.
    await tester.pumpWidget(const XfutebolApp());
    await tester.pumpAndSettle();

    // Verify the app builds without errors.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

