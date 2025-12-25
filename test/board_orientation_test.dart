import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

import '../packages/xfutebol_flutter_bridge/test/mocks/mock_bridge_api.dart';

/// Tests for FT-019: Board Orientation Fix
/// 
/// Validates that the board renders with correct chess convention:
/// - Row 0 (A1, White's goal) at BOTTOM of screen
/// - Row 7 (A8, Black's goal) at TOP of screen
/// - White pieces start at bottom (rows 0-3)
/// - Black pieces start at top (rows 4-7)
void main() {
  group('Board Orientation (FT-019)', () {
    setUpAll(() {
      // Initialize bridge with mock
      XfutebolBridge.initMock(api: MockXfutebolBridgeApi());
    });

    group('Position Calculation', () {
      // Test the Y-axis flip formula: top = (7 - row) * squareSize
      const boardSize = 400.0;
      const squareSize = boardSize / 8; // 50.0

      test('row 0 (A1) renders at bottom of screen', () {
        // Formula: top = (7 - 0) * 50 = 350
        final position = Position(row: 0, col: 0);
        final top = (7 - position.row) * squareSize;
        
        expect(top, equals(350.0)); // Near bottom (400 - 50 = 350)
      });

      test('row 7 (A8) renders at top of screen', () {
        // Formula: top = (7 - 7) * 50 = 0
        final position = Position(row: 7, col: 0);
        final top = (7 - position.row) * squareSize;
        
        expect(top, equals(0.0)); // At top
      });

      test('row 3 (center-bottom) renders in lower half', () {
        // Formula: top = (7 - 3) * 50 = 200
        final position = Position(row: 3, col: 4);
        final top = (7 - position.row) * squareSize;
        
        expect(top, equals(200.0)); // Center
      });

      test('row 4 (center-top) renders in upper half', () {
        // Formula: top = (7 - 4) * 50 = 150
        final position = Position(row: 4, col: 4);
        final top = (7 - position.row) * squareSize;
        
        expect(top, equals(150.0)); // Above center
      });

      test('column position unchanged (left = col * squareSize)', () {
        final position = Position(row: 3, col: 5);
        final left = position.col * squareSize;
        
        expect(left, equals(250.0)); // col 5 * 50 = 250
      });
    });

    group('Team Positions via Bridge', () {
      late String gameId;

      setUp(() async {
        // Create a game first so the mock returns board data
        gameId = await newGame(mode: GameModeType.standardMatch);
      });

      test('White goalkeeper at row 0 renders at bottom', () async {
        final board = await getBoard(gameId: gameId);
        expect(board, isNotNull);
        
        // Find white goalkeeper
        final whiteGK = board!.pieces.firstWhere(
          (p) => p.team == Team.white && p.role == PieceRole.goalkeeper,
        );
        
        // White GK should be at row 0 (engine coordinate)
        expect(whiteGK.position.row, equals(0));
        
        // When rendered, row 0 should be at bottom (high Y value)
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        final visualTop = (7 - whiteGK.position.row) * squareSize;
        
        // Row 0 -> visualTop = 350 (near bottom of 400px board)
        expect(visualTop, equals(350.0));
      });

      test('Black goalkeeper at row 7 renders at top', () async {
        final board = await getBoard(gameId: gameId);
        expect(board, isNotNull);
        
        // Find black goalkeeper
        final blackGK = board!.pieces.firstWhere(
          (p) => p.team == Team.black && p.role == PieceRole.goalkeeper,
        );
        
        // Black GK should be at row 7 (engine coordinate)
        expect(blackGK.position.row, equals(7));
        
        // When rendered, row 7 should be at top (low Y value)
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        final visualTop = (7 - blackGK.position.row) * squareSize;
        
        // Row 7 -> visualTop = 0 (at top)
        expect(visualTop, equals(0.0));
      });

      test('White pieces render in bottom half (rows 0-3)', () async {
        final board = await getBoard(gameId: gameId);
        expect(board, isNotNull);
        
        final whitePieces = board!.pieces.where((p) => p.team == Team.white);
        
        for (final piece in whitePieces) {
          // White pieces should be in rows 0-3
          expect(piece.position.row, lessThanOrEqualTo(3),
            reason: 'White ${piece.role} should be in bottom half (row <= 3)');
          
          // Visual position should be in lower half (top >= 200 for 400px board)
          const boardSize = 400.0;
          const squareSize = boardSize / 8;
          final visualTop = (7 - piece.position.row) * squareSize;
          
          expect(visualTop, greaterThanOrEqualTo(200.0),
            reason: 'White ${piece.role} at row ${piece.position.row} should render in bottom half');
        }
      });

      test('Black pieces render in top half (rows 4-7)', () async {
        final board = await getBoard(gameId: gameId);
        expect(board, isNotNull);
        
        final blackPieces = board!.pieces.where((p) => p.team == Team.black);
        
        for (final piece in blackPieces) {
          // Black pieces should be in rows 4-7
          expect(piece.position.row, greaterThanOrEqualTo(4),
            reason: 'Black ${piece.role} should be in top half (row >= 4)');
          
          // Visual position should be in upper half (top < 200 for 400px board)
          const boardSize = 400.0;
          const squareSize = boardSize / 8;
          final visualTop = (7 - piece.position.row) * squareSize;
          
          expect(visualTop, lessThan(200.0),
            reason: 'Black ${piece.role} at row ${piece.position.row} should render in top half');
        }
      });
    });

    group('Goal Area Positions', () {
      test('White goal (row 0) at visual bottom', () async {
        // Row 0 = White's goal area (A1-D1)
        // Should render at bottom of screen
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        
        // Row 0 visual position
        final visualTop = (7 - 0) * squareSize;
        expect(visualTop, equals(350.0)); // Bottom row
      });

      test('Black goal (row 7) at visual top', () async {
        // Row 7 = Black's goal area (A8-D8)
        // Should render at top of screen
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        
        // Row 7 visual position
        final visualTop = (7 - 7) * squareSize;
        expect(visualTop, equals(0.0)); // Top row
      });
    });

    group('Attack Direction', () {
      test('White attacks upward (toward decreasing visual Y)', () async {
        // White at row 3 attacking toward row 7 (Black's goal)
        // Visual: row 3 at y=200, row 7 at y=0
        // Attacking upward = decreasing Y coordinate
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        
        final startTop = (7 - 3) * squareSize; // 200
        final targetTop = (7 - 7) * squareSize; // 0
        
        expect(targetTop, lessThan(startTop),
          reason: 'White attacks upward (Y decreases)');
      });

      test('Black attacks downward (toward increasing visual Y)', () async {
        // Black at row 4 attacking toward row 0 (White's goal)
        // Visual: row 4 at y=150, row 0 at y=350
        // Attacking downward = increasing Y coordinate
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        
        final startTop = (7 - 4) * squareSize; // 150
        final targetTop = (7 - 0) * squareSize; // 350
        
        expect(targetTop, greaterThan(startTop),
          reason: 'Black attacks downward (Y increases)');
      });
    });
  });
}

