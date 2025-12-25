# FT-016: Post-Goal Reset (Kickoff)

## Status: Investigation Complete

## Problem

After a goal is scored in non-GoldenGoal game modes, the ball should reset to the center and possession should transfer to the team that conceded (like a real soccer kickoff). Currently, this doesn't happen.

## Current Behavior

1. Goal scored → Score incremented ✓
2. Game continues (if not GoldenGoal) ✓
3. Ball stays where it is ✗ (should go to center)
4. Conceding team doesn't get possession ✗

## Expected Behavior (Soccer Rules)

After a goal:
1. Ball returns to center of the field (E4 or E5)
2. Team that was scored against gets possession (kickoff)
3. Positions may optionally reset (or just the ball)
4. Game continues with the conceding team's turn

## Root Cause Analysis

### Where Logic Currently Exists

**CLI (`xfutebol-engine/src/main.rs`)**:
```rust
fn reset_ball_to_center(game_match: &mut GameMatch) {
    let center = if game_match.state.turn_number % 2 == 0 {
        BoardTile::E5
    } else {
        BoardTile::E4
    };
    
    game_match.state.board.set_ball_position(Some(center));
    game_match.state.board.set_ball_possession(None);
}
```

This logic exists only in `main.rs` for CLI use - it's NOT part of the `GameMatch` library.

### What's Missing

1. **Engine (`GameMatch`)**: No `reset_after_goal` method
2. **Flutter Bridge**: No API to reset ball position
3. **Flutter App**: No handling for post-goal state

### Goal Detection in Engine

In `game_match.rs`, `check_goal_and_end()`:
```rust
fn check_goal_and_end(&mut self, last_tile: BoardTile) -> (Option<Team>, bool, Option<Team>) {
    // Check for goal
    let goal = if turn == Team::White && self.state.board.is_top_goal_tile(last_tile) {
        self.state.score.0 += 1;
        Some(Team::White)
    } else if turn == Team::Black && self.state.board.is_bottom_goal_tile(last_tile) {
        self.state.score.1 += 1;
        Some(Team::Black)
    } else {
        None
    };

    // Check for game end based on mode
    let (game_over, winner) = if goal.is_some() {
        match self.game_mode.game_ending {
            GameEnding::GoldenGoal | GameEnding::GoalReached => {
                self.state.status = GameMatchStatus::Finished;
                (true, goal)
            }
            _ => (false, None)  // <-- Game continues, but NO reset!
        }
    } else {
        (false, None)
    };

    (goal, game_over, winner)
}
```

## Proposed Solution

### Option A: Fix in Engine (Recommended)

Add `reset_after_goal` to `GameMatch` in `xfutebol-engine`:

```rust
impl GameMatch {
    fn reset_after_goal(&mut self, scoring_team: Team) {
        // Ball goes to center
        let center = BoardTile::E4; // or E5 based on turn
        self.state.board.set_ball_position(Some(center));
        
        // Conceding team gets possession
        let kickoff_team = match scoring_team {
            Team::White => Team::Black,
            Team::Black => Team::White,
            _ => Team::White,
        };
        
        // Give ball to conceding team's attacker at center
        // (Implementation details TBD)
        
        // Switch turn to conceding team
        self.state.current_turn = kickoff_team;
        self.actions_remaining = self.game_mode.actions_per_turn as u8;
    }
}
```

Then update `check_goal_and_end`:
```rust
if goal.is_some() && !game_over {
    self.reset_after_goal(goal.unwrap());
}
```

### Option B: Bridge Workaround

Add a `reset_ball_to_center` API to the Flutter bridge that the app can call after detecting a goal.

### Option C: Flutter App Workaround

In `GameController`, after executing a move that returns `goal_scored: Some(team)`, manually reset by calling a new bridge API.

## Implementation Plan

1. [ ] Implement `reset_after_goal` in `xfutebol-engine/src/game/game_match.rs`
2. [ ] Update `check_goal_and_end` to call reset when game continues
3. [ ] Update `ActionOutcome` to indicate if reset occurred
4. [ ] Test with `TurnLimit` game modes
5. [ ] Verify Flutter app displays correctly after reset

## Files Affected

### Engine (`xfutebol-engine`)
- `src/game/game_match.rs` - Add reset logic
- `src/core/board.rs` - May need helper methods

### Bridge (`xfutebol_flutter_bridge`)
- `rust/src/api.rs` - May need new API if Option B/C chosen

### Flutter App
- `lib/src/game/game_controller.dart` - May need to handle reset

## Testing Considerations

1. Test goal in `StandardMatch` mode (20 turns) - should reset and continue
2. Test goal in `QuickMatch` mode (10 turns) - should reset and continue
3. Test goal in `GoldenGoal` mode - should end game immediately
4. Verify correct team gets kickoff after goal
5. Verify ball position is at center after reset

## Related Issues

- `duplicate keys` error in UI was fixed (validMoves deduplication)
- Widget test compilation error was fixed (MyApp → XfutebolApp)

