# FT-023: Bot Offensive Strategy

## Status: Draft

## Summary

The bot AI correctly generates valid moves (FT-022 fixed) but lacks offensive strategy. When the bot has the ball, it should actively advance toward the opponent's goal and attempt to score.

## Problem Statement

### Observed Behavior

After FT-022 fix:
- ✅ Bot no longer does no-op intercepts
- ✅ Bot generates valid MOVE/PASS/SHOOT options
- ❌ Bot does NOT advance toward goal
- ❌ Bot appears to move randomly or defensively
- ❌ Bot never attempts to score

### Expected Behavior

When bot (Black team) has the ball:
1. **Advance toward White's goal** (row 0)
2. **Shoot when in range** (rows 0-2, columns 2-4)
3. **Pass to forward teammates** when blocked
4. **Prioritize scoring opportunities**

## Current AI Architecture

The bot AI likely uses a scoring/priority system for move selection:

```rust
fn select_best_action(moves: Vec<BotMove>, difficulty: Difficulty) -> Option<BotMove> {
    match difficulty {
        Difficulty::Easy => moves.choose_random(),
        Difficulty::Medium => {
            // Some priority logic, but may not prioritize goal advancement
        }
        Difficulty::Hard => {
            // Full strategic evaluation
        }
    }
}
```

## Proposed Solution

### Phase 1: Goal-Seeking Heuristic

Add a scoring function that rewards moves closer to opponent's goal:

```rust
fn score_offensive_move(piece: &Piece, target: BoardTile, opponent_goal_row: u8) -> i32 {
    let current_distance = (piece.position.row as i32 - opponent_goal_row as i32).abs();
    let new_distance = (target.row as i32 - opponent_goal_row as i32).abs();
    
    let mut score = 0;
    
    // Reward advancing toward goal
    if new_distance < current_distance {
        score += 10 * (current_distance - new_distance);
    }
    
    // Bonus for being in shooting range
    if is_in_shooting_range(target, opponent_goal_row) {
        score += 50;
    }
    
    // Bonus for being in goal zone
    if is_goal_zone(target, opponent_goal_row) {
        score += 100; // This would score!
    }
    
    score
}
```

### Phase 2: Action Priority

When ball holder selects action:

```rust
fn prioritize_offensive_actions(moves: Vec<BotMove>) -> Vec<BotMove> {
    // Priority order:
    // 1. SHOOT to goal (if in range) → highest priority
    // 2. MOVE into goal zone (instant score)
    // 3. MOVE toward goal
    // 4. PASS to forward teammate
    // 5. Other moves
    
    moves.sort_by(|a, b| {
        let score_a = score_offensive_move(a);
        let score_b = score_offensive_move(b);
        score_b.cmp(&score_a) // Descending
    });
    
    moves
}
```

### Phase 3: Shooting Logic

Bot should attempt to shoot when:
- Ball holder is in rows 0-2 (for Black) or 5-7 (for White)
- Clear path to goal columns (2-4)
- No defender blocking the shot path

```rust
fn should_attempt_shoot(piece: &Piece, board: &Board) -> bool {
    let goal_row = match piece.team {
        Team::Black => 0,  // Black shoots toward row 0
        Team::White => 7,  // White shoots toward row 7
    };
    
    let distance_to_goal = (piece.position.row as i32 - goal_row as i32).abs();
    
    // Within shooting range (3 rows from goal)
    if distance_to_goal <= 3 {
        // Check if path to goal is clear
        return has_clear_shot_path(piece, goal_row, board);
    }
    
    false
}
```

## Difficulty Levels

| Difficulty | Offensive Behavior |
|------------|-------------------|
| **Easy** | Random moves, no goal-seeking |
| **Medium** | 70% goal-seeking, 30% random |
| **Hard** | Full strategic play, always seeks goal |

## Acceptance Criteria

1. **Goal Advancement**:
   - [ ] Bot with ball moves toward opponent's goal
   - [ ] Bot prefers forward moves over lateral/backward moves

2. **Shooting**:
   - [ ] Bot attempts to shoot when in range
   - [ ] Bot looks for clear shot paths

3. **Scoring**:
   - [ ] Bot can score goals during normal gameplay
   - [ ] In 10 test matches, bot scores at least 1 goal per match (on Medium+)

4. **Difficulty Scaling**:
   - [ ] Easy: Minimal goal-seeking
   - [ ] Medium: Moderate goal-seeking
   - [ ] Hard: Aggressive goal-seeking

## Testing

### Manual Test
1. Start game
2. Let bot intercept ball (or move White piece away)
3. Observe bot behavior over 10+ turns
4. **Verify**: Bot advances toward row 0 (White's goal)
5. **Verify**: Bot attempts to score

### Unit Tests
```rust
#[test]
fn test_bot_advances_toward_goal() {
    // Setup: Black has ball at row 4
    // Action: Get bot move
    // Assert: Move target is row 3 or lower (closer to goal)
}

#[test]
fn test_bot_shoots_when_in_range() {
    // Setup: Black ball holder at row 2, clear path to goal
    // Action: Get bot move
    // Assert: Action is SHOOT
}

#[test]
fn test_bot_scores_goal() {
    // Setup: Black ball holder at row 1, goal column
    // Action: Execute bot move
    // Assert: Goal scored for Black
}
```

## Related Issues

- FT-021: Goal Validation (must have ball to score) ✅
- FT-022: Bot Ball Possession Logic (no no-op intercepts) ✅
- FT-023: This issue - offensive strategy

## Notes

The app currently uses `Difficulty::medium`. Even on Medium, the bot should show some goal-seeking behavior.

The issue may be that Medium difficulty is using random selection among valid moves rather than strategic prioritization.

