# Feature Specification: Flutter UI Implementation

**Feature ID:** FT-015  
**Status:** Pending  
**Created:** December 24, 2025  
**Updated:** December 24, 2025  
**Priority:** High  
**Effort:** ~1-2 weeks  
**Dependencies:**  
- FT-014 (Complete Bridge Actions) ✅ COMPLETE

---

## Summary

Implement the Flutter UI for Xfutebol, enabling kids to play against the bot on mobile devices. This spec covers the 6 core UI components needed for Phase 1.

**Target Visual Style:** Clash Royale (2.5D isometric, cartoon characters)  
**Phase 1 Style:** 2D Lichess-inspired (for gameplay testing)

---

## Game Elements

### Pieces (14 total)

Xfutebol has **4 piece types** (soccer player roles), each team has 7 players:

| Role | Abbrev | Count per Team | Description |
|------|--------|----------------|-------------|
| **Goalkeeper** | GK | 1 | Defends the goal |
| **Defender** | DF | 2 | Defensive players |
| **Midfielder** | MF | 2 | Central players |
| **Attacker** | FW | 2 | Offensive players |

**Total:** 14 pieces (7 white + 7 black)

### The Ball (1)

The ball is **NOT a piece** - it's a separate game element:

| Property | Description |
|----------|-------------|
| **Location** | Either held by a piece (`PieceView.hasBall`) or at a position (`BoardView.ballPosition`) |
| **Held Ball** | Displayed as overlay on the piece holding it |
| **Loose Ball** | Displayed at `ballPosition` when no piece holds it (after interceptions, etc.) |

**Ball States:**

```
┌─────────────────────────────────────────────────────┐
│  Held by piece     │  piece.hasBall == true        │
│  (most common)     │  Ball overlaid on piece       │
├────────────────────┼───────────────────────────────┤
│  Loose ball        │  board.ballPosition != null   │
│  (after intercept) │  Ball rendered at position    │
└─────────────────────────────────────────────────────┘
```

**Ball Holder Actions:**
- **Pass** - Transfer ball to teammate along a path
- **Shoot** - Attempt to score a goal
- **Kick** - Clear the ball away (defensive)

### Visual Representation

| Element | Phase 1 (Dev) | Phase 2 (Final) |
|---------|---------------|-----------------|
| **Pieces** | Circles + Text (GK, DF, MF, FW) | Cartoon soccer player sprites |
| **Ball** | Small soccer ball icon | Animated soccer ball |
| **Ball Held** | Ball overlaid bottom-right of piece | Ball at player's feet |
| **Ball Loose** | Ball at grid position | Ball bouncing/rolling |

---

## Best Practices Review

### Flame Engine vs Widget Approach

| Aspect | Flame Engine | Widget/Stack Approach |
|--------|-------------|----------------------|
| Best for | Real-time games (60fps) | Turn-based games |
| Game loop | Built-in | Not needed |
| Learning curve | Steeper | Familiar Flutter |
| Examples | Shooters, platformers | Chess, Lichess |

**Decision:** ✅ Widget approach - Xfutebol is turn-based, no game loop needed.

### State Management

| Option | Pros | Cons |
|--------|------|------|
| ChangeNotifier | Simple | Hard to test, doesn't scale |
| **Riverpod** ✅ | Testable, composable, modern | Learning curve |
| BLoC | Battle-tested | Boilerplate |

**Decision:** ✅ Riverpod - Modern, testable, good for games.

### Performance Checklist

- [x] `const` constructors everywhere possible
- [x] `RepaintBoundary` to isolate board layers
- [x] `CustomPainter` for background (no rebuilds)
- [x] `ValueKey` for animated pieces
- [x] `shouldRepaint` implemented correctly

---

## Architecture Overview

### Package Structure

```
packages/
├── xfutebol_app/                      # Main Flutter app
│   ├── lib/
│   │   ├── main.dart                  # Entry point, bridge init
│   │   └── src/
│   │       ├── app/
│   │       │   ├── app.dart           # MaterialApp config
│   │       │   └── router.dart        # GoRouter (future)
│   │       ├── features/
│   │       │   └── game/
│   │       │       ├── presentation/
│   │       │       │   ├── screens/
│   │       │       │   │   └── game_screen.dart
│   │       │       │   └── widgets/
│   │       │       │       ├── board/
│   │       │       │       │   ├── xfutebol_board.dart
│   │       │       │       │   ├── board_background.dart
│   │       │       │       │   └── positioned_square.dart
│   │       │       │       ├── piece/
│   │       │       │       │   └── piece_widget.dart
│   │       │       │       ├── highlight/
│   │       │       │       │   └── highlights.dart
│   │       │       │       ├── hud/
│   │       │       │       │   └── game_hud.dart
│   │       │       │       └── dialogs/
│   │       │       │           └── win_dialog.dart
│   │       │       ├── providers/
│   │       │       │   ├── game_provider.dart      # Riverpod state
│   │       │       │   └── game_state.dart         # Immutable state
│   │       │       └── models/
│   │       │           └── ui_models.dart
│   │       └── shared/
│   │           ├── widgets/
│   │           └── utils/
│   │               └── board_geometry.dart
│   └── pubspec.yaml
│
├── xfutebol_flutter_bridge/           # Engine FFI (existing)
│
├── xfutebol_theme_interface/          # Theme contract
│   ├── lib/
│   │   └── theme_interface.dart
│   └── pubspec.yaml
│
└── xfutebol_theme_simple/             # Default theme (circles + text)
    ├── lib/
    │   └── simple_theme.dart
    └── pubspec.yaml
```

### Dependencies

```yaml
# xfutebol_app/pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Immutable models
  freezed_annotation: ^2.4.0
  
  # Internal packages
  xfutebol_flutter_bridge:
    path: ../xfutebol_flutter_bridge
  xfutebol_theme_interface:
    path: ../xfutebol_theme_interface
  xfutebol_theme_simple:
    path: ../xfutebol_theme_simple

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
  flutter_test:
    sdk: flutter
```

---

## Theme Package System

### Theme Interface Contract

```dart
// packages/xfutebol_theme_interface/lib/theme_interface.dart

import 'package:flutter/widgets.dart';

/// Contract that all Xfutebol themes must implement.
/// Allows easy swapping between simple dev theme and Clash Royale-style theme.
abstract class XfutebolTheme {
  /// Theme metadata
  String get id;
  String get name;
  String get author;
  
  /// Build a piece widget for the given team and role.
  /// 
  /// [team] - Team.white or Team.black
  /// [role] - One of the 4 piece roles:
  ///   - PieceRole.goalkeeper (GK) - 1 per team
  ///   - PieceRole.defender (DF) - 2 per team
  ///   - PieceRole.midfielder (MF) - 2 per team
  ///   - PieceRole.attacker (FW) - 2 per team
  /// [size] - square size in logical pixels
  /// [hasBall] - whether to show ball indicator
  /// [opacity] - for fade animations (0.0-1.0)
  Widget buildPiece({
    required Team team,
    required PieceRole role,
    required double size,
    bool hasBall = false,
    double opacity = 1.0,
  });
  
  /// Build standalone ball widget (for loose ball scenarios)
  Widget buildBall({required double size});
  
  /// Color scheme for board and highlights
  BoardColors get colors;
  
  /// Optional: custom board painter
  /// Return null to use default soccer field
  CustomPainter? buildBoardPainter(double squareSize) => null;
  
  /// Preload assets during splash screen
  Future<void> preloadAssets(BuildContext context) async {}
}

/// Immutable color scheme for the board
@immutable
class BoardColors {
  const BoardColors({
    required this.lightSquare,
    required this.darkSquare,
    required this.goalArea,
    required this.fieldLines,
    required this.selected,
    required this.lastMove,
    required this.validMove,
    required this.validCapture,
  });

  final Color lightSquare;
  final Color darkSquare;
  final Color goalArea;
  final Color fieldLines;
  final Color selected;
  final Color lastMove;
  final Color validMove;
  final Color validCapture;
  
  /// Default soccer green theme
  static const soccerGreen = BoardColors(
    lightSquare: Color(0xFF7CB342),
    darkSquare: Color(0xFF558B2F),
    goalArea: Color(0x30FFFFFF),
    fieldLines: Color(0x50FFFFFF),
    selected: Color(0x80FFD54F),
    lastMove: Color(0x809CC700),
    validMove: Color(0x40000000),
    validCapture: Color(0x40E53935),
  );
}
```

### Simple Theme Implementation

```dart
// packages/xfutebol_theme_simple/lib/simple_theme.dart

import 'package:flutter/material.dart';
import 'package:xfutebol_theme_interface/theme_interface.dart';

/// Simple theme using painted circles with role abbreviations.
/// Perfect for development and testing - no image assets needed.
/// 
/// Renders the 4 piece types as circles with text:
/// - GK (Goalkeeper) - 1 per team
/// - DF (Defender) - 2 per team  
/// - MF (Midfielder) - 2 per team
/// - FW (Attacker/Forward) - 2 per team
class SimpleTheme implements XfutebolTheme {
  const SimpleTheme();

  @override
  String get id => 'simple';
  
  @override
  String get name => 'Simple';
  
  @override
  String get author => 'Xfutebol Team';

  @override
  BoardColors get colors => BoardColors.soccerGreen;

  @override
  Widget buildPiece({
    required Team team,
    required PieceRole role,
    required double size,
    bool hasBall = false,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: _SimplePiece(
        team: team,
        role: role,
        size: size,
        hasBall: hasBall,
      ),
    );
  }

  @override
  Widget buildBall({required double size}) => _SoccerBall(size: size);
}

class _SimplePiece extends StatelessWidget {
  const _SimplePiece({
    required this.team,
    required this.role,
    required this.size,
    required this.hasBall,
  });

  final Team team;
  final PieceRole role;
  final double size;
  final bool hasBall;

  @override
  Widget build(BuildContext context) {
    final isWhite = team == Team.white;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          // Piece body
          Center(
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: isWhite ? Colors.white : const Color(0xFF2D2D2D),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWhite ? Colors.grey.shade400 : Colors.grey.shade700,
                  width: size * 0.04,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: size * 0.1,
                    offset: Offset(size * 0.02, size * 0.04),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _roleAbbreviation,
                  style: TextStyle(
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.bold,
                    color: isWhite ? Colors.grey.shade800 : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // Ball indicator
          if (hasBall)
            Positioned(
              right: size * 0.05,
              bottom: size * 0.05,
              child: _SoccerBall(size: size * 0.35),
            ),
        ],
      ),
    );
  }

  /// Maps PieceRole enum to display abbreviation
  String get _roleAbbreviation {
    switch (role) {
      case PieceRole.goalkeeper: return 'GK';
      case PieceRole.defender: return 'DF';
      case PieceRole.midfielder: return 'MF';
      case PieceRole.attacker: return 'FW';
    }
  }
}

class _SoccerBall extends StatelessWidget {
  const _SoccerBall({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87, width: size * 0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: size * 0.15,
            offset: Offset(size * 0.05, size * 0.08),
          ),
        ],
      ),
    );
  }
}
```

---

## State Management (Riverpod)

### Game State Model

```dart
// lib/src/features/game/providers/game_state.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

part 'game_state.freezed.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    required String? gameId,
    required BoardView? board,
    required String? selectedPieceId,
    required List<Position> legalMoves,
    required List<PositionPath> legalPasses,
    required List<PositionPath> legalShoots,
    required bool isLoading,
    required bool isBotThinking,
    required bool isGameOver,
    required Team? winner,
    required String? error,
    required ({Position from, Position to})? lastAction,
  }) = _GameState;

  factory GameState.initial() => const GameState(
    gameId: null,
    board: null,
    selectedPieceId: null,
    legalMoves: [],
    legalPasses: [],
    legalShoots: [],
    isLoading: false,
    isBotThinking: false,
    isGameOver: false,
    winner: null,
    error: null,
    lastAction: null,
  );
}
```

### Game Provider

```dart
// lib/src/features/game/providers/game_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';
import 'game_state.dart';

part 'game_provider.g.dart';

@riverpod
class Game extends _$Game {
  @override
  GameState build() => GameState.initial();

  /// Start a new game
  Future<void> startNewGame(GameModeType mode) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final gameId = await newGame(mode: mode);
      final board = await getBoard(gameId: gameId);
      
      if (board == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load game board',
        );
        return;
      }
      
      state = state.copyWith(
        gameId: gameId,
        board: board,
        isLoading: false,
        isGameOver: false,
        winner: null,
        lastAction: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start game: $e',
      );
    }
  }

  /// Select a piece and fetch legal actions
  Future<void> selectPiece(String pieceId) async {
    final gameId = state.gameId;
    final board = state.board;
    if (gameId == null || board == null) return;

    // Find the piece
    final piece = board.pieces.where((p) => p.id == pieceId).firstOrNull;
    if (piece == null) return;

    // Can only select current team's pieces
    if (piece.team != board.currentTurn) return;

    // Toggle selection
    if (state.selectedPieceId == pieceId) {
      _clearSelection();
      return;
    }

    try {
      // Fetch legal moves
      final moves = await getLegalMoves(gameId: gameId, pieceId: pieceId);
      
      // Fetch passes/shoots if has ball
      List<PositionPath> passes = [];
      List<PositionPath> shoots = [];
      
      if (piece.hasBall) {
        passes = await getLegalPasses(gameId: gameId, pieceId: pieceId);
        shoots = await getLegalShoots(gameId: gameId, pieceId: pieceId);
      }

      state = state.copyWith(
        selectedPieceId: pieceId,
        legalMoves: moves,
        legalPasses: passes,
        legalShoots: shoots,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to get legal moves: $e');
    }
  }

  /// Handle tap on a board square
  Future<void> handleSquareTap(Position position) async {
    if (state.isBotThinking) return; // Block input during bot turn
    
    if (state.selectedPieceId == null) {
      // Try to select piece at position
      final piece = state.board?.pieces.where(
        (p) => p.position == position,
      ).firstOrNull;
      
      if (piece != null) {
        await selectPiece(piece.id);
      }
      return;
    }

    // Check if position is a valid move
    if (state.legalMoves.contains(position)) {
      await _executeMove(position);
      return;
    }

    // Check if position is end of a pass path
    final passPath = _findPathEndingAt(state.legalPasses, position);
    if (passPath != null) {
      await _executePass(passPath);
      return;
    }

    // Check if position is end of a shoot path
    final shootPath = _findPathEndingAt(state.legalShoots, position);
    if (shootPath != null) {
      await _executeShoot(shootPath);
      return;
    }

    // Invalid tap - clear selection
    _clearSelection();
  }

  Future<void> _executeMove(Position to) async {
    final gameId = state.gameId!;
    final pieceId = state.selectedPieceId!;
    final fromPos = state.board!.pieces
        .firstWhere((p) => p.id == pieceId)
        .position;

    try {
      final result = await executeMove(
        gameId: gameId,
        pieceId: pieceId,
        to: to,
      );
      await _handleActionResult(result, fromPos, to);
    } catch (e) {
      state = state.copyWith(error: 'Move failed: $e');
      _clearSelection();
    }
  }

  Future<void> _executePass(List<Position> path) async {
    final gameId = state.gameId!;
    final pieceId = state.selectedPieceId!;
    final fromPos = path.first;
    final toPos = path.last;

    try {
      final result = await executePass(
        gameId: gameId,
        pieceId: pieceId,
        path: path,
      );
      await _handleActionResult(result, fromPos, toPos);
    } catch (e) {
      state = state.copyWith(error: 'Pass failed: $e');
      _clearSelection();
    }
  }

  Future<void> _executeShoot(List<Position> path) async {
    final gameId = state.gameId!;
    final pieceId = state.selectedPieceId!;
    final fromPos = path.first;
    final toPos = path.last;

    try {
      final result = await executeShoot(
        gameId: gameId,
        pieceId: pieceId,
        path: path,
      );
      await _handleActionResult(result, fromPos, toPos);
    } catch (e) {
      state = state.copyWith(error: 'Shoot failed: $e');
      _clearSelection();
    }
  }

  Future<void> _handleActionResult(
    ActionResult result,
    Position from,
    Position to,
  ) async {
    _clearSelection();

    if (!result.success) {
      state = state.copyWith(error: result.message);
      return;
    }

    // Refresh board
    final board = await getBoard(gameId: state.gameId!);
    
    state = state.copyWith(
      board: board,
      lastAction: (from: from, to: to),
    );

    // Check game over
    if (result.gameOver) {
      state = state.copyWith(
        isGameOver: true,
        winner: result.winner,
      );
      return;
    }

    // Check if it's bot's turn
    if (board?.currentTurn == Team.black) {
      await _executeBotTurn();
    }
  }

  Future<void> _executeBotTurn() async {
    state = state.copyWith(isBotThinking: true);

    while (state.board?.currentTurn == Team.black && !state.isGameOver) {
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final botAction = await getBotAction(
          gameId: state.gameId!,
          difficulty: Difficulty.medium,
        );

        if (botAction == null) break;

        // Highlight bot's piece briefly
        state = state.copyWith(selectedPieceId: botAction.pieceId);
        await Future.delayed(const Duration(milliseconds: 300));

        // Execute bot action
        final result = await _executeBotAction(botAction);
        
        _clearSelection();
        
        final board = await getBoard(gameId: state.gameId!);
        state = state.copyWith(board: board);

        if (result.gameOver) {
          state = state.copyWith(
            isGameOver: true,
            winner: result.winner,
          );
          break;
        }

        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        state = state.copyWith(error: 'Bot error: $e');
        break;
      }
    }

    state = state.copyWith(isBotThinking: false);
  }

  Future<ActionResult> _executeBotAction(BotAction action) async {
    switch (action.actionType) {
      case ActionType.move:
        return executeMove(
          gameId: state.gameId!,
          pieceId: action.pieceId,
          to: action.path.last,
        );
      case ActionType.pass:
        return executePass(
          gameId: state.gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
      case ActionType.shoot:
        return executeShoot(
          gameId: state.gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
      default:
        return executeMove(
          gameId: state.gameId!,
          pieceId: action.pieceId,
          to: action.path.last,
        );
    }
  }

  void _clearSelection() {
    state = state.copyWith(
      selectedPieceId: null,
      legalMoves: [],
      legalPasses: [],
      legalShoots: [],
    );
  }

  List<Position>? _findPathEndingAt(List<PositionPath> paths, Position target) {
    for (final path in paths) {
      if (path.positions.isNotEmpty && path.positions.last == target) {
        return path.positions;
      }
    }
    return null;
  }
}
```

---

## Board Widget (with RepaintBoundary)

```dart
// lib/src/features/game/presentation/widgets/board/xfutebol_board.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';
import 'package:xfutebol_theme_interface/theme_interface.dart';

import '../../../shared/utils/board_geometry.dart';
import 'board_background.dart';
import 'positioned_square.dart';
import '../highlight/highlights.dart';

class XfutebolBoard extends ConsumerWidget with BoardGeometry {
  const XfutebolBoard({
    super.key,
    required this.size,
    required this.board,
    required this.theme,
    required this.onSquareTap,
    this.selectedPieceId,
    this.legalMoves = const [],
    this.lastAction,
  });

  @override
  final double size;
  final BoardView board;
  final XfutebolTheme theme;
  final String? selectedPieceId;
  final List<Position> legalMoves;
  final ({Position from, Position to})? lastAction;
  final void Function(Position) onSquareTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = theme.colors;

    return Listener(
      onPointerDown: (event) {
        final pos = offsetToPosition(event.localPosition);
        if (pos != null) onSquareTap(pos);
      },
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            // Layer 1: Background (isolated - rarely changes)
            RepaintBoundary(
              child: CustomPaint(
                size: Size.square(size),
                painter: theme.buildBoardPainter(squareSize) ??
                    FieldBackgroundPainter(colors: colors),
              ),
            ),
            
            // Layer 2: Highlights (isolated - changes on selection)
            RepaintBoundary(
              child: Stack(
                children: _buildHighlights(colors),
              ),
            ),
            
            // Layer 3: Pieces
            ..._buildPieces(),
            
            // Layer 4: Loose ball (if not held by any piece)
            if (_looseBallPosition != null)
              PositionedSquare(
                key: const ValueKey('loose-ball'),
                size: size,
                position: _looseBallPosition!,
                child: Center(
                  child: theme.buildBall(size: squareSize * 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Returns ball position if ball is loose (not held by any piece)
  Position? get _looseBallPosition {
    // If any piece has the ball, it's not loose
    if (board.pieces.any((p) => p.hasBall)) return null;
    // Otherwise return the board's ball position
    return board.ballPosition;
  }

  List<Widget> _buildHighlights(BoardColors colors) {
    final highlights = <Widget>[];

    // Last action highlight
    if (lastAction != null) {
      highlights.add(PositionedSquare(
        size: size,
        position: lastAction!.from,
        child: SquareHighlight(color: colors.lastMove),
      ));
      highlights.add(PositionedSquare(
        size: size,
        position: lastAction!.to,
        child: SquareHighlight(color: colors.lastMove),
      ));
    }

    // Selected piece highlight
    if (selectedPieceId != null) {
      final piece = board.pieces.where((p) => p.id == selectedPieceId).firstOrNull;
      if (piece != null) {
        highlights.add(PositionedSquare(
          size: size,
          position: piece.position,
          child: SquareHighlight(color: colors.selected),
        ));
      }
    }

    // Legal move highlights
    for (final pos in legalMoves) {
      final isOccupied = board.pieces.any((p) => p.position == pos);
      highlights.add(PositionedSquare(
        size: size,
        position: pos,
        child: ValidMoveHighlight(
          size: squareSize,
          color: isOccupied ? colors.validCapture : colors.validMove,
          occupied: isOccupied,
        ),
      ));
    }

    return highlights;
  }

  List<Widget> _buildPieces() {
    return board.pieces.map((piece) {
      return PositionedSquare(
        key: ValueKey('piece-${piece.id}'),
        size: size,
        position: piece.position,
        child: theme.buildPiece(
          team: piece.team,
          role: piece.role,
          size: squareSize,
          hasBall: piece.hasBall,
        ),
      );
    }).toList();
  }
}
```

---

## Board Geometry Mixin

```dart
// lib/src/shared/utils/board_geometry.dart

import 'package:flutter/widgets.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Mixin providing board geometry calculations.
/// Inspired by Lichess chessground geometry.dart
mixin BoardGeometry {
  /// Visual size of the board (width = height)
  double get size;

  /// Size of a single square
  double get squareSize => size / 8;

  /// Convert board position to screen offset
  Offset positionToOffset(Position pos) {
    return Offset(pos.col * squareSize, pos.row * squareSize);
  }

  /// Convert screen offset to board position
  /// Returns null if outside the board
  Position? offsetToPosition(Offset offset) {
    final col = (offset.dx / squareSize).floor();
    final row = (offset.dy / squareSize).floor();
    if (row >= 0 && row < 8 && col >= 0 && col < 8) {
      return Position(row: row, col: col);
    }
    return null;
  }
}
```

---

## Game Screen

```dart
// lib/src/features/game/presentation/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';
import 'package:xfutebol_theme_simple/simple_theme.dart';

import '../../providers/game_provider.dart';
import '../widgets/board/xfutebol_board.dart';
import '../widgets/hud/game_hud.dart';
import '../widgets/dialogs/win_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _theme = const SimpleTheme();

  @override
  void initState() {
    super.initState();
    // Start a new game on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).startNewGame(GameModeType.standardMatch);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    // Loading state
    if (gameState.isLoading || gameState.board == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF2E7D32),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Error state
    if (gameState.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E7D32),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gameState.error!,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(gameProvider.notifier)
                    .startNewGame(GameModeType.standardMatch),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // HUD
                GameHud(
                  board: gameState.board!,
                  isBotThinking: gameState.isBotThinking,
                  onNewGame: () => ref.read(gameProvider.notifier)
                      .startNewGame(GameModeType.standardMatch),
                ),
                
                // Board
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boardSize = constraints.maxWidth < constraints.maxHeight
                            ? constraints.maxWidth - 16
                            : constraints.maxHeight - 16;
                        
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: XfutebolBoard(
                            size: boardSize,
                            board: gameState.board!,
                            theme: _theme,
                            selectedPieceId: gameState.selectedPieceId,
                            legalMoves: gameState.legalMoves,
                            lastAction: gameState.lastAction,
                            onSquareTap: (pos) => ref.read(gameProvider.notifier)
                                .handleSquareTap(pos),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // Win dialog overlay
            if (gameState.isGameOver)
              WinDialog(
                winner: gameState.winner,
                whiteScore: gameState.board!.whiteScore,
                blackScore: gameState.board!.blackScore,
                onPlayAgain: () => ref.read(gameProvider.notifier)
                    .startNewGame(GameModeType.standardMatch),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Implementation Steps

### Step 1: Create Theme Packages
- [ ] Create `xfutebol_theme_interface` package
- [ ] Create `xfutebol_theme_simple` package
- [ ] Test theme rendering

### Step 2: Board Widget
- [ ] Implement `BoardGeometry` mixin
- [ ] Implement `PositionedSquare` widget
- [ ] Implement `FieldBackgroundPainter`
- [ ] Implement `XfutebolBoard` with RepaintBoundary
- [ ] Implement highlight widgets

### Step 3: State Management
- [ ] Add Riverpod dependencies
- [ ] Create `GameState` with Freezed
- [ ] Create `GameProvider` with Riverpod
- [ ] Add error handling

### Step 4: Game Screen
- [ ] Create `GameScreen` with Riverpod Consumer
- [ ] Create `GameHud` widget
- [ ] Create `WinDialog` widget

### Step 5: Integration
- [ ] Update `main.dart` with ProviderScope
- [ ] Initialize bridge
- [ ] Test full game flow

### Step 6: Testing
- [ ] Provider unit tests
- [ ] Widget tests
- [ ] Integration tests

---

## Testing Strategy

### Provider Tests

```dart
void main() {
  group('GameProvider', () {
    test('startNewGame creates game and loads board', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      await container.read(gameProvider.notifier).startNewGame(
        GameModeType.standardMatch,
      );
      
      final state = container.read(gameProvider);
      expect(state.gameId, isNotNull);
      expect(state.board, isNotNull);
      expect(state.board!.pieces.length, equals(14));
    });

    test('selectPiece fetches legal moves', () async {
      // ...
    });

    test('cannot select opponent piece', () async {
      // ...
    });
  });
}
```

### Widget Tests

```dart
testWidgets('XfutebolBoard renders 14 pieces', (tester) async {
  final board = _createMockBoard();
  
  await tester.pumpWidget(
    MaterialApp(
      home: XfutebolBoard(
        size: 400,
        board: board,
        theme: const SimpleTheme(),
        onSquareTap: (_) {},
      ),
    ),
  );
  
  // Verify pieces are rendered
  // ...
});
```

---

## Checklist

### Theme Packages
- [ ] `xfutebol_theme_interface` created
- [ ] `XfutebolTheme` contract defined
- [ ] `BoardColors` defined
- [ ] `xfutebol_theme_simple` created
- [ ] `SimpleTheme` implemented

### Board Widget
- [ ] `BoardGeometry` mixin
- [ ] `PositionedSquare` widget
- [ ] `FieldBackgroundPainter` with `shouldRepaint`
- [ ] `XfutebolBoard` with `RepaintBoundary`
- [ ] `SquareHighlight` widget
- [ ] `ValidMoveHighlight` widget

### State Management
- [ ] Riverpod dependencies added
- [ ] `GameState` with Freezed
- [ ] `GameProvider` with error handling
- [ ] Bot turn logic

### UI Components
- [ ] `GameScreen` with loading/error states
- [ ] `GameHud` widget
- [ ] `WinDialog` widget

### Testing
- [ ] Provider unit tests
- [ ] Widget tests
- [ ] Integration tests

---

## References

### Lichess Chessground (Primary Inspiration)

- **Repository:** https://github.com/lichess-org/flutter-chessground
- **Local Clone:** `/Users/alebairos/Projects/chess/flutter-chessground`
- **Key Files:**
  - `lib/src/widgets/board.dart` - Stack composition
  - `lib/src/widgets/geometry.dart` - Coordinate mixin
  - `lib/src/board_settings.dart` - Immutable settings

### Flutter Best Practices

- Riverpod documentation: https://riverpod.dev
- Freezed for immutable models: https://pub.dev/packages/freezed
- Flutter performance: https://docs.flutter.dev/perf

### Project Documentation

- [FT-014: Complete Bridge Actions](./ft_014_complete_bridge_actions.md)
- [FT-013: Bridge API Readiness](./ft_013_bridge_api_readiness.md)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2025-12-24 | Initial specification |
| 0.2.0 | 2025-12-24 | Added Lichess patterns |
| 0.3.0 | 2025-12-24 | Best practices review: Riverpod, theme packages, RepaintBoundary, error handling |
| 0.3.1 | 2025-12-24 | Added Game Pieces section: 4 soccer roles (GK, DF, MF, FW), use enums not strings |
| 0.3.2 | 2025-12-24 | Clarified ball is separate from pieces: held ball vs loose ball, added loose ball rendering |
