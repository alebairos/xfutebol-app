import 'package:flutter_test/flutter_test.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

import 'mocks/mock_bridge_api.dart';

void main() {
  group('xfutebol_flutter_bridge', () {
    setUpAll(() {
      // Initialize the bridge with mock API
      XfutebolBridge.initMock(api: MockXfutebolBridgeApi());
    });

    group('newGame', () {
      test('returns non-empty game ID', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        expect(gameId, isNotEmpty);
      });

      test('game ID contains mode name', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        expect(gameId, contains('standardMatch'));
      });

      test('different modes produce different IDs', () async {
        final quick = await newGame(mode: GameModeType.quickMatch);
        final standard = await newGame(mode: GameModeType.standardMatch);
        final golden = await newGame(mode: GameModeType.goldenGoal);

        expect(quick, contains('quickMatch'));
        expect(standard, contains('standardMatch'));
        expect(golden, contains('goldenGoal'));
      });
    });

    group('getBoard', () {
      test('returns BoardView with 14 pieces for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        expect(board, isNotNull);
        // Engine uses 14 pieces (7 per team)
        expect(board!.pieces.length, equals(14));
      });

      test('returns null for invalid game', () async {
        final board = await getBoard(gameId: 'invalid_game_id');
        expect(board, isNull);
      });

      test('has 7 white and 7 black pieces', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        expect(board, isNotNull);
        final whiteCount = board!.pieces
            .where((p) => p.team == Team.white)
            .length;
        final blackCount = board.pieces
            .where((p) => p.team == Team.black)
            .length;
        expect(whiteCount, equals(7));
        expect(blackCount, equals(7));
      });

      test('initial turn is white', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        expect(board!.currentTurn, equals(Team.white));
      });

      test('initial score is 0-0', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        expect(board!.whiteScore, equals(0));
        expect(board.blackScore, equals(0));
      });

      test('initial turn number is 1', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        expect(board!.turnNumber, equals(1));
      });

      test('has exactly one ball holder', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        final ballHolders = board!.pieces.where((p) => p.hasBall).toList();
        expect(ballHolders.length, equals(1));
      });

      test('ball holder is white attacker', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        final ballHolder = board!.pieces.firstWhere((p) => p.hasBall);
        expect(ballHolder.team, equals(Team.white));
        expect(ballHolder.role, equals(PieceRole.attacker));
      });

      test('piece IDs use engine format', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final board = await getBoard(gameId: gameId);
        // Engine piece IDs: "WG01", "BD02", etc.
        for (final piece in board!.pieces) {
          expect(piece.id, isA<String>());
          expect(piece.id.length, greaterThanOrEqualTo(3));
        }
      });
    });

    group('getLegalMoves', () {
      test('returns list of positions', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final moves = await getLegalMoves(gameId: gameId, pieceId: 'WA01');
        expect(moves, isNotEmpty);
      });

      test('positions have valid row values', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final moves = await getLegalMoves(gameId: gameId, pieceId: 'WA01');
        for (final pos in moves) {
          expect(pos.row, lessThan(8));
        }
      });

      test('positions have valid col values', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final moves = await getLegalMoves(gameId: gameId, pieceId: 'WA01');
        for (final pos in moves) {
          expect(pos.col, lessThan(8));
        }
      });

      test('returns empty for invalid game', () async {
        final moves = await getLegalMoves(gameId: 'invalid', pieceId: 'WA01');
        expect(moves, isEmpty);
      });
    });

    group('getLegalPasses', () {
      test('returns list of paths', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final passes = await getLegalPasses(gameId: gameId, pieceId: 'WA01');
        expect(passes, isNotEmpty);
      });

      test('each path contains positions', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final passes = await getLegalPasses(gameId: gameId, pieceId: 'WA01');
        for (final path in passes) {
          expect(path, isA<PositionPath>());
          expect(path.positions, isNotEmpty);
        }
      });

      test('returns empty for invalid game', () async {
        final passes = await getLegalPasses(gameId: 'invalid', pieceId: 'WA01');
        expect(passes, isEmpty);
      });
    });

    group('getLegalShoots', () {
      test('returns list of paths', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final shoots = await getLegalShoots(gameId: gameId, pieceId: 'WA01');
        expect(shoots, isA<List<PositionPath>>());
      });

      test('returns empty for invalid game', () async {
        final shoots = await getLegalShoots(gameId: 'invalid', pieceId: 'WA01');
        expect(shoots, isEmpty);
      });
    });

    group('executeMove', () {
      test('returns ActionResult', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executeMove(
          gameId: gameId,
          pieceId: 'WA01',
          to: Position(row: 4, col: 3),
        );
        expect(result, isA<ActionResult>());
      });

      test('result indicates success for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executeMove(
          gameId: gameId,
          pieceId: 'WA01',
          to: Position(row: 4, col: 3),
        );
        expect(result.success, isTrue);
      });

      test('result indicates failure for invalid game', () async {
        final result = await executeMove(
          gameId: 'invalid',
          pieceId: 'WA01',
          to: Position(row: 4, col: 3),
        );
        expect(result.success, isFalse);
        expect(result.message, contains('not found'));
      });

      test('result has non-empty message', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executeMove(
          gameId: gameId,
          pieceId: 'WA01',
          to: Position(row: 4, col: 3),
        );
        expect(result.message, isNotEmpty);
      });

      test('game is not over after move', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executeMove(
          gameId: gameId,
          pieceId: 'WA01',
          to: Position(row: 4, col: 3),
        );
        expect(result.gameOver, isFalse);
      });

      test('result includes actionsRemaining', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executeMove(
          gameId: gameId,
          pieceId: 'WA01',
          to: Position(row: 4, col: 3),
        );
        expect(result.actionsRemaining, greaterThanOrEqualTo(0));
      });
    });

    group('executePass', () {
      test('returns ActionResult', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executePass(
          gameId: gameId,
          pieceId: 'WA01',
          path: [Position(row: 4, col: 4)],
        );
        expect(result, isA<ActionResult>());
      });

      test('result indicates success for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executePass(
          gameId: gameId,
          pieceId: 'WA01',
          path: [Position(row: 4, col: 4)],
        );
        expect(result.success, isTrue);
      });

      test('result indicates failure for invalid game', () async {
        final result = await executePass(
          gameId: 'invalid',
          pieceId: 'WA01',
          path: [Position(row: 4, col: 4)],
        );
        expect(result.success, isFalse);
      });
    });

    group('executeShoot', () {
      test('returns ActionResult', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executeShoot(
          gameId: gameId,
          pieceId: 'WA01',
          path: [Position(row: 7, col: 4)],
        );
        expect(result, isA<ActionResult>());
      });

      test('result indicates success for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final result = await executeShoot(
          gameId: gameId,
          pieceId: 'WA01',
          path: [Position(row: 7, col: 4)],
        );
        expect(result.success, isTrue);
      });

      test('result indicates failure for invalid game', () async {
        final result = await executeShoot(
          gameId: 'invalid',
          pieceId: 'WA01',
          path: [Position(row: 7, col: 4)],
        );
        expect(result.success, isFalse);
      });
    });

    group('getBotMove', () {
      test('returns move tuple for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final move = await getBotMove(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(move, isNotNull);
      });

      test('returns null for invalid game', () async {
        final move = await getBotMove(
          gameId: 'invalid',
          difficulty: Difficulty.medium,
        );
        expect(move, isNull);
      });

      test('piece ID is a valid string', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final move = await getBotMove(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(move!.$1, isA<String>());
        expect(move.$1, isNotEmpty);
      });

      test('position has valid row', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final move = await getBotMove(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(move!.$2.row, lessThan(8));
      });

      test('position has valid col', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final move = await getBotMove(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(move!.$2.col, lessThan(8));
      });

      test('works with easy difficulty', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final move = await getBotMove(
          gameId: gameId,
          difficulty: Difficulty.easy,
        );
        expect(move, isNotNull);
      });

      test('works with medium difficulty', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final move = await getBotMove(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(move, isNotNull);
      });
    });

    group('getBotAction', () {
      test('returns BotAction for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final action = await getBotAction(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(action, isNotNull);
        expect(action, isA<BotAction>());
      });

      test('returns null for invalid game', () async {
        final action = await getBotAction(
          gameId: 'invalid',
          difficulty: Difficulty.medium,
        );
        expect(action, isNull);
      });

      test('has valid piece ID', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final action = await getBotAction(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(action!.pieceId, isNotEmpty);
      });

      test('has valid action type', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final action = await getBotAction(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(action!.actionType, isA<ActionType>());
      });

      test('has non-empty path', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final action = await getBotAction(
          gameId: gameId,
          difficulty: Difficulty.medium,
        );
        expect(action!.path, isNotEmpty);
      });
    });

    group('isGameOver', () {
      test('returns false for valid new game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final isOver = await isGameOver(gameId: gameId);
        expect(isOver, isFalse);
      });

      test('returns true for invalid game', () async {
        final isOver = await isGameOver(gameId: 'invalid');
        expect(isOver, isTrue);
      });
    });

    group('getWinner', () {
      test('returns null for new game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final winner = await getWinner(gameId: gameId);
        expect(winner, isNull);
      });
    });

    group('gameExists', () {
      test('returns true for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final exists = await gameExists(gameId: gameId);
        expect(exists, isTrue);
      });

      test('returns false for invalid game', () async {
        final exists = await gameExists(gameId: 'invalid');
        expect(exists, isFalse);
      });
    });

    group('deleteGame', () {
      test('returns true for valid game', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        final deleted = await deleteGame(gameId: gameId);
        expect(deleted, isTrue);
      });

      test('game no longer exists after deletion', () async {
        final gameId = await newGame(mode: GameModeType.standardMatch);
        await deleteGame(gameId: gameId);
        final exists = await gameExists(gameId: gameId);
        expect(exists, isFalse);
      });

      test('returns false for non-existent game', () async {
        final deleted = await deleteGame(gameId: 'non_existent');
        expect(deleted, isFalse);
      });
    });

    group('greet', () {
      test('returns personalized message', () async {
        final greeting = await greet(name: 'Alice');
        expect(greeting, contains('Alice'));
      });

      test('mentions Xfutebol', () async {
        final greeting = await greet(name: 'Test');
        expect(greeting, contains('Xfutebol'));
      });

      test('has correct format', () async {
        final greeting = await greet(name: 'Bob');
        expect(greeting, equals('Hello, Bob! Welcome to Xfutebol!'));
      });
    });
  });
}
