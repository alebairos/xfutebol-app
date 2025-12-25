import 'package:flutter/material.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Game over overlay with winner display and action buttons.
///
/// Shows the winner, final score, and options to play again or exit.
class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({
    super.key,
    required this.winner,
    required this.whiteScore,
    required this.blackScore,
    required this.onNewGame,
    required this.onMainMenu,
  });

  /// The winning team
  final Team winner;

  /// White team's final score
  final int whiteScore;

  /// Black team's final score
  final int blackScore;

  /// Called when "Play Again" is pressed
  final VoidCallback onNewGame;

  /// Called when "Main Menu" is pressed
  final VoidCallback onMainMenu;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlayerWin = widget.winner == Team.white;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withAlpha(220),
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPlayerWin ? Colors.amber : Colors.grey.shade600,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isPlayerWin ? Colors.amber : Colors.black)
                        .withAlpha(100),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy/emoji
                  Text(
                    isPlayerWin ? '🏆' : '😔',
                    style: const TextStyle(fontSize: 64),
                  ),

                  const SizedBox(height: 16),

                  // Game Over text
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Winner announcement
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isPlayerWin ? Colors.amber : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isPlayerWin ? 'YOU WIN!' : 'BOT WINS!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isPlayerWin ? Colors.black : Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Final score
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScoreColumn(
                        label: 'YOU',
                        score: widget.whiteScore,
                        isWinner: isPlayerWin,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      _ScoreColumn(
                        label: 'BOT',
                        score: widget.blackScore,
                        isWinner: !isPlayerWin,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: widget.onNewGame,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Play Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: widget.onMainMenu,
                        icon: const Icon(Icons.home),
                        label: const Text('Menu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.isWinner,
  });

  final String label;
  final int score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.amber : Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.amber : Colors.white,
          ),
        ),
      ],
    );
  }
}

