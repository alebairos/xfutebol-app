/// Flutter bindings for the Xfutebol game engine.
///
/// This package provides Dart FFI bindings to the Rust game engine,
/// exposing types and functions for game state management, piece movement,
/// and bot AI.
///
/// ## Getting Started
///
/// Initialize the bridge before using any functions:
///
/// ```dart
/// import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';
///
/// void main() async {
///   await XfutebolBridge.init();
///   // Now you can use the API functions
/// }
/// ```
library;

// Export generated Rust bindings
export 'src/rust/api.dart';
export 'src/rust/frb_generated.dart' show XfutebolBridge;
