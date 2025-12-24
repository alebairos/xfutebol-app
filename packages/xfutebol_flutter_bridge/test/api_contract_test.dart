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

      test('has hard value', () {
        expect(Difficulty.hard, isNotNull);
      });

      test('has exactly 3 values', () {
        expect(Difficulty.values.length, equals(3));
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
          id: 5,
          team: Team.white,
          role: PieceRole.attacker,
          position: Position(row: 3, col: 3),
          hasBall: true,
        );
        expect(piece.id, equals(5));
        expect(piece.team, equals(Team.white));
        expect(piece.role, equals(PieceRole.attacker));
        expect(piece.position.row, equals(3));
        expect(piece.position.col, equals(3));
        expect(piece.hasBall, isTrue);
      });

      test('equality works for same values', () {
        final piece1 = PieceView(
          id: 0,
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        final piece2 = PieceView(
          id: 0,
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        expect(piece1, equals(piece2));
      });

      test('equality fails for different id', () {
        final piece1 = PieceView(
          id: 0,
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        final piece2 = PieceView(
          id: 1,
          team: Team.black,
          role: PieceRole.goalkeeper,
          position: Position(row: 7, col: 4),
          hasBall: false,
        );
        expect(piece1, isNot(equals(piece2)));
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
        );
        expect(result.success, isTrue);
        expect(result.message, equals('Move executed'));
        expect(result.gameOver, isFalse);
        expect(result.winner, isNull);
      });

      test('can include winner', () {
        final result = ActionResult(
          success: true,
          message: 'Goal scored!',
          gameOver: true,
          winner: Team.white,
        );
        expect(result.gameOver, isTrue);
        expect(result.winner, equals(Team.white));
      });

      test('equality works for same values', () {
        final result1 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
        );
        final result2 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
        );
        expect(result1, equals(result2));
      });

      test('equality fails for different success', () {
        final result1 = ActionResult(
          success: true,
          message: 'Test',
          gameOver: false,
        );
        final result2 = ActionResult(
          success: false,
          message: 'Test',
          gameOver: false,
        );
        expect(result1, isNot(equals(result2)));
      });
    });
  });
}

