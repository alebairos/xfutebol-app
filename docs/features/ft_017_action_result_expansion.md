# FT-017: ActionResult Field Expansion

## Status: ✅ Complete (100% FT-011 Support)

## Summary

Expanded the `ActionResult` struct in the Flutter bridge to expose all fields from the engine's `ActionOutcome`, enabling the Flutter app to fully detect goals, turn endings, and kickoff resets.

## Problem

The bridge's `ActionResult` was missing critical fields that the engine provides:

| Engine Field | Type | Bridge Status |
|-------------|------|---------------|
| `goal_scored` | `Option<Team>` | ❌ Missing |
| `turn_ended` | `bool` | ❌ Missing |
| `kickoff_reset` | `bool` | ❌ Missing |
| `game_over` | `bool` | ✅ Existed |
| `winner` | `Option<Team>` | ✅ Existed |
| `actions_remaining` | `u8` | ✅ Existed |

Without these fields, the Flutter app couldn't:
- Detect when a goal was scored to trigger celebrations
- Know when the ball should reset to center after a goal
- Handle post-goal kickoff properly

## Solution

### 1. Updated Rust Bridge (`api.rs`)

```rust
#[frb]
#[derive(Debug, Clone)]
pub struct ActionResult {
    pub success: bool,
    pub message: String,
    pub game_over: bool,
    pub winner: Option<Team>,
    pub actions_remaining: u8,
    /// Which team scored a goal (if any) - None means no goal
    pub goal_scored: Option<Team>,  // NEW
    /// Whether the turn ended after this action
    pub turn_ended: bool,           // NEW
    /// Whether ball was reset to center after a goal (kickoff)
    pub kickoff_reset: bool,        // NEW
}

impl ActionResult {
    fn from_outcome(outcome: &xfutebol_engine::ActionOutcome) -> Self {
        ActionResult {
            success: true,
            message: format!("Action completed: {:?}", outcome.action),
            game_over: outcome.game_over,
            winner: outcome.winner.map(|t| t.into()),
            actions_remaining: outcome.actions_remaining,
            goal_scored: outcome.goal_scored.map(|t| t.into()),  // NEW
            turn_ended: outcome.turn_ended,                       // NEW
            kickoff_reset: outcome.kickoff_reset,                 // NEW
        }
    }
}
```

### 2. Regenerated Dart Bindings

```dart
class ActionResult {
  final bool success;
  final String message;
  final bool gameOver;
  final Team? winner;
  final int actionsRemaining;
  final Team? goalScored;    // NEW - which team scored (null if no goal)
  final bool turnEnded;      // NEW - whether this action ended the turn
  final bool kickoffReset;   // NEW - whether ball reset to center after goal
  
  const ActionResult({
    required this.success,
    required this.message,
    required this.gameOver,
    this.winner,
    required this.actionsRemaining,
    this.goalScored,
    required this.turnEnded,
    required this.kickoffReset,
  });
}
```

### 3. Updated Tests

- `test/mocks/mock_bridge_api.dart` - All mock ActionResult instances updated
- `test/api_contract_test.dart` - Added tests for new fields

## Usage in Flutter App

```dart
Future<void> executePlayerMove(String pieceId, Position target) async {
  final result = await executeMove(
    gameId: _gameId,
    pieceId: pieceId,
    to: target,
  );
  
  if (result.success) {
    // Check if a goal was scored
    if (result.goalScored != null) {
      _showGoalCelebration(result.goalScored!);
      
      // Check if kickoff reset occurred (ball returned to center)
      if (result.kickoffReset) {
        _playKickoffAnimation();
        // Board state is already updated by engine
      }
    }
    
    // Check if turn ended
    if (result.turnEnded) {
      _switchTurn();
    }
    
    // Check if game is over
    if (result.gameOver && result.winner != null) {
      _showGameOver(result.winner!);
    }
    
    // Refresh board state
    await _refreshBoard();
  }
}
```

## Files Changed

| File | Change |
|------|--------|
| `packages/xfutebol_flutter_bridge/rust/src/api.rs` | Added `goal_scored`, `turn_ended`, and `kickoff_reset` fields |
| `packages/xfutebol_flutter_bridge/lib/src/rust/api.dart` | Auto-regenerated |
| `packages/xfutebol_flutter_bridge/lib/src/rust/frb_generated.dart` | Auto-regenerated |
| `packages/xfutebol_flutter_bridge/lib/src/rust/frb_generated.io.dart` | Auto-regenerated |
| `packages/xfutebol_flutter_bridge/lib/src/rust/frb_generated.web.dart` | Auto-regenerated |
| `packages/xfutebol_flutter_bridge/test/mocks/mock_bridge_api.dart` | Updated all ActionResult constructors |
| `packages/xfutebol_flutter_bridge/test/api_contract_test.dart` | Added tests for new fields |

## Testing

```bash
# Run bridge tests
cd packages/xfutebol_flutter_bridge
flutter test

# Run integration tests (requires device)
cd /path/to/xfutebol-app
flutter test integration_test/app_test.dart -d <device_id>
```

## Engine → Bridge Field Mapping (100% Complete)

| Engine `ActionOutcome` | Bridge `ActionResult` | Status |
|------------------------|----------------------|--------|
| `action` | - | Not exposed (internal) |
| `piece_id` | - | Not exposed (use BoardView) |
| `from` | - | Not exposed (use BoardView) |
| `to` | - | Not exposed (use BoardView) |
| `path` | - | Not exposed (use BoardView) |
| `turn_ended` | `turnEnded` | ✅ Mapped |
| `goal_scored` | `goalScored` | ✅ Mapped |
| `game_over` | `gameOver` | ✅ Mapped |
| `winner` | `winner` | ✅ Mapped |
| `actions_remaining` | `actionsRemaining` | ✅ Mapped |
| `kickoff_reset` | `kickoffReset` | ✅ Mapped |

## Related

- **FT-016**: Post-Goal Reset - Engine already implements kickoff reset; bridge now exposes it
- This change enables the app to fully handle goals and kickoffs

## Next Steps

1. [x] ~~Implement post-goal reset in engine~~ (Already done in engine)
2. [ ] Add goal celebration animation in Flutter app
3. [ ] Update `GameController` to handle `goalScored` + `kickoffReset` events
4. [ ] Add sound effects for goal scoring

