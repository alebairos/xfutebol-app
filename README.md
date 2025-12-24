# Xfutebol App

A strategic soccer-themed board game built with Flutter and a Rust game engine.

## Architecture

```
xfutebol_app/          ← Flutter UI (this repo)
    │
    │ flutter_rust_bridge (FFI)
    │
    ▼
xfutebol-engine/       ← Rust game logic (separate repo)
```

## Prerequisites

### Required Tools

| Tool | Version | Install |
|------|---------|---------|
| Flutter | 3.x | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Rust | stable | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| flutter_rust_bridge_codegen | latest | `cargo install flutter_rust_bridge_codegen` |

### Verify Installation

```bash
flutter --version    # Should show 3.x
rustc --version      # Should show stable
flutter_rust_bridge_codegen --version
```

## Project Structure

```
xfutebol_app/
├── lib/
│   ├── main.dart              # App entry point
│   └── src/
│       ├── rust/              # Generated Rust bindings (DO NOT EDIT)
│       └── game/              # Game UI widgets
├── rust/
│   └── src/
│       └── api.rs             # Rust API exposed to Flutter
├── pubspec.yaml
└── flutter_rust_bridge.yaml   # Bridge configuration
```

## Setup

### 1. Clone and Setup

```bash
# Clone this repo
git clone <repo-url> xfutebol_app
cd xfutebol_app

# Ensure xfutebol-engine is at ../xfutebol-engine
# (sibling directory)
ls ../xfutebol-engine  # Should exist

# Install Flutter dependencies
flutter pub get
```

### 2. Install Rust Bridge Tools

```bash
# Install the code generator
cargo install flutter_rust_bridge_codegen

# Add required Rust targets for mobile
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim  # iOS
rustup target add aarch64-linux-android armv7-linux-androideabi             # Android
```

### 3. Generate Bindings

```bash
# Generate Dart bindings from Rust API
flutter_rust_bridge_codegen generate
```

### 4. Run the App

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Both (choose device)
flutter run
```

## Development Workflow

### When You Modify Rust API

If you change functions in `rust/src/api.rs`:

```bash
flutter_rust_bridge_codegen generate
flutter run
```

### When You Modify Flutter Only

Just run:

```bash
flutter run
# Hot reload with 'r' in terminal
```

## Rust API

The Rust engine exposes these functions to Flutter:

```rust
// rust/src/api.rs

/// Create a new game
pub fn new_game(mode: GameMode) -> GameState;

/// Get current board state
pub fn get_board(game: &GameState) -> BoardView;

/// Get legal moves for a piece
pub fn get_legal_moves(game: &GameState, piece_id: u8) -> Vec<Tile>;

/// Execute a player action
pub fn execute_action(game: &mut GameState, action: Action) -> ActionResult;

/// Get bot's move
pub fn get_bot_move(game: &GameState, difficulty: Difficulty) -> Action;
```

## Building for Release

### iOS

```bash
flutter build ios --release
# Then archive in Xcode
```

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Troubleshooting

### "Library not found" errors

```bash
# Regenerate bindings
flutter_rust_bridge_codegen generate

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Rust compilation errors

```bash
# Check Rust compiles standalone
cd ../xfutebol-engine
cargo build
```

### iOS Simulator issues

```bash
# Ensure correct target
rustup target add aarch64-apple-ios-sim
```

## Related Repositories

- **xfutebol-engine**: Rust game logic - `../xfutebol-engine`

## License

MIT
