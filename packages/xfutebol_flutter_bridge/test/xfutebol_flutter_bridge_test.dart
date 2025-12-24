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
      test('returns BoardView with 12 pieces', () async {
        final board = await getBoard(gameId: 'test');
        expect(board.pieces.length, equals(12));
      });

      test('has 6 white and 6 black pieces', () async {
        final board = await getBoard(gameId: 'test');
        final whiteCount =
            board.pieces.where((p) => p.team == Team.white).length;
        final blackCount =
            board.pieces.where((p) => p.team == Team.black).length;
        expect(whiteCount, equals(6));
        expect(blackCount, equals(6));
      });

      test('initial turn is white', () async {
        final board = await getBoard(gameId: 'test');
        expect(board.currentTurn, equals(Team.white));
      });

      test('initial score is 0-0', () async {
        final board = await getBoard(gameId: 'test');
        expect(board.whiteScore, equals(0));
        expect(board.blackScore, equals(0));
      });

      test('initial turn number is 1', () async {
        final board = await getBoard(gameId: 'test');
        expect(board.turnNumber, equals(1));
      });

      test('has exactly one ball holder', () async {
        final board = await getBoard(gameId: 'test');
        final ballHolders = board.pieces.where((p) => p.hasBall).toList();
        expect(ballHolders.length, equals(1));
      });

      test('ball holder is white attacker', () async {
        final board = await getBoard(gameId: 'test');
        final ballHolder = board.pieces.firstWhere((p) => p.hasBall);
        expect(ballHolder.team, equals(Team.white));
        expect(ballHolder.role, equals(PieceRole.attacker));
      });
    });

    group('getLegalMoves', () {
      test('returns list of positions', () async {
        final moves = await getLegalMoves(gameId: 'test', pieceId: 5);
        expect(moves, isNotEmpty);
      });

      test('positions have valid row values', () async {
        final moves = await getLegalMoves(gameId: 'test', pieceId: 5);
        for (final pos in moves) {
          expect(pos.row, lessThan(8));
        }
      });

      test('positions have valid col values', () async {
        final moves = await getLegalMoves(gameId: 'test', pieceId: 5);
        for (final pos in moves) {
          expect(pos.col, lessThan(8));
        }
      });
    });

    group('executeMove', () {
      test('returns ActionResult', () async {
        final result = await executeMove(
          gameId: 'test',
          pieceId: 5,
          to: Position(row: 4, col: 3),
        );
        expect(result, isA<ActionResult>());
      });

      test('result indicates success', () async {
        final result = await executeMove(
          gameId: 'test',
          pieceId: 5,
          to: Position(row: 4, col: 3),
        );
        expect(result.success, isTrue);
      });

      test('result has non-empty message', () async {
        final result = await executeMove(
          gameId: 'test',
          pieceId: 5,
          to: Position(row: 4, col: 3),
        );
        expect(result.message, isNotEmpty);
      });

      test('game is not over after move', () async {
        final result = await executeMove(
          gameId: 'test',
          pieceId: 5,
          to: Position(row: 4, col: 3),
        );
        expect(result.gameOver, isFalse);
      });
    });

    group('getBotMove', () {
      test('returns move tuple', () async {
        final move = await getBotMove(
          gameId: 'test',
          difficulty: Difficulty.medium,
        );
        expect(move, isNotNull);
      });

      test('piece ID is within valid range', () async {
        final move = await getBotMove(
          gameId: 'test',
          difficulty: Difficulty.medium,
        );
        expect(move!.$1, lessThan(12));
      });

      test('position has valid row', () async {
        final move = await getBotMove(
          gameId: 'test',
          difficulty: Difficulty.medium,
        );
        expect(move!.$2.row, lessThan(8));
      });

      test('position has valid col', () async {
        final move = await getBotMove(
          gameId: 'test',
          difficulty: Difficulty.medium,
        );
        expect(move!.$2.col, lessThan(8));
      });

      test('works with easy difficulty', () async {
        final move = await getBotMove(
          gameId: 'test',
          difficulty: Difficulty.easy,
        );
        expect(move, isNotNull);
      });

      test('works with hard difficulty', () async {
        final move = await getBotMove(
          gameId: 'test',
          difficulty: Difficulty.hard,
        );
        expect(move, isNotNull);
      });
    });

    group('isGameOver', () {
      test('returns false for new game', () async {
        final isOver = await isGameOver(gameId: 'test');
        expect(isOver, isFalse);
      });
    });

    group('getWinner', () {
      test('returns null for new game', () async {
        final winner = await getWinner(gameId: 'test');
        expect(winner, isNull);
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
