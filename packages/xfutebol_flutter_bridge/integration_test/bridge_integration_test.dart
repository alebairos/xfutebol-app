import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Integration tests for the Flutter-Rust bridge.
///
/// These tests require the Rust library to be compiled and run on a device
/// or simulator. They verify the actual FFI communication works correctly.
///
/// To run:
/// ```bash
/// flutter test integration_test/bridge_integration_test.dart -d <device_id>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize the real FFI bridge
    await XfutebolBridge.init();
  });

  group('FFI Bridge Integration', () {
    testWidgets('greet returns personalized message', (tester) async {
      final result = await greet(name: 'IntegrationTest');
      expect(result, contains('IntegrationTest'));
      expect(result, contains('Xfutebol'));
    });

    testWidgets('newGame creates valid game ID', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      expect(gameId, isNotEmpty);
      expect(gameId, contains('StandardMatch'));
    });

    testWidgets('getBoard returns 12 pieces', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = await getBoard(gameId: gameId);
      expect(board.pieces.length, equals(12));
    });

    testWidgets('getBoard has 6 white and 6 black pieces', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = await getBoard(gameId: gameId);

      final whiteCount =
          board.pieces.where((p) => p.team == Team.white).length;
      final blackCount =
          board.pieces.where((p) => p.team == Team.black).length;

      expect(whiteCount, equals(6));
      expect(blackCount, equals(6));
    });

    testWidgets('getBoard has one ball holder', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = await getBoard(gameId: gameId);

      final ballHolders = board.pieces.where((p) => p.hasBall).toList();
      expect(ballHolders.length, equals(1));
    });

    testWidgets('getLegalMoves returns positions', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final moves = await getLegalMoves(gameId: gameId, pieceId: 5);
      expect(moves, isNotEmpty);
    });

    testWidgets('executeMove returns success', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final moves = await getLegalMoves(gameId: gameId, pieceId: 5);

      if (moves.isNotEmpty) {
        final result = await executeMove(
          gameId: gameId,
          pieceId: 5,
          to: moves.first,
        );
        expect(result.success, isTrue);
        expect(result.message, isNotEmpty);
      }
    });

    testWidgets('getBotMove returns valid move', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final move = await getBotMove(
        gameId: gameId,
        difficulty: Difficulty.medium,
      );

      expect(move, isNotNull);
      expect(move!.$1, lessThan(12)); // Valid piece ID
      expect(move.$2.row, lessThan(8)); // Valid row
      expect(move.$2.col, lessThan(8)); // Valid col
    });

    testWidgets('isGameOver returns false initially', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final isOver = await isGameOver(gameId: gameId);
      expect(isOver, isFalse);
    });

    testWidgets('getWinner returns null initially', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final winner = await getWinner(gameId: gameId);
      expect(winner, isNull);
    });
  });

  group('Game Flow Integration', () {
    testWidgets('can create game and get board', (tester) async {
      // Create a new game
      final gameId = await newGame(mode: GameModeType.quickMatch);
      expect(gameId, isNotEmpty);

      // Get the board state
      final board = await getBoard(gameId: gameId);
      expect(board.pieces, isNotEmpty);
      expect(board.currentTurn, equals(Team.white));
      expect(board.turnNumber, equals(1));
    });

    testWidgets('can get moves and execute one', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = await getBoard(gameId: gameId);

      // Find a piece with the ball (should be piece 5 - white attacker)
      final ballHolder = board.pieces.firstWhere((p) => p.hasBall);
      expect(ballHolder.id, equals(5));

      // Get legal moves for this piece
      final moves = await getLegalMoves(
        gameId: gameId,
        pieceId: ballHolder.id,
      );
      expect(moves, isNotEmpty);

      // Execute a move
      final result = await executeMove(
        gameId: gameId,
        pieceId: ballHolder.id,
        to: moves.first,
      );
      expect(result.success, isTrue);
    });

    testWidgets('all game modes work', (tester) async {
      for (final mode in GameModeType.values) {
        final gameId = await newGame(mode: mode);
        expect(gameId, isNotEmpty);

        final board = await getBoard(gameId: gameId);
        expect(board.pieces.length, equals(12));
      }
    });

    testWidgets('all difficulty levels work', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);

      for (final difficulty in Difficulty.values) {
        final move = await getBotMove(
          gameId: gameId,
          difficulty: difficulty,
        );
        expect(move, isNotNull);
      }
    });
  });
}

