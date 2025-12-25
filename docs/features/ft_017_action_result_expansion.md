# FT-017: ActionResult Field Expansion

## Status: ✅ Implemented

## Summary

Expanded the `ActionResult` struct in the Flutter bridge to expose additional fields from the engine's `ActionOutcome`, enabling the Flutter app to detect goals and turn endings.

## Problem

The bridge's `ActionResult` was missing critical fields that the engine provides:

| Engine Field | Type | Bridge Status |
|-------------|------|---------------|
| `goal_scored` | `Option<Team>` | ❌ Missing |
| `turn_ended` | `bool` | ❌ Missing |
| `game_over` | `bool` | ✅ Existed |
| `winner` | `Option<Team>` | ✅ Existed |
| `actions_remaining` | `u8` | ✅ Existed |

Without `goal_scored`, the Flutter app couldn't detect when a goal was scored to trigger celebrations or handle post-goal reset.

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
  final Team? goalScored;   // NEW - which team scored (null if no goal)
  final bool turnEnded;     // NEW - whether this action ended the turn
  
  const ActionResult({
    required this.success,
    required this.message,
    required this.gameOver,
    this.winner,
    required this.actionsRemaining,
    this.goalScored,
    required this.turnEnded,
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
      
      // TODO: Handle post-goal reset when engine implements it
      // For now, the engine continues without resetting
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
| `packages/xfutebol_flutter_bridge/rust/src/api.rs` | Added `goal_scored` and `turn_ended` fields |
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
flutter test test/api_contract_test.dart

# Run integration tests (requires device)
cd /path/to/xfutebol-app
flutter test integration_test/app_test.dart -d <device_id>
```

## Related

- **FT-016**: Post-Goal Reset - The engine still needs to implement board reset after goal
- This change enables the app to DETECT goals, but the reset logic is pending in the engine

## Next Steps

1. [ ] Implement post-goal reset in `xfutebol-engine` (FT-016)
2. [ ] Add goal celebration animation in Flutter app
3. [ ] Update `GameController` to handle `goalScored` event
4. [ ] Add sound effects for goal scoring

