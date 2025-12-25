import 'package:xfutebol_flutter_bridge/src/rust/api.dart';
import 'package:xfutebol_flutter_bridge/src/rust/frb_generated.dart';

/// Mock implementation of XfutebolBridgeApi for testing without FFI.
class MockXfutebolBridgeApi extends XfutebolBridgeApi {
  final Set<String> _games = {};

  @override
  Future<String> crateApiNewGame({required GameModeType mode}) async {
    final id = 'mock_game_${mode.name}_${_games.length}';
    _games.add(id);
    return id;
  }

  @override
  Future<BoardView?> crateApiGetBoard({required String gameId}) async {
    if (!_games.contains(gameId)) return null;
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
    required String pieceId,
  }) async {
    if (!_games.contains(gameId)) return [];
    return [
      Position(row: 3, col: 4),
      Position(row: 4, col: 3),
      Position(row: 4, col: 4),
    ];
  }

  @override
  Future<List<PositionPath>> crateApiGetLegalPasses({
    required String gameId,
    required String pieceId,
  }) async {
    if (!_games.contains(gameId)) return [];
    return [
      PositionPath(
        positions: [Position(row: 2, col: 2), Position(row: 2, col: 5)],
      ),
      PositionPath(positions: [Position(row: 3, col: 4)]),
    ];
  }

  @override
  Future<List<PositionPath>> crateApiGetLegalShoots({
    required String gameId,
    required String pieceId,
  }) async {
    if (!_games.contains(gameId)) return [];
    return [
      PositionPath(
        positions: [
          Position(row: 5, col: 3),
          Position(row: 6, col: 3),
          Position(row: 7, col: 3),
        ],
      ),
    ];
  }

  @override
  Future<List<PositionPath>> crateApiGetLegalIntercepts({
    required String gameId,
    required String pieceId,
  }) async {
    if (!_games.contains(gameId)) return [];
    return [
      PositionPath(positions: [Position(row: 4, col: 4)]),
    ];
  }

  @override
  Future<List<PositionPath>> crateApiGetLegalKicks({
    required String gameId,
    required String pieceId,
  }) async {
    if (!_games.contains(gameId)) return [];
    return [
      PositionPath(
        positions: [Position(row: 5, col: 3), Position(row: 6, col: 3)],
      ),
    ];
  }

  @override
  Future<List<PositionPath>> crateApiGetLegalDefends({
    required String gameId,
    required String pieceId,
  }) async {
    if (!_games.contains(gameId)) return [];
    return [
      PositionPath(positions: [Position(row: 5, col: 4)]),
    ];
  }

  @override
  Future<List<PositionPath>> crateApiGetLegalPushes({
    required String gameId,
    required String pieceId,
  }) async {
    if (!_games.contains(gameId)) return [];
    return [
      PositionPath(
        positions: [Position(row: 4, col: 4), Position(row: 4, col: 5)],
      ),
    ];
  }

  @override
  Future<ActionResult> crateApiExecuteMove({
    required String gameId,
    required String pieceId,
    required Position to,
  }) async {
    if (!_games.contains(gameId)) {
      return ActionResult(
        success: false,
        message: 'Game not found',
        gameOver: false,
        actionsRemaining: 0,
        turnEnded: false,
      );
    }
    return ActionResult(
      success: true,
      message: 'Mock move executed',
      gameOver: false,
      actionsRemaining: 1,
      turnEnded: false,
    );
  }

  @override
  Future<ActionResult> crateApiExecutePass({
    required String gameId,
    required String pieceId,
    required List<Position> path,
  }) async {
    if (!_games.contains(gameId)) {
      return ActionResult(
        success: false,
        message: 'Game not found',
        gameOver: false,
        actionsRemaining: 0,
        turnEnded: false,
      );
    }
    return ActionResult(
      success: true,
      message: 'Mock pass executed',
      gameOver: false,
      actionsRemaining: 1,
      turnEnded: false,
    );
  }

  @override
  Future<ActionResult> crateApiExecuteShoot({
    required String gameId,
    required String pieceId,
    required List<Position> path,
  }) async {
    if (!_games.contains(gameId)) {
      return ActionResult(
        success: false,
        message: 'Game not found',
        gameOver: false,
        actionsRemaining: 0,
        turnEnded: false,
      );
    }
    return ActionResult(
      success: true,
      message: 'Mock shoot executed',
      gameOver: false,
      actionsRemaining: 0,
      turnEnded: true,
    );
  }

  @override
  Future<ActionResult> crateApiExecuteIntercept({
    required String gameId,
    required String pieceId,
    required List<Position> path,
  }) async {
    if (!_games.contains(gameId)) {
      return ActionResult(
        success: false,
        message: 'Game not found',
        gameOver: false,
        actionsRemaining: 0,
        turnEnded: false,
      );
    }
    return ActionResult(
      success: true,
      message: 'Mock intercept executed',
      gameOver: false,
      actionsRemaining: 1,
      turnEnded: false,
    );
  }

  @override
  Future<ActionResult> crateApiExecuteKick({
    required String gameId,
    required String pieceId,
    required List<Position> path,
  }) async {
    if (!_games.contains(gameId)) {
      return ActionResult(
        success: false,
        message: 'Game not found',
        gameOver: false,
        actionsRemaining: 0,
        turnEnded: false,
      );
    }
    return ActionResult(
      success: true,
      message: 'Mock kick executed',
      gameOver: false,
      actionsRemaining: 1,
      turnEnded: false,
    );
  }

  @override
  Future<ActionResult> crateApiExecuteDefend({
    required String gameId,
    required String pieceId,
    required List<Position> path,
  }) async {
    if (!_games.contains(gameId)) {
      return ActionResult(
        success: false,
        message: 'Game not found',
        gameOver: false,
        actionsRemaining: 0,
        turnEnded: false,
      );
    }
    return ActionResult(
      success: true,
      message: 'Mock defend executed',
      gameOver: false,
      actionsRemaining: 1,
      turnEnded: false,
    );
  }

  @override
  Future<ActionResult> crateApiExecutePush({
    required String gameId,
    required String pieceId,
    required Position target,
    required Position destination,
  }) async {
    if (!_games.contains(gameId)) {
      return ActionResult(
        success: false,
        message: 'Game not found',
        gameOver: false,
        actionsRemaining: 0,
        turnEnded: false,
      );
    }
    return ActionResult(
      success: true,
      message: 'Mock push executed',
      gameOver: false,
      actionsRemaining: 1,
      turnEnded: false,
    );
  }

  @override
  Future<(String, Position)?> crateApiGetBotMove({
    required String gameId,
    required Difficulty difficulty,
  }) async {
    if (!_games.contains(gameId)) return null;
    return ('BD01', Position(row: 5, col: 2));
  }

  @override
  Future<BotAction?> crateApiGetBotAction({
    required String gameId,
    required Difficulty difficulty,
  }) async {
    if (!_games.contains(gameId)) return null;
    return BotAction(
      pieceId: 'WA01',
      actionType: ActionType.move,
      path: [Position(row: 4, col: 3)],
    );
  }

  @override
  Future<bool> crateApiIsGameOver({required String gameId}) async =>
      !_games.contains(gameId);

  @override
  Future<Team?> crateApiGetWinner({required String gameId}) async => null;

  @override
  Future<bool> crateApiGameExists({required String gameId}) async =>
      _games.contains(gameId);

  @override
  Future<bool> crateApiDeleteGame({required String gameId}) async {
    return _games.remove(gameId);
  }

  @override
  Future<String> crateApiGreet({required String name}) async {
    return 'Hello, $name! Welcome to Xfutebol!';
  }

  /// Creates a mock set of 14 pieces for testing (7 per team).
  List<PieceView> _createMockPieces() {
    return [
      // White team (7 pieces)
      PieceView(
        id: 'WG01',
        team: Team.white,
        role: PieceRole.goalkeeper,
        position: Position(row: 0, col: 3),
        hasBall: false,
      ),
      PieceView(
        id: 'WD01',
        team: Team.white,
        role: PieceRole.defender,
        position: Position(row: 1, col: 1),
        hasBall: false,
      ),
      PieceView(
        id: 'WD02',
        team: Team.white,
        role: PieceRole.defender,
        position: Position(row: 1, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 'WM01',
        team: Team.white,
        role: PieceRole.midfielder,
        position: Position(row: 2, col: 2),
        hasBall: false,
      ),
      PieceView(
        id: 'WM02',
        team: Team.white,
        role: PieceRole.midfielder,
        position: Position(row: 2, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 'WA01',
        team: Team.white,
        role: PieceRole.attacker,
        position: Position(row: 3, col: 3),
        hasBall: true, // Ball holder
      ),
      PieceView(
        id: 'WA02',
        team: Team.white,
        role: PieceRole.attacker,
        position: Position(row: 3, col: 4),
        hasBall: false,
      ),
      // Black team (7 pieces)
      PieceView(
        id: 'BG01',
        team: Team.black,
        role: PieceRole.goalkeeper,
        position: Position(row: 7, col: 4),
        hasBall: false,
      ),
      PieceView(
        id: 'BD01',
        team: Team.black,
        role: PieceRole.defender,
        position: Position(row: 6, col: 2),
        hasBall: false,
      ),
      PieceView(
        id: 'BD02',
        team: Team.black,
        role: PieceRole.defender,
        position: Position(row: 6, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 'BM01',
        team: Team.black,
        role: PieceRole.midfielder,
        position: Position(row: 5, col: 2),
        hasBall: false,
      ),
      PieceView(
        id: 'BM02',
        team: Team.black,
        role: PieceRole.midfielder,
        position: Position(row: 5, col: 5),
        hasBall: false,
      ),
      PieceView(
        id: 'BA01',
        team: Team.black,
        role: PieceRole.attacker,
        position: Position(row: 4, col: 3),
        hasBall: false,
      ),
      PieceView(
        id: 'BA02',
        team: Team.black,
        role: PieceRole.attacker,
        position: Position(row: 4, col: 4),
        hasBall: false,
      ),
    ];
  }
}
