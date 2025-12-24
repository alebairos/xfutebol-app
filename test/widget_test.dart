// Unit tests for XfutebolApp.
//
// Note: Tests that require the Rust bridge must run as integration tests
// because the native library cannot be loaded in the Dart VM.
// See: integration_test/app_test.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder unit test', () {
    // Widget tests that need the Rust bridge should use integration tests.
    // Run with: flutter test integration_test/app_test.dart -d <device>
    expect(true, isTrue);
  });
}
