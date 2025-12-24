import 'package:flutter/foundation.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Controller for game state and bridge interactions.
/// 
/// Manages:
/// - Game initialization and state
/// - Piece selection and valid moves
/// - Action execution (move, pass, shoot, etc.)
/// - Bot turns
class GameController extends ChangeNotifier {
  GameController();

  /// Current game ID (null if no game started)
  String? _gameId;
  String? get gameId => _gameId;

  /// Current board state
  BoardView? _board;
  BoardView? get board => _board;

  /// Currently selected piece ID
  String? _selectedPieceId;
  String? get selectedPieceId => _selectedPieceId;

  /// Valid moves for selected piece
  List<Position> _validMoves = [];
  List<Position> get validMoves => _validMoves;

  /// Last move positions (for highlighting)
  Position? _lastMoveFrom;
  Position? get lastMoveFrom => _lastMoveFrom;
  Position? _lastMoveTo;
  Position? get lastMoveTo => _lastMoveTo;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Error message (null if no error)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Game over state
  bool get isGameOver => _board != null && 
      (_board!.whiteScore >= 3 || _board!.blackScore >= 3);

  /// Winner (null if game not over)
  Team? get winner {
    if (_board == null) return null;
    if (_board!.whiteScore >= 3) return Team.white;
    if (_board!.blackScore >= 3) return Team.black;
    return null;
  }

  /// Start a new game
  Future<void> startNewGame() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _gameId = await newGame(mode: GameModeType.quickMatch);
      await _refreshBoard();
      _selectedPieceId = null;
      _validMoves = [];
      _lastMoveFrom = null;
      _lastMoveTo = null;
    } catch (e) {
      _errorMessage = 'Failed to start game: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle square tap - select piece or execute move
  Future<void> handleSquareTap(Position position) async {
    if (_gameId == null || _board == null || isGameOver) return;

    // Check if tapped on a piece
    final tappedPiece = _board!.pieces.where(
      (p) => p.position.row == position.row && p.position.col == position.col,
    ).firstOrNull;

    if (tappedPiece != null) {
      await _handlePieceTap(tappedPiece);
    } else if (_selectedPieceId != null) {
      // Check if tapped position is a valid move
      final isValidMove = _validMoves.any(
        (m) => m.row == position.row && m.col == position.col,
      );

      if (isValidMove) {
        await _executeMove(position);
      } else {
        // Deselect if tapped on empty non-valid square
        _clearSelection();
        notifyListeners();
      }
    }
  }

  /// Handle piece tap
  Future<void> _handlePieceTap(PieceView piece) async {
    if (_gameId == null || _board == null) return;

    // Can only select own pieces on your turn
    if (piece.team != _board!.currentTurn) {
      _clearSelection();
      notifyListeners();
      return;
    }

    // If already selected, deselect
    if (_selectedPieceId == piece.id) {
      _clearSelection();
      notifyListeners();
      return;
    }

    // Select the piece and get valid moves
    _selectedPieceId = piece.id;
    _isLoading = true;
    notifyListeners();

    try {
      _validMoves = await getLegalMoves(gameId: _gameId!, pieceId: piece.id);
    } catch (e) {
      _errorMessage = 'Failed to get moves: $e';
      _validMoves = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Execute a move to the target position
  Future<void> _executeMove(Position target) async {
    if (_gameId == null || _selectedPieceId == null) return;

    final selectedPiece = _board!.pieces.where((p) => p.id == _selectedPieceId).firstOrNull;
    if (selectedPiece == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Store for highlight
      _lastMoveFrom = selectedPiece.position;
      _lastMoveTo = target;

      // Execute the move
      await executeMove(
        gameId: _gameId!,
        pieceId: _selectedPieceId!,
        to: target,
      );

      await _refreshBoard();
      _clearSelection();

      // Handle bot turn if needed
      await _handleBotTurn();
    } catch (e) {
      _errorMessage = 'Move failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle bot turn (if it's black's turn)
  Future<void> _handleBotTurn() async {
    if (_gameId == null || _board == null || isGameOver) return;

    // Keep executing bot actions while it's black's turn
    while (_board!.currentTurn == Team.black && !isGameOver) {
      // Small delay to show the bot is "thinking"
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        // Get bot's action
        final botAction = await getBotAction(
          gameId: _gameId!,
          difficulty: Difficulty.easy,
        );

        if (botAction == null) {
          // Bot has no valid action, end turn
          break;
        }

        // Find the piece to get its position for highlighting
        final botPiece = _board!.pieces.where((p) => p.id == botAction.pieceId).firstOrNull;
        if (botPiece != null) {
          _lastMoveFrom = botPiece.position;
          if (botAction.path.isNotEmpty) {
            _lastMoveTo = botAction.path.last;
          }
        }

        // Execute the action based on type
        await _executeBotAction(botAction);

        await _refreshBoard();
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Bot move failed: $e';
        break;
      }
    }
  }

  /// Execute a bot action
  Future<void> _executeBotAction(BotAction action) async {
    switch (action.actionType) {
      case ActionType.move:
        if (action.path.isNotEmpty) {
          await executeMove(
            gameId: _gameId!,
            pieceId: action.pieceId,
            to: action.path.last,
          );
        }
        break;
      case ActionType.pass:
        await executePass(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
        break;
      case ActionType.shoot:
        await executeShoot(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
        break;
      case ActionType.intercept:
        await executeIntercept(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
        break;
      case ActionType.kick:
        await executeKick(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
        break;
      case ActionType.defend:
        await executeDefend(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
        break;
      case ActionType.push:
        if (action.path.length >= 2) {
          await executePush(
            gameId: _gameId!,
            pieceId: action.pieceId,
            target: action.path[0],
            destination: action.path[1],
          );
        }
        break;
    }
  }

  /// Refresh board state from engine
  Future<void> _refreshBoard() async {
    if (_gameId == null) return;
    _board = await getBoard(gameId: _gameId!);
  }

  /// Clear piece selection
  void _clearSelection() {
    _selectedPieceId = null;
    _validMoves = [];
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up game if needed
    if (_gameId != null) {
      deleteGame(gameId: _gameId!);
    }
    super.dispose();
  }
}
