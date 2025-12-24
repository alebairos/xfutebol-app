import 'package:xfutebol_flutter_bridge/src/rust/api.dart';
import 'package:xfutebol_flutter_bridge/src/rust/frb_generated.dart';

/// Mock implementation of XfutebolBridgeApi for testing without FFI.
class MockXfutebolBridgeApi extends XfutebolBridgeApi {
  @override
  Future<String> crateApiNewGame({required GameModeType mode}) async {
    return 'mock_game_${mode.name}';
  }

  @override
  Future<BoardView> crateApiGetBoard({required String gameId}) async {
    return BoardView(
      pieces: _createMockPieces(),
      currentTurn: Team.white,
      actionsRemaining: 2,
      whiteScore: 0,
      blackScore: 0,
      turnNumber: 1,
    );
  }

  @override
  Future<List<Position>> crateApiGetLegalMoves({
    required String gameId,
    required int pieceId,
  }) async {
    return [
      Position(row: 3, col: 4),
      Position(row: 4, col: 3),
      Position(row: 4, col: 4),
    ];
  }

  @override
  Future<ActionResult> crateApiExecuteMove({
    required String gameId,
    required int pieceId,
    required Position to,
  }) async {
    return ActionResult(
      success: true,
      message: 'Mock move executed',
      gameOver: false,
    );
  }

  @override
  Future<(int, Position)?> crateApiGetBotMove({
    required String gameId,
    required Difficulty difficulty,
  }) async {
    return (7, Position(row: 5, col: 2));
  }

  @override
  Future<bool> crateApiIsGameOver({required String gameId}) async => false;

  @override
  Future<Team?> crateApiGetWinner({required String gameId}) async => null;

  @override
  Future<String> crateApiGreet({required String name}) async {
    return 'Hello, $name! Welcome to Xfutebol!';
  }

  /// Creates a mock set of 12 pieces for testing.
  List<PieceView> _createMockPieces() {
    return [
      // White team (6 pieces)
      PieceView(
        id: 0,
        team: Team.white,
        role: PieceRole.goalkeeper,
        position: Position(row: 0, col: 3),
        hasBall: false,
      ),
      PieceView(
        id: 1,
        team: Team.white,
        role: PieceRole.defender,
        position: Position(row: 1, col: 1),
        hasBall: false,
      ),
      PieceView(
        id: 2,
        team: Team.white,
        role: PieceRole.defender,
        position: Position(row: 1, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 3,
        team: Team.white,
        role: PieceRole.midfielder,
        position: Position(row: 2, col: 2),
        hasBall: false,
      ),
      PieceView(
        id: 4,
        team: Team.white,
        role: PieceRole.midfielder,
        position: Position(row: 2, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 5,
        team: Team.white,
        role: PieceRole.attacker,
        position: Position(row: 3, col: 3),
        hasBall: true, // Ball holder
      ),
      // Black team (6 pieces)
      PieceView(
        id: 6,
        team: Team.black,
        role: PieceRole.goalkeeper,
        position: Position(row: 7, col: 4),
        hasBall: false,
      ),
      PieceView(
        id: 7,
        team: Team.black,
        role: PieceRole.defender,
        position: Position(row: 6, col: 2),
        hasBall: false,
      ),
      PieceView(
        id: 8,
        team: Team.black,
        role: PieceRole.defender,
        position: Position(row: 6, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 9,
        team: Team.black,
        role: PieceRole.midfielder,
        position: Position(row: 5, col: 2),
        hasBall: false,
      ),
      PieceView(
        id: 10,
        team: Team.black,
        role: PieceRole.midfielder,
        position: Position(row: 5, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 11,
        team: Team.black,
        role: PieceRole.attacker,
        position: Position(row: 4, col: 4),
        hasBall: false,
      ),
    ];
  }
}

