import 'package:flutter_test/flutter_test.dart';
import 'package:xfutebol_flutter_bridge/src/rust/api.dart';

/// Tests for API type contracts.
/// These verify the generated Dart types match expected structure.
void main() {
  group('API Contract Tests', () {
    group('Team enum', () {
      test('has white value', () {
        expect(Team.white, isNotNull);
      });

      test('has black value', () {
        expect(Team.black, isNotNull);
      });

      test('has exactly 2 values', () {
        expect(Team.values.length, equals(2));
      });
    });

    group('PieceRole enum', () {
      test('has goalkeeper value', () {
        expect(PieceRole.goalkeeper, isNotNull);
      });

      test('has defender value', () {
        expect(PieceRole.defender, isNotNull);
      });

      test('has midfielder value', () {
        expect(PieceRole.midfielder, isNotNull);
      });

      test('has attacker value', () {
        expect(PieceRole.attacker, isNotNull);
      });

      test('has exactly 4 values', () {
        expect(PieceRole.values.length, equals(4));
      });
    });

    group('Difficulty enum', () {
      test('has easy value', () {
        expect(Difficulty.easy, isNotNull);
      });

      test('has medium value', () {
        expect(Difficulty.medium, isNotNull);
      });

      test('has exactly 2 values', () {
        // Note: Hard not yet implemented in engine
        expect(Difficulty.values.length, equals(2));
      });
    });

    group('GameModeType enum', () {
      test('has quickMatch value', () {
        expect(GameModeType.quickMatch, isNotNull);
      });

      test('has standardMatch value', () {
        expect(GameModeType.standardMatch, isNotNull);
      });

      test('has goldenGoal value', () {
        expect(GameModeType.goldenGoal, isNotNull);
      });

      test('has exactly 3 values', () {
        expect(GameModeType.values.length, equals(3));
      });
    });

    group('Position class', () {
      test('can be constructed with row and col', () {
        final pos = Position(row: 3, col: 5);
        expect(pos.row, equals(3));
        expect(pos.col, equals(5));
      });

      test('equality works for same values', () {
        final pos1 = Position(row: 2, col: 4);
        final pos2 = Position(row: 2, col: 4);
        expect(pos1, equals(pos2));
      });

      test('equality fails for different values', () {
        final pos1 = Position(row: 2, col: 4);
        final pos2 = Position(row: 2, col: 5);
        expect(pos1, isNot(equals(pos2)));
      });

      test('hashCode is consistent for equal objects', () {
        final pos1 = Position(row: 1, col: 1);
        final pos2 = Position(row: 1, col: 1);
        expect(pos1.hashCode, equals(pos2.hashCode));
      });
    });

    group('PieceView class', () {
      test('can be constructed with all required fields', () {
        final piece = PieceView(
          id: 'WA01',
          team: Team.white,
          role: PieceRole.attacker,
          position: Position(row: 3, col: 3),
          hasBall: true,
        );
        expect(piece.id, equals('WA01'));
        expect(piece.team, equals(Team.white));
        expect(piece.role, equals(PieceRole.attacker));
        expect(piece.position.row, equals(3));
        expect(piece.position.col, equals(3));
        expect(piece.hasBall, isTrue);
      });

      test('equality works for same values', () {
        final piece1 = PieceView(
          id: 'BG01',
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        final piece2 = PieceView(
          id: 'BG01',
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        expect(piece1, equals(piece2));
      });

      test('equality fails for different id', () {
        final piece1 = PieceView(
          id: 'BG01',
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        final piece2 = PieceView(
          id: 'WG01',
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        expect(piece1, isNot(equals(piece2)));
      });

      test('piece id uses engine format', () {
        // Engine piece ID format: [Team][Role][Number]
        // W/B = White/Black, G/D/M/A = Goalkeeper/Defender/Midfielder/Attacker
        final piece = PieceView(
          id: 'WM02',
          team: Team.white,
          role: PieceRole.midfielder,
          position: Position(row: 2, col: 5),
          hasBall: false,
        );
        expect(piece.id.length, greaterThanOrEqualTo(3));
        expect(piece.id, startsWith('W'));
      });
    });

    group('BoardView class', () {
      test('can be constructed with all required fields', () {
        final board = BoardView(
          pieces: [],
          currentTurn: Team.white,
          actionsRemaining: 2,
          whiteScore: 0,
          blackScore: 0,
          turnNumber: 1,
        );
        expect(board.pieces, isEmpty);
        expect(board.currentTurn, equals(Team.white));
        expect(board.actionsRemaining, equals(2));
        expect(board.whiteScore, equals(0));
        expect(board.blackScore, equals(0));
        expect(board.turnNumber, equals(1));
        expect(board.ballPosition, isNull);
      });

      test('ballPosition can be set', () {
        final board = BoardView(
          pieces: [],
          ballPosition: Position(row: 4, col: 4),
          currentTurn: Team.black,
          actionsRemaining: 1,
          whiteScore: 1,
          blackScore: 2,
          turnNumber: 15,
        );
        expect(board.ballPosition, isNotNull);
        expect(board.ballPosition!.row, equals(4));
        expect(board.ballPosition!.col, equals(4));
      });
    });

    group('ActionResult class', () {
      test('can be constructed with success result', () {
        final result = ActionResult(
          success: true,
          message: 'Move executed',
          gameOver: false,
          actionsRemaining: 1,
        );
        expect(result.success, isTrue);
        expect(result.message, equals('Move executed'));
        expect(result.gameOver, isFalse);
        expect(result.winner, isNull);
        expect(result.actionsRemaining, equals(1));
      });

      test('can include winner', () {
        final result = ActionResult(
          success: true,
          message: 'Goal scored!',
          gameOver: true,
          winner: Team.white,
          actionsRemaining: 0,
        );
        expect(result.gameOver, isTrue);
        expect(result.winner, equals(Team.white));
      });

      test('equality works for same values', () {
        final result1 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
          actionsRemaining: 2,
        );
        final result2 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
          actionsRemaining: 2,
        );
        expect(result1, equals(result2));
      });

      test('equality fails for different success', () {
        final result1 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
          actionsRemaining: 2,
        );
        final result2 = ActionResult(
          success: false,
          message: 'Test',
          gameOver: false,
          actionsRemaining: 2,
        );
        expect(result1, isNot(equals(result2)));
      });

      test('equality fails for different actionsRemaining', () {
        final result1 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
          actionsRemaining: 2,
        );
        final result2 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
          actionsRemaining: 1,
        );
        expect(result1, isNot(equals(result2)));
      });
    });

    group('ActionType enum', () {
      test('has move value', () {
        expect(ActionType.move, isNotNull);
      });

      test('has pass value', () {
        expect(ActionType.pass, isNotNull);
      });

      test('has shoot value', () {
        expect(ActionType.shoot, isNotNull);
      });

      test('has intercept value', () {
        expect(ActionType.intercept, isNotNull);
      });

      test('has exactly 7 values', () {
        expect(ActionType.values.length, equals(7));
      });

      test('has kick value', () {
        expect(ActionType.values, contains(ActionType.kick));
      });

      test('has defend value', () {
        expect(ActionType.values, contains(ActionType.defend));
      });

      test('has push value', () {
        expect(ActionType.values, contains(ActionType.push));
      });
    });

    group('BotAction class', () {
      test('can be constructed with all required fields', () {
        final action = BotAction(
          pieceId: 'WA01',
          actionType: ActionType.move,
          path: [Position(row: 4, col: 3)],
        );
        expect(action.pieceId, equals('WA01'));
        expect(action.actionType, equals(ActionType.move));
        expect(action.path.length, equals(1));
        expect(action.path[0].row, equals(4));
      });

      test('can have multiple positions in path', () {
        final action = BotAction(
          pieceId: 'WA01',
          actionType: ActionType.pass,
          path: [
            Position(row: 3, col: 3),
            Position(row: 4, col: 3),
            Position(row: 5, col: 3),
          ],
        );
        expect(action.path.length, equals(3));
      });

      test('equality requires same reference for path', () {
        // Note: Generated Dart classes use shallow list comparison
        // Two instances with identical paths are not equal unless paths share reference
        final action1 = BotAction(
          pieceId: 'WM01',
          actionType: ActionType.shoot,
          path: [Position(row: 7, col: 4)],
        );
        final action2 = BotAction(
          pieceId: 'WM01',
          actionType: ActionType.shoot,
          path: [Position(row: 7, col: 4)],
        );
        // Different path lists -> not equal (Dart list equality is by reference)
        expect(action1, isNot(equals(action2)));

        // Shared path -> equal
        final sharedPath = [Position(row: 7, col: 4)];
        final action3 = BotAction(
          pieceId: 'WM01',
          actionType: ActionType.shoot,
          path: sharedPath,
        );
        final action4 = BotAction(
          pieceId: 'WM01',
          actionType: ActionType.shoot,
          path: sharedPath,
        );
        expect(action3, equals(action4));
      });

      test('equality fails for different action type', () {
        final action1 = BotAction(
          pieceId: 'WM01',
          actionType: ActionType.move,
          path: [Position(row: 4, col: 4)],
        );
        final action2 = BotAction(
          pieceId: 'WM01',
          actionType: ActionType.pass,
          path: [Position(row: 4, col: 4)],
        );
        expect(action1, isNot(equals(action2)));
      });
    });

    group('PositionPath class', () {
      test('can be constructed with positions', () {
        final path = PositionPath(
          positions: [
            Position(row: 3, col: 3),
            Position(row: 4, col: 3),
            Position(row: 5, col: 3),
          ],
        );
        expect(path.positions.length, equals(3));
        expect(path.positions[0].row, equals(3));
      });

      test('equality requires same reference for positions', () {
        // Note: Generated Dart classes use shallow list comparison
        final path1 = PositionPath(
          positions: [Position(row: 1, col: 1), Position(row: 2, col: 2)],
        );
        final path2 = PositionPath(
          positions: [Position(row: 1, col: 1), Position(row: 2, col: 2)],
        );
        // Different position lists -> not equal (Dart list equality is by reference)
        expect(path1, isNot(equals(path2)));

        // Shared positions -> equal
        final sharedPositions = [
          Position(row: 1, col: 1),
          Position(row: 2, col: 2),
        ];
        final path3 = PositionPath(positions: sharedPositions);
        final path4 = PositionPath(positions: sharedPositions);
        expect(path3, equals(path4));
      });
    });
  });
}
