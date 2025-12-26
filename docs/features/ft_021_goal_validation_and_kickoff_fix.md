# FT-021: Goal Validation and Kickoff State Fix

## Status: Implemented (Engine) | Pending (App Integration)

## Summary

Fix two critical gameplay bugs:
1. **Goal scored without ball**: A piece without the ball can score by entering the goal zone
2. **Bot illegal paths after kickoff**: Bot receives stale action suggestions after kickoff reset

## Problem Statement

### Bug 1: Goal Without Ball

**Observed behavior**: 
- White piece WA07 moves with ball to (4,3)
- Black intercepts, taking the ball
- User continues moving WA07 (now without ball)
- WA07 reaches goal zone (7,2)
- **Goal is credited to White despite having no ball**

**Log evidence**:
```
[19:40:46.505554] ENGINE:ACTION {"team":"white","action":"move","to":"(4,3)","hasBall":true}
[19:40:49.962723] ENGINE:ACTION {"team":"black","action":"intercept","to":"(4,3)"} ← Ball taken!
[19:40:50.775820] UI:pieceTapped WA07 {"hasBall":false} ← Piece has no ball
[19:41:03.089530] executeMove {"goalScored":"white"} ← GOAL CREDITED ANYWAY
```

**Expected behavior**: 
Goals can only be scored by:
1. Moving a **ball carrier** into the goal zone
2. **Shooting** the ball into the goal
3. A **pass** that lands in the goal zone

### Bug 2: Bot Illegal Paths After Kickoff

**Observed behavior**:
- Goal is scored, kickoff reset triggers
- Bot attempts to move but gets `IllegalPath("F3")` errors
- Bot loop runs 3 times then stops (error limit hit)

**Log evidence**:
```
[19:41:03.092279] UI:goalScored white {"kickoffReset":true}
[19:41:06.466794] UI:error Bot action failed ERROR: IllegalPath("F3")
[19:41:06.971475] UI:error Bot action failed ERROR: IllegalPath("F3")
[19:41:07.476544] UI:error Bot action failed ERROR: IllegalPath("F3")
[19:41:07.477266] UI:error Bot loop stopped ERROR: Too many consecutive errors (3)
```

**Root cause**: 
After kickoff reset, the board is restored to initial positions, but:
1. The bot AI computes moves based on pre-reset state
2. The Flutter side may have stale board data
3. Path calculations reference positions that no longer exist

---

## Engine Implementation

### Fix Location
`xfutebol-engine/src/game.rs`

### Key Change
Goal validation now checks ball possession before awarding a goal on MOVE action:

```rust
fn check_goal_on_move(piece: &Piece, to: Position) -> Option<Team> {
    // Only score if piece has the ball AND reaches goal zone
    if !piece.has_ball {
        return None; // Cannot score without ball
    }
    
    // Check if destination is in opponent's goal zone
    match (piece.team, to.row) {
        (Team::White, 7) if (2..=4).contains(&to.col) => Some(Team::White),
        (Team::Black, 0) if (2..=4).contains(&to.col) => Some(Team::Black),
        _ => None,
    }
}
```

---

## Engine Gameplay Tests

### Test 1: `test_public_api_interception_then_move_to_goal`
**File**: `tests/public_api_test.rs:2045-2090`

**Scenario**: Exact bug reproduction
```
1. White attacker at E6, Black midfielder at D5 has ball (post-interception state)
2. White moves: E6 → E7 (no goal - not at goal tile)
3. White moves: E7 → E8 (goal tile, but NO ball)
4. ✅ Assert: goal_scored = None (FT-021 fix verified)
5. ✅ Assert: score remains 0-0
```

---

### Test 2: `test_public_api_comprehensive_all_actions_gameplay`
**File**: `tests/public_api_test.rs:2099-2366`

**All 7 actions tested:**

| Phase | Action | Setup | Validation |
|-------|--------|-------|------------|
| 1 | **MOVE** | White attacker E3 with ball | Ball moves with piece to E4 |
| 2 | **PASS** | A7 at E4 → M5 at F4 | Ball transfers to F4 |
| 3 | **KICK** | Long ball D3 → D4 → D5 → D6 | Multi-tile pass works |
| 4 | **INTERCEPT** | Black E4 intercepts White E5 | Ball stolen |
| 5 | **DEFEND** | Goalkeeper F5 → E5 | GK defensive move |
| 6 | **PUSH** | D4 pushes D5 to D6 | Physical challenge |
| 7 | **SHOOT** | E6 shoots → E7 → E8 (goal) | Goal scored ✅ |

**FT-021 Verification (Phase 8-9):**
```rust
// Phase 8: Piece WITHOUT ball → goal tile → NO GOAL
game.board_mut().from_notation_v3("@A7:E6,m5*:D5|t=w").unwrap();
let result = game.perform_move(BoardTile::E7, BoardTile::E8);
assert!(result.goal_scored.is_none()); // ✅ FT-021

// Phase 9: Piece WITH ball → goal tile → GOAL
game.board_mut().from_notation_v3("@A7*:E7|t=w").unwrap();
let result = game.perform_move(BoardTile::E7, BoardTile::E8);
assert_eq!(result.goal_scored, Some(Team::White)); // ✅ Control
```

---

### Test 3: `test_public_api_interception_steals_ball_no_goal`
**File**: `tests/public_api_test.rs:2368-2432`

**Full interception flow:**
```
1. Setup: White A7 at D5 with ball, Black D2 at D6
2. White moves D5 → D6
3. Simulate interception: Black D2 now has ball at E6
4. White (no ball) continues: D6 → D7 → D8 (goal tile)
5. ✅ Assert: goal_scored = None
   "FT-021: After ball was stolen, piece should NOT score without ball!"
```

---

### Test 4: `test_public_api_multiple_actions_per_turn`
**File**: `tests/public_api_test.rs:2436-2492`

**Turn management:**
```
Setup: White A7 at D4 (ball), M5 at E4, M6 at D3
Actions per turn: 2

Action 1: PASS D4 → E4 (ball to M5)
Action 2: MOVE E4 → E5 (ball holder advances)

✅ Verify actions_remaining decrements correctly
✅ Verify turn_ended flag
```

---

## Test Coverage Summary

| Test | Coverage |
|------|----------|
| All 7 action types | ✅ MOVE, PASS, KICK, INTERCEPT, DEFEND, PUSH, SHOOT |
| FT-021 bug fix | ✅ No goal without ball |
| Interception mechanics | ✅ Ball properly stolen |
| Multi-action turns | ✅ 2 actions per turn flow |

---

## App Integration (Pending)

### Phase 2: Bridge Kickoff State Sync

**Location**: `packages/xfutebol_flutter_bridge/rust/src/api.rs`

1. Add explicit `reset_for_kickoff()` function (if needed)
2. Ensure `clearGoalCelebration()` refreshes board state

### Phase 3: Bot Action Validation

Add pre-validation in `get_bot_action()` to prevent stale paths.

---

## Acceptance Criteria

1. **Goal Validation** (Engine - ✅ Complete):
   - [x] Moving a piece WITHOUT ball into goal zone does NOT score
   - [x] Moving a piece WITH ball into goal zone DOES score
   - [x] Shooting into goal zone DOES score
   - [x] Unit tests pass for all goal scenarios

2. **Kickoff State** (App - Pending):
   - [ ] After goal, board visually resets to kickoff positions
   - [ ] Bot can successfully execute moves after kickoff
   - [ ] No `IllegalPath` errors after kickoff reset

3. **Bot Reliability** (App - Partial):
   - [x] Bot loop stops after 3 consecutive errors (defensive fix)
   - [ ] Bot actions are validated before execution
   - [ ] Invalid bot actions return `None` gracefully

---

## Related Issues

- FT-018: Goal Handling App (original implementation)
- FT-020: Match History Logging (helped diagnose this bug)

## Notes

The match logging (FT-020) was instrumental in identifying these bugs. The `hasBall: false` logging made it clear the piece had lost the ball before scoring.
