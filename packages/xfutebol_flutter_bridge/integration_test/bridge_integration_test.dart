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

    testWidgets('newGame creates valid UUID game ID', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      expect(gameId, isNotEmpty);
      // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
      expect(gameId.length, equals(36));
      expect(gameId, contains('-'));
    });

    testWidgets('getBoard returns 14 pieces', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;
      // Engine uses 14 pieces (7 per team)
      expect(board.pieces.length, equals(14));
    });

    testWidgets('getBoard has 7 white and 7 black pieces', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;

      final whiteCount = board.pieces.where((p) => p.team == Team.white).length;
      final blackCount = board.pieces.where((p) => p.team == Team.black).length;

      expect(whiteCount, equals(7));
      expect(blackCount, equals(7));
    });

    testWidgets('getBoard has one ball holder', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;

      final ballHolders = board.pieces.where((p) => p.hasBall).toList();
      expect(ballHolders.length, equals(1));
    });

    testWidgets('getLegalMoves returns positions', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;
      final ballHolder = board.pieces.firstWhere((p) => p.hasBall);

      final moves = await getLegalMoves(gameId: gameId, pieceId: ballHolder.id);
      expect(moves, isNotEmpty);
    });

    testWidgets('executeMove returns success', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;
      final ballHolder = board.pieces.firstWhere((p) => p.hasBall);

      final moves = await getLegalMoves(gameId: gameId, pieceId: ballHolder.id);

      if (moves.isNotEmpty) {
        final result = await executeMove(
          gameId: gameId,
          pieceId: ballHolder.id,
          to: moves.first,
        );
        expect(result.success, isTrue);
        expect(result.message, isNotEmpty);
      }
    });

    testWidgets('getBotMove returns valid move', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;
      final move = await getBotMove(
        gameId: gameId,
        difficulty: Difficulty.medium,
      );

      expect(move, isNotNull);
      // Piece ID is now a String (engine format: "WA01", etc.)
      expect(move!.$1, isA<String>());
      expect(move.$1, isNotEmpty);
      // Verify piece exists
      expect(board.pieces.any((p) => p.id == move.$1), isTrue);
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
      final board = (await getBoard(gameId: gameId))!;
      expect(board.pieces, isNotEmpty);
      expect(board.currentTurn, equals(Team.white));
      expect(board.actionsRemaining, equals(2));
    });

    testWidgets('can get moves and execute one', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;

      // Find a piece with the ball (should be white attacker)
      final ballHolder = board.pieces.firstWhere((p) => p.hasBall);
      expect(ballHolder.team, equals(Team.white));
      expect(ballHolder.role, equals(PieceRole.attacker));
      // ID is now a String in engine format
      expect(ballHolder.id, isA<String>());
      expect(ballHolder.id, isNotEmpty);

      // Get legal moves for this piece
      final moves = await getLegalMoves(gameId: gameId, pieceId: ballHolder.id);
      expect(moves, isNotEmpty);

      // Execute a move
      final result = await executeMove(
        gameId: gameId,
        pieceId: ballHolder.id,
        to: moves.first,
      );
      expect(result.success, isTrue);
      expect(result.actionsRemaining, equals(1));
    });

    testWidgets('all game modes work', (tester) async {
      for (final mode in GameModeType.values) {
        final gameId = await newGame(mode: mode);
        expect(gameId, isNotEmpty);

        final board = (await getBoard(gameId: gameId))!;
        // All modes use 14 pieces
        expect(board.pieces.length, equals(14));
      }
    });

    testWidgets('all difficulty levels work', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);

      for (final difficulty in Difficulty.values) {
        final move = await getBotMove(gameId: gameId, difficulty: difficulty);
        expect(move, isNotNull);
      }
    });

    testWidgets('full turn flow - two moves then turn switch', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);

      // Initial state
      var board = (await getBoard(gameId: gameId))!;
      expect(board.currentTurn, equals(Team.white));
      expect(board.actionsRemaining, equals(2));

      final ballHolder = board.pieces.firstWhere((p) => p.hasBall);

      // First move
      var moves = await getLegalMoves(gameId: gameId, pieceId: ballHolder.id);
      var result = await executeMove(
        gameId: gameId,
        pieceId: ballHolder.id,
        to: moves.first,
      );
      expect(result.success, isTrue);
      expect(result.actionsRemaining, equals(1));

      // Second move
      moves = await getLegalMoves(gameId: gameId, pieceId: ballHolder.id);
      result = await executeMove(
        gameId: gameId,
        pieceId: ballHolder.id,
        to: moves.first,
      );
      expect(result.success, isTrue);

      // After two moves, turn should switch to Black
      board = (await getBoard(gameId: gameId))!;
      expect(board.currentTurn, equals(Team.black));
      expect(board.actionsRemaining, equals(2));
    });

    testWidgets('piece IDs are in engine format', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;

      for (final piece in board.pieces) {
        // IDs should be at least 4 chars: "WG01", "BA02", etc.
        expect(piece.id.length, greaterThanOrEqualTo(4));

        // First char should match team
        final teamChar = piece.id[0];
        if (piece.team == Team.white) {
          expect(teamChar, equals('W'));
        } else {
          expect(teamChar, equals('B'));
        }

        // Second char should match role
        final roleChar = piece.id[1];
        switch (piece.role) {
          case PieceRole.goalkeeper:
            expect(roleChar, equals('G'));
            break;
          case PieceRole.defender:
            expect(roleChar, equals('D'));
            break;
          case PieceRole.midfielder:
            expect(roleChar, equals('M'));
            break;
          case PieceRole.attacker:
            expect(roleChar, equals('A'));
            break;
        }
      }
    });
  });

  group('Pass and Shoot Actions', () {
    testWidgets('executePass with valid path', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;
      final ballHolder = board.pieces.firstWhere((p) => p.hasBall);

      // Try a pass (may fail if no valid pass path, which is OK for this test)
      // We're just testing the API works, not the game logic
      final result = await executePass(
        gameId: gameId,
        pieceId: ballHolder.id,
        path: [Position(row: 4, col: 4)],
      );

      // Result should be valid (either success or failure with message)
      expect(result.message, isNotEmpty);
    });

    testWidgets('executeShoot with valid path', (tester) async {
      final gameId = await newGame(mode: GameModeType.standardMatch);
      final board = (await getBoard(gameId: gameId))!;
      final ballHolder = board.pieces.firstWhere((p) => p.hasBall);

      // Try a shoot (may fail if invalid path, which is OK for this test)
      final result = await executeShoot(
        gameId: gameId,
        pieceId: ballHolder.id,
        path: [Position(row: 7, col: 4)],
      );

      // Result should be valid (either success or failure with message)
      expect(result.message, isNotEmpty);
    });
  });
}
