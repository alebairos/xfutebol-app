# FT-022: Bot AI Ball Possession Logic

## Status: Implemented (Engine) - **INCOMPLETE** ⚠️

## Summary

Fix bot AI that performs no-op intercept actions when it already has the ball, instead of advancing toward the goal.

## Problem Statement - UPDATED

### Original Bug (Partially Fixed)
When a piece WITH the ball did INTERCEPT → Fixed ✅

### Remaining Bug (NEW)
When the **team** has the ball, other pieces (without ball) still generate INTERCEPT actions, causing:

```
ENGINE:ACTION {"team":"black","action":"intercept","from":"(5,5)","to":"(4,4)","path":["(4,4)"]}
ENGINE:ACTION {"team":"black","action":"intercept","from":"(4,4)","to":"(5,5)","path":["(5,5)"]}
```

**What's happening:**
1. Black team has the ball (one piece holds it)
2. Other Black pieces (without ball) still generate INTERCEPT actions
3. These pieces "intercept" to swap positions (4,4) ↔ (5,5)
4. Ball carrier never advances toward goal
5. Bot effectively does nothing useful

### Root Cause

FT-022 fix only checks:
```rust
if piece.has_ball {
    // Don't intercept
}
```

But should check:
```rust
if my_team_has_ball(board) {
    // No piece on my team should intercept
}
```

## Required Fix

### In `src/core/bot.rs` - `generate_all_moves()` or intercept generation:

```rust
// FT-022 COMPLETE FIX: Check TEAM ball possession, not just piece
fn should_generate_intercept(piece: &Piece, board: &GameBoard) -> bool {
    // If my team has the ball, no intercepts for anyone
    if let Some(ball_holder) = board.get_ball_possession() {
        if ball_holder.team == piece.team {
            return false; // My team has ball - no intercept needed
        }
    }
    
    // Only intercept if opponent has the ball
    true
}
```

### In move evaluation:

```rust
fn evaluate_move(&self, bot_move: &BotMove, board: &GameBoard) -> i32 {
    // ...
    Action::INTERCEPT | Action::DEFEND => {
        // FT-022: Only score intercept if opponent has ball
        if let Some(holder) = board.get_ball_possession() {
            if holder.team == self.team {
                return -1000; // NEVER intercept when we have the ball
            }
        }
        score += 500;
    }
    // ...
}
```

## Expected Behavior After Complete Fix

When Black team has the ball:
1. ✅ Ball carrier: MOVE toward goal, PASS, SHOOT, KICK
2. ✅ Other pieces: MOVE to support positions (NOT intercept!)
3. ❌ NO piece should do INTERCEPT

When White (opponent) has the ball:
1. ✅ Generate INTERCEPT options to steal ball
2. ✅ Intercept paths must END at ball position

## Acceptance Criteria

1. **Team Ball Possession Check**:
   - [ ] When Black has ball, NO Black piece generates INTERCEPT
   - [ ] When White has ball, Black pieces CAN generate INTERCEPT

2. **Offensive Play**:
   - [ ] Bot advances ball toward goal
   - [ ] Bot attempts shots when in range
   - [ ] Other pieces move to support (not intercept)

## Log Evidence

From current (broken) behavior:
```
[21:59:45.850549] ENGINE:ACTION {"team":"black","action":"intercept","from":"(5,5)","to":"(4,4)"}
[21:59:45.850972] ENGINE:ACTION {"team":"black","action":"intercept","from":"(4,4)","to":"(5,5)"}
```

Both Black pieces doing INTERCEPT when Black TEAM has the ball!

## Related Issues

- FT-021: Goal Validation ✅
- FT-022 (original): Piece-level ball check ✅
- FT-022 (this update): Team-level ball check ⚠️ NEEDED
- FT-023: Offensive Strategy (depends on this fix)
