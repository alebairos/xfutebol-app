import 'package:flutter/material.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

import 'game_controller.dart';
import 'widgets/board/board_settings.dart';
import 'widgets/board/xfutebol_board.dart';

/// Main game screen.
/// 
/// Displays:
/// - Score HUD at top
/// - Game board in center  
/// - Turn indicator and actions at bottom
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_onControllerChanged);
    _controller.startNewGame();
  }

  void _onControllerChanged() {
    setState(() {});

    // Show win dialog if game over
    if (_controller.isGameOver && _controller.winner != null) {
      _showWinDialog();
    }

    // Show error snackbar if error
    if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: _controller.clearError,
          ),
        ),
      );
      _controller.clearError();
    }
  }

  void _showWinDialog() {
    final winner = _controller.winner!;
    final isPlayerWin = winner == Team.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isPlayerWin ? '🎉 Victory!' : '😔 Defeat',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            color: isPlayerWin ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPlayerWin ? 'You won!' : 'The bot won!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              '${_controller.board!.whiteScore} - ${_controller.board!.blackScore}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.startNewGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = _controller.board;

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Dark green background
      body: SafeArea(
        child: Column(
          children: [
            // Score HUD
            _ScoreHud(board: board),

            // Board
            Expanded(
              child: Center(
                child: _controller.isLoading && board == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : board != null
                        ? _buildBoard(board)
                        : const Text(
                            'Failed to load game',
                            style: TextStyle(color: Colors.white),
                          ),
              ),
            ),

            // Turn indicator and actions
            _TurnIndicator(
              board: board,
              selectedPieceId: _controller.selectedPieceId,
              isLoading: _controller.isLoading,
              onNewGame: _controller.startNewGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(BoardView board) {
    // Calculate board size to fit screen with padding
    final screenSize = MediaQuery.of(context).size;
    final boardSize = (screenSize.width < screenSize.height - 200
            ? screenSize.width
            : screenSize.height - 200) -
        32; // 16px padding on each side

    return Padding(
      padding: const EdgeInsets.all(16),
      child: XfutebolBoard(
        size: boardSize,
        board: board,
        settings: const BoardSettings(
          showCoordinates: true,
        ),
        selectedPieceId: _controller.selectedPieceId,
        validMoves: _controller.validMoves,
        lastMoveFrom: _controller.lastMoveFrom,
        lastMoveTo: _controller.lastMoveTo,
        onSquareTap: _controller.handleSquareTap,
      ),
    );
  }
}

/// Score display at top of screen
class _ScoreHud extends StatelessWidget {
  const _ScoreHud({required this.board});

  final BoardView? board;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // White (player) score
          _TeamScore(
            label: 'YOU',
            score: board?.whiteScore ?? 0,
            color: Colors.white,
            isActive: board?.currentTurn == Team.white,
          ),

          // VS separator
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Black (bot) score
          _TeamScore(
            label: 'BOT',
            score: board?.blackScore ?? 0,
            color: const Color(0xFF2D2D2D),
            isActive: board?.currentTurn == Team.black,
          ),
        ],
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.label,
    required this.score,
    required this.color,
    required this.isActive,
  });

  final String label;
  final int score;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(230), // 0.9 * 255 ≈ 230
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: Colors.amber, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77), // 0.3 * 255 ≈ 77
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color == Colors.white ? Colors.grey.shade800 : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: color == Colors.white ? Colors.grey.shade900 : Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Turn indicator and action buttons at bottom
class _TurnIndicator extends StatelessWidget {
  const _TurnIndicator({
    required this.board,
    required this.selectedPieceId,
    required this.isLoading,
    required this.onNewGame,
  });

  final BoardView? board;
  final String? selectedPieceId;
  final bool isLoading;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final isPlayerTurn = board?.currentTurn == Team.white;
    final actionsRemaining = board?.actionsRemaining ?? 0;
    final turnNumber = board?.turnNumber ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Turn info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isPlayerTurn ? Colors.white : const Color(0xFF2D2D2D),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                isPlayerTurn ? 'Your turn' : 'Bot thinking...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Actions and turn info
          Text(
            'Turn $turnNumber • $actionsRemaining actions left',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          // Hint text
          Text(
            selectedPieceId != null
                ? 'Tap a highlighted square to move'
                : 'Tap a piece to select it',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 16),

          // New game button
          TextButton.icon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh, color: Colors.white70),
            label: const Text(
              'New Game',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

