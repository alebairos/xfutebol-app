# xfutebol_flutter_bridge

Flutter bindings for the Xfutebol game engine.

## Overview

This package provides Dart FFI bindings to the Rust game engine via [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/). It exposes types and functions for:

- Game state management
- Piece movement and actions
- Bot AI
- Game mode configuration

## Usage

### Initialization

Initialize the bridge before using any functions:

```dart
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await XfutebolBridge.init();
  runApp(MyApp());
}
```

### Creating a Game

```dart
final gameId = await newGame(mode: GameModeType.standardMatch);
```

### Getting Board State

```dart
final board = await getBoard(gameId: gameId);
print('Turn: ${board.turnNumber}, Current: ${board.currentTurn}');
for (final piece in board.pieces) {
  print('Piece ${piece.id}: ${piece.role} at (${piece.position.row}, ${piece.position.col})');
}
```

### Making Moves

```dart
// Get legal moves for a piece
final moves = await getLegalMoves(gameId: gameId, pieceId: 5);

// Execute a move
final result = await executeMove(
  gameId: gameId,
  pieceId: 5,
  to: Position(row: 4, col: 3),
);

if (result.success) {
  print('Move executed: ${result.message}');
}
```

## Development

### Prerequisites

- Flutter SDK ^3.10.0
- Rust toolchain
- `flutter_rust_bridge_codegen` (`cargo install flutter_rust_bridge_codegen`)

### Regenerating Bindings

After modifying `rust/src/api.rs`:

```bash
cd packages/xfutebol_flutter_bridge
flutter_rust_bridge_codegen generate
```

### Engine Dependency

This package depends on `xfutebol-engine` via path reference. The engine repository should be cloned alongside `xfutebol-app`:

```
Projects/
├── xfutebol-engine/     # Rust game engine
└── xfutebol-app/
    └── packages/
        └── xfutebol_flutter_bridge/
```

## Testing

This package has comprehensive test coverage at multiple layers:

### Rust Unit Tests

Test the Rust logic without FFI:

```bash
cd packages/xfutebol_flutter_bridge/rust
cargo test
```

### Dart Unit Tests

Test Dart code with mocked FFI (fast, no device required):

```bash
cd packages/xfutebol_flutter_bridge
flutter test
```

### Integration Tests

Test the real FFI bridge (requires device/simulator):

```bash
# List available devices
flutter devices

# Run integration tests on a device
flutter test integration_test/bridge_integration_test.dart -d <device_id>
```

### Test Coverage

| Layer | Tests | What it Covers |
|-------|-------|----------------|
| Rust | 29 | API functions, board state, game logic |
| Dart Contract | 29 | Type definitions, equality, constructors |
| Dart Mocked | 28 | API behavior with mock FFI |
| Integration | 13 | Real FFI communication |

## API Reference

### Types

- `Team` - White or Black
- `PieceRole` - Goalkeeper, Defender, Midfielder, Attacker
- `Position` - Board coordinates (row, col)
- `PieceView` - Piece state for UI rendering
- `BoardView` - Complete board state
- `ActionResult` - Result of an action (move, pass, shoot)
- `GameModeType` - QuickMatch, StandardMatch, GoldenGoal
- `Difficulty` - Easy, Medium, Hard (for bot)

### Functions

- `newGame(mode)` - Create a new game
- `getBoard(gameId)` - Get current board state
- `getLegalMoves(gameId, pieceId)` - Get valid moves for a piece
- `executeMove(gameId, pieceId, to)` - Execute a move
- `getBotMove(gameId, difficulty)` - Get AI-suggested move
- `isGameOver(gameId)` - Check if game has ended
- `getWinner(gameId)` - Get winner (if game over)
- `greet(name)` - Test function to verify bridge works

## License

Proprietary - Xfutebol

