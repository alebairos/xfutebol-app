# FT-018: Goal Handling in Flutter App

## Status: 📋 Planned

## Summary

Update the Flutter app to properly handle goals using the new bridge fields: `goalScored`, `turnEnded`, and `kickoffReset`. This includes goal detection, celebration animations, and kickoff reset handling.

## Background

With FT-017 complete, the bridge now exposes all goal-related fields from the engine:

```dart
class ActionResult {
  final Team? goalScored;    // Which team scored (null = no goal)
  final bool turnEnded;      // Turn ended after this action
  final bool kickoffReset;   // Ball reset to center after goal
  final bool gameOver;       // Game ended (e.g., Golden Goal mode)
  final Team? winner;        // Winner if game ended
  // ...
}
```

## Requirements

### 1. Goal Detection
- After any action (move, pass, shoot, kick), check `result.goalScored`
- If not null, a goal was scored by the indicated team
- Update score display immediately

### 2. Goal Celebration
- Show goal celebration overlay/animation
- Display scoring team's color/name
- Play goal sound effect (if audio enabled)
- Duration: ~2-3 seconds

### 3. Kickoff Reset Handling
- When `result.kickoffReset == true`:
  - Ball has been reset to center by the engine
  - Ball is now held by the conceding team's attacker
  - All pieces return to starting positions (engine handles this)
  - Turn switches to conceding team
- UI should:
  - Animate pieces returning to positions (optional)
  - Refresh board state after celebration
  - Show "Kickoff: [Team]" indicator

### 4. Game Over Detection
- When `result.gameOver == true`:
  - Stop accepting player input
  - Show game over overlay
  - Display winner from `result.winner`
  - Show final score
  - Offer "New Game" or "Main Menu" options

### 5. Turn End Handling
- When `result.turnEnded == true` (and not goal/game over):
  - Switch active team indicator
  - Update actions remaining display
  - If vs bot, trigger bot move

## Implementation Plan

### Phase 1: Goal Detection & Score Update
**File:** `lib/src/game/game_controller.dart` (or equivalent)

```dart
Future<void> _handleActionResult(ActionResult result) async {
  if (!result.success) {
    _showError(result.message);
    return;
  }

  // Update actions remaining
  _actionsRemaining = result.actionsRemaining;

  // Check for goal
  if (result.goalScored != null) {
    await _handleGoalScored(result.goalScored!, result.kickoffReset);
  }

  // Check for game over
  if (result.gameOver) {
    await _handleGameOver(result.winner!);
    return;
  }

  // Check for turn end
  if (result.turnEnded) {
    await _handleTurnEnd();
  }

  // Refresh board
  await _refreshBoard();
}
```

### Phase 2: Goal Celebration Widget
**File:** `lib/src/game/widgets/goal_celebration.dart`

```dart
class GoalCelebration extends StatefulWidget {
  final Team scoringTeam;
  final VoidCallback onComplete;

  const GoalCelebration({
    required this.scoringTeam,
    required this.onComplete,
  });

  @override
  State<GoalCelebration> createState() => _GoalCelebrationState();
}

class _GoalCelebrationState extends State<GoalCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GOAL!',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: widget.scoringTeam == Team.white
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              Text(
                '${widget.scoringTeam.name.toUpperCase()} SCORES!',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Phase 3: Game Over Overlay
**File:** `lib/src/game/widgets/game_over_overlay.dart`

```dart
class GameOverOverlay extends StatelessWidget {
  final Team winner;
  final int whiteScore;
  final int blackScore;
  final VoidCallback onNewGame;
  final VoidCallback onMainMenu;

  const GameOverOverlay({
    required this.winner,
    required this.whiteScore,
    required this.blackScore,
    required this.onNewGame,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GAME OVER', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              '${winner.name.toUpperCase()} WINS!',
              style: TextStyle(fontSize: 32, color: Colors.amber),
            ),
            SizedBox(height: 8),
            Text('$whiteScore - $blackScore', style: TextStyle(fontSize: 24)),
            SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: onNewGame,
                  child: Text('New Game'),
                ),
                SizedBox(width: 16),
                OutlinedButton(
                  onPressed: onMainMenu,
                  child: Text('Main Menu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Phase 4: Integration in Game Screen
**File:** `lib/src/game/game_screen.dart`

```dart
class _GameScreenState extends State<GameScreen> {
  Team? _goalScoredBy;
  bool _showGameOver = false;
  Team? _winner;

  Future<void> _handleGoalScored(Team team, bool kickoffReset) async {
    setState(() => _goalScoredBy = team);
    
    // Wait for celebration to complete
    await Future.delayed(Duration(milliseconds: 2500));
    
    setState(() => _goalScoredBy = null);
    
    if (kickoffReset) {
      // Board already reset by engine, just refresh
      await _refreshBoard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Game board
        XfutebolBoard(...),
        
        // Goal celebration overlay
        if (_goalScoredBy != null)
          GoalCelebration(
            scoringTeam: _goalScoredBy!,
            onComplete: () => setState(() => _goalScoredBy = null),
          ),
        
        // Game over overlay
        if (_showGameOver)
          GameOverOverlay(
            winner: _winner!,
            whiteScore: _whiteScore,
            blackScore: _blackScore,
            onNewGame: _startNewGame,
            onMainMenu: _returnToMenu,
          ),
      ],
    );
  }
}
```

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/src/game/game_controller.dart` | Modify | Add goal/turnEnd/gameOver handling logic |
| `lib/src/game/widgets/goal_celebration.dart` | Create | Goal celebration overlay widget |
| `lib/src/game/widgets/game_over_overlay.dart` | Create | Game over screen widget |
| `lib/src/game/game_screen.dart` | Modify | Integrate overlays and handle state |

## Testing

### Unit Tests
```dart
group('Goal handling', () {
  test('goal detection triggers celebration', () async {
    final controller = GameController();
    final result = ActionResult(
      success: true,
      message: 'Goal!',
      gameOver: false,
      actionsRemaining: 0,
      goalScored: Team.white,
      turnEnded: true,
      kickoffReset: true,
    );
    
    await controller.handleActionResult(result);
    
    expect(controller.lastGoalScoredBy, Team.white);
  });
  
  test('kickoff reset refreshes board', () async {
    // Test board state after kickoffReset
  });
  
  test('game over stops input', () async {
    // Test input blocked after gameOver
  });
});
```

### Integration Tests
```dart
testWidgets('goal celebration displays and auto-dismisses', (tester) async {
  await tester.pumpWidget(
    GoalCelebration(
      scoringTeam: Team.white,
      onComplete: () {},
    ),
  );
  
  expect(find.text('GOAL!'), findsOneWidget);
  
  await tester.pump(Duration(milliseconds: 2500));
  
  // Celebration should trigger onComplete
});
```

## Acceptance Criteria

- [ ] Goal scored by White → Shows "WHITE SCORES!" celebration
- [ ] Goal scored by Black → Shows "BLACK SCORES!" celebration
- [ ] Celebration auto-dismisses after ~2.5 seconds
- [ ] Board refreshes after kickoff reset
- [ ] Score display updates immediately on goal
- [ ] Game over shows correct winner
- [ ] Game over allows starting new game
- [ ] Game over allows returning to menu
- [ ] Bot mode: Bot plays after kickoff (conceding team starts)

## Dependencies

- ✅ FT-017: ActionResult expansion (complete)
- ✅ Engine: Kickoff reset logic (complete)
- ✅ Bridge: All fields mapped (complete)

## Notes

- The engine handles all reset logic (ball position, piece positions, turn switch)
- The app just needs to:
  1. Show celebration
  2. Refresh board state (which gets new positions from engine)
- No client-side game logic needed for reset

## Related

- FT-016: Post-Goal Reset (engine analysis)
- FT-017: ActionResult Field Expansion (bridge implementation)
- FT-015: Flutter UI Implementation (current UI structure)

