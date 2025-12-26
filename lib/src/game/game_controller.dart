import 'package:flutter/foundation.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

import 'services/match_logger.dart';

/// Controller for game state and bridge interactions.
/// 
/// Manages:
/// - Game initialization and state
/// - Piece selection and valid moves
/// - Action execution (move, pass, shoot, etc.)
/// - Bot turns
/// - Goal detection and celebration
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

  /// Team that just scored (null if no recent goal)
  /// This is set when a goal is scored and cleared after celebration
  Team? _goalScoredBy;
  Team? get goalScoredBy => _goalScoredBy;

  /// Whether a kickoff reset just occurred
  bool _kickoffReset = false;
  bool get kickoffReset => _kickoffReset;

  /// Game over state - uses engine's gameOver flag from last action
  bool _isGameOver = false;
  bool get isGameOver => _isGameOver || 
      (_board != null && (_board!.whiteScore >= 3 || _board!.blackScore >= 3));

  /// Winner (null if game not over)
  Team? _winner;
  Team? get winner {
    if (_winner != null) return _winner;
    if (_board == null) return null;
    if (_board!.whiteScore >= 3) return Team.white;
    if (_board!.blackScore >= 3) return Team.black;
    return null;
  }

  /// Match logger for debugging
  MatchLogger? _logger;
  MatchLogger? get logger => _logger;

  /// Start a new game
  Future<void> startNewGame() async {
    _isLoading = true;
    _errorMessage = null;
    _isGameOver = false;
    _winner = null;
    _goalScoredBy = null;
    _kickoffReset = false;
    notifyListeners();

    try {
      _logger?.logBridgeStart('newGame');
      _gameId = await newGame(mode: GameModeType.quickMatch);
      
      // Initialize logger for this match
      _logger = MatchLogger(_gameId!);
      _logger!.logUI(UIEventType.gameStarted, 'New game started', data: {
        'gameId': _gameId,
        'mode': 'quickMatch',
      });
      _logger?.logBridgeComplete('newGame', result: {'gameId': _gameId});
      
      await _refreshBoard();
      _selectedPieceId = null;
      _validMoves = [];
      _lastMoveFrom = null;
      _lastMoveTo = null;
    } catch (e) {
      _errorMessage = 'Failed to start game: $e';
      _logger?.logError('Failed to start game', error: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear goal celebration state and continue game
  /// Called by UI after celebration animation completes
  Future<void> clearGoalCelebration() async {
    _goalScoredBy = null;
    _kickoffReset = false;
    
    // CRITICAL: Refresh board state after kickoff reset
    // The engine has reset the board, we need fresh data
    await _refreshBoard();
    notifyListeners();

    // Continue bot turn if it's bot's turn after kickoff
    if (!isGameOver && _board?.currentTurn == Team.black) {
      await _handleBotTurn();
    }
  }

  /// Handle square tap - select piece or execute move
  Future<void> handleSquareTap(Position position) async {
    if (_gameId == null || _board == null || isGameOver) return;

    _logger?.logUI(UIEventType.squareTapped, 'position', data: {
      'row': position.row,
      'col': position.col,
    });

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

    _logger?.logUI(UIEventType.pieceTapped, piece.id, data: {
      'team': piece.team.name,
      'role': piece.role.name,
      'position': '(${piece.position.row},${piece.position.col})',
      'hasBall': piece.hasBall,
    });

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
      _logger?.logBridgeStart('getLegalMoves');
      _validMoves = await getLegalMoves(gameId: _gameId!, pieceId: piece.id);
      _logger?.logBridgeComplete('getLegalMoves', result: {'moveCount': _validMoves.length});
      _logger?.logUI(UIEventType.validMovesComputed, 'moves', data: {
        'count': _validMoves.length,
        'moves': _validMoves.map((m) => '(${m.row},${m.col})').toList(),
      });
    } catch (e) {
      _errorMessage = 'Failed to get moves: $e';
      _validMoves = [];
      _logger?.logBridgeFailed('getLegalMoves', e.toString());
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

      _logger?.logBridgeStart('executeMove');
      // Execute the move and handle result
      final result = await executeMove(
        gameId: _gameId!,
        pieceId: _selectedPieceId!,
        to: target,
      );
      _logger?.logBridgeComplete('executeMove', result: {
        'success': result.success,
        'message': result.message,
        'goalScored': result.goalScored?.name,
      });

      // Sync engine log after action
      await _logger?.syncFromEngine();

      await _handleActionResult(result);
      _clearSelection();

      // Handle bot turn if needed (after goal celebration)
      if (_goalScoredBy == null && !isGameOver) {
        await _handleBotTurn();
      }
    } catch (e) {
      _errorMessage = 'Move failed: $e';
      _logger?.logBridgeFailed('executeMove', e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle action result - check for goals and game over
  Future<void> _handleActionResult(ActionResult result) async {
    if (!result.success) {
      _errorMessage = result.message;
      _logger?.logError('Action failed', error: result.message);
      return;
    }

    // Check for goal scored
    if (result.goalScored != null) {
      _goalScoredBy = result.goalScored;
      _kickoffReset = result.kickoffReset;
      _logger?.logUI(UIEventType.goalScored, result.goalScored!.name, data: {
        'team': result.goalScored!.name,
        'kickoffReset': result.kickoffReset,
      });
      notifyListeners();
      // UI will show celebration and call clearGoalCelebration() when done
    }

    // Check for game over
    if (result.gameOver) {
      _isGameOver = true;
      _winner = result.winner;
    }

    // Refresh board state
    await _refreshBoard();
  }

  /// Handle bot turn (if it's black's turn)
  Future<void> _handleBotTurn() async {
    if (_gameId == null || _board == null || isGameOver) return;

    int consecutiveErrors = 0;
    const maxErrors = 3; // Stop after 3 consecutive failures

    // Keep executing bot actions while it's black's turn
    while (_board!.currentTurn == Team.black && !isGameOver && _goalScoredBy == null) {
      // Small delay to show the bot is "thinking"
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        // Get bot's action
        // Use Medium difficulty so bot prioritizes interception (Easy = random moves)
        final botAction = await getBotAction(
          gameId: _gameId!,
          difficulty: Difficulty.medium,
        );

        if (botAction == null) {
          // Bot has no valid action, end turn
          _logger?.logUI(UIEventType.error, 'Bot has no valid action', data: {'reason': 'null action'});
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
        final result = await _executeBotAction(botAction);
        
        if (result != null) {
          // Check if action failed
          if (!result.success) {
            consecutiveErrors++;
            _logger?.logError('Bot action failed', error: result.message);
            
            if (consecutiveErrors >= maxErrors) {
              _logger?.logError('Bot loop stopped', error: 'Too many consecutive errors ($maxErrors)');
              break;
            }
            
            // Refresh board and retry
            await _refreshBoard();
            continue;
          }
          
          // Success - reset error counter
          consecutiveErrors = 0;
          
          await _handleActionResult(result);
          notifyListeners();
          
          // Stop bot loop if goal scored (let celebration play)
          if (_goalScoredBy != null || isGameOver) {
            break;
          }
        }
      } catch (e) {
        consecutiveErrors++;
        _errorMessage = 'Bot move failed: $e';
        _logger?.logError('Bot move exception', error: e.toString());
        
        if (consecutiveErrors >= maxErrors) {
          break;
        }
      }
    }
  }

  /// Execute a bot action and return the result
  Future<ActionResult?> _executeBotAction(BotAction action) async {
    switch (action.actionType) {
      case ActionType.move:
        if (action.path.isNotEmpty) {
          return executeMove(
            gameId: _gameId!,
            pieceId: action.pieceId,
            to: action.path.last,
          );
        }
        return null;
      case ActionType.pass:
        return executePass(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
      case ActionType.shoot:
        return executeShoot(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
      case ActionType.intercept:
        return executeIntercept(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
      case ActionType.kick:
        return executeKick(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
      case ActionType.defend:
        return executeDefend(
          gameId: _gameId!,
          pieceId: action.pieceId,
          path: action.path,
        );
      case ActionType.push:
        if (action.path.length >= 2) {
          return executePush(
            gameId: _gameId!,
            pieceId: action.pieceId,
            target: action.path[0],
            destination: action.path[1],
          );
        }
        return null;
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

  /// Export match log to file
  Future<void> exportLog() async {
    if (_logger != null) {
      _logger!.logUI(UIEventType.gameEnded, 'Game ended', data: {
        'winner': winner?.name,
        'scoreWhite': _board?.whiteScore,
        'scoreBlack': _board?.blackScore,
      });
      await _logger!.exportToFile();
    }
  }

  @override
  void dispose() {
    // Export log before cleanup
    if (_logger != null) {
      exportLog();
    }
    
    // Clean up game if needed
    if (_gameId != null) {
      deleteGame(gameId: _gameId!);
    }
    super.dispose();
  }
}
