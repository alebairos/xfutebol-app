# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-24

### Added

- Initial package structure
- Flutter Rust Bridge integration
- Core types: `Team`, `PieceRole`, `Position`, `PieceView`, `BoardView`, `ActionResult`
- Game lifecycle functions: `newGame`, `getBoard`, `isGameOver`, `getWinner`
- Action functions: `getLegalMoves`, `executeMove`
- Bot AI: `getBotMove`
- Test function: `greet`

### Testing (FT-010)

- 29 Rust unit tests covering API functions and board state
- 29 Dart API contract tests for type definitions
- 28 Dart unit tests with mock FFI
- 13 integration tests for real FFI communication
- Mock infrastructure: `MockXfutebolBridgeApi`

### Notes

- This is a placeholder API with stub implementations
- Actual game logic integration with xfutebol-engine pending

