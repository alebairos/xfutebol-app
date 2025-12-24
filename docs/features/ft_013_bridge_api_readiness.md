# Feature Specification: Bridge API Readiness Analysis

**Feature ID:** FT-013  
**Status:** Analysis Complete  
**Created:** December 24, 2025  
**Priority:** Informational  
**Dependencies:**  
- FT-011 (Engine Integration) ✅ COMPLETE
- FT-012 (Bridge API Gaps) ✅ COMPLETE

---

## Summary

Analysis of whether the current `xfutebol_flutter_bridge` API is sufficient to implement the Flutter app, based on the requirements in `game_development_plan.md`.

### Overall Verdict

| Criteria | Status |
|----------|--------|
| **Phase 1 Ready?** | ✅ Yes |
| **API Completeness** | ✅ **All 7 engine actions exposed** (FT-014 complete) |

---

## Engine Actions Coverage

The xfutebol-engine supports **7 action types**. Current bridge coverage:

| Engine Action | In ActionType Enum | Has Execute Function | Has GetLegal Function |
|---------------|:------------------:|:--------------------:|:---------------------:|
| **MOVE** | ✅ | ✅ `executeMove` | ✅ `getLegalMoves` |
| **PASS** | ✅ | ✅ `executePass` | ✅ `getLegalPasses` |
| **SHOOT** | ✅ | ✅ `executeShoot` | ✅ `getLegalShoots` |
| **INTERCEPT** | ✅ | ✅ `executeIntercept` | ✅ `getLegalIntercepts` |
| **KICK** | ✅ | ✅ `executeKick` | ✅ `getLegalKicks` |
| **DEFEND** | ✅ | ✅ `executeDefend` | ✅ `getLegalDefends` |
| **PUSH** | ✅ | ✅ `executePush` | ✅ `getLegalPushes` |

### Full Engine Coverage ✅

All 7 engine actions are now exposed in the bridge API (completed in FT-014):

| Action | Execute Function | GetLegal Function |
|--------|------------------|-------------------|
| MOVE | `executeMove` | `getLegalMoves` |
| PASS | `executePass` | `getLegalPasses` |
| SHOOT | `executeShoot` | `getLegalShoots` |
| INTERCEPT | `executeIntercept` | `getLegalIntercepts` |
| KICK | `executeKick` | `getLegalKicks` |
| DEFEND | `executeDefend` | `getLegalDefends` |
| PUSH | `executePush` | `getLegalPushes` |

**All actions are available for both players and bot AI.**

---

## Current Bridge API

### Game Management

| Function | Return Type | Description |
|----------|-------------|-------------|
| `newGame(mode)` | `String` | Create a new game, returns game ID |
| `gameExists(gameId)` | `bool` | Check if game exists |
| `deleteGame(gameId)` | `bool` | Clean up game memory |

### Board State

| Function | Return Type | Description |
|----------|-------------|-------------|
| `getBoard(gameId)` | `BoardView?` | Current board state |

**BoardView contains:**
- `pieces: List<PieceView>` - All 14 pieces with positions
- `ballPosition: Position?` - Ball location
- `currentTurn: Team` - Whose turn (white/black)
- `actionsRemaining: int` - Actions left this turn (0-2)
- `whiteScore: int` - White team goals
- `blackScore: int` - Black team goals
- `turnNumber: int` - Current turn number

### Legal Actions

| Function | Return Type | Description |
|----------|-------------|-------------|
| `getLegalMoves(gameId, pieceId)` | `List<Position>` | Valid move destinations |
| `getLegalPasses(gameId, pieceId)` | `List<PositionPath>` | Valid pass paths |
| `getLegalShoots(gameId, pieceId)` | `List<PositionPath>` | Valid shoot paths |

### Execute Actions

| Function | Return Type | Description |
|----------|-------------|-------------|
| `executeMove(gameId, pieceId, to)` | `ActionResult` | Execute a move |
| `executePass(gameId, pieceId, path)` | `ActionResult` | Execute a pass |
| `executeShoot(gameId, pieceId, path)` | `ActionResult` | Execute a shoot |

**ActionResult contains:**
- `success: bool` - Whether action succeeded
- `message: String` - Result message
- `gameOver: bool` - Whether game ended
- `winner: Team?` - Winner if game over
- `actionsRemaining: int` - Actions left after this action

### Bot/AI

| Function | Return Type | Description |
|----------|-------------|-------------|
| `getBotMove(gameId, difficulty)` | `(String, Position)?` | Bot's move (deprecated) |
| `getBotAction(gameId, difficulty)` | `BotAction?` | Full bot action with type and path |

**BotAction contains:**
- `pieceId: String` - Which piece to move
- `actionType: ActionType` - Move, Pass, Shoot, or Intercept
- `path: List<Position>` - Full path for the action

### Game State

| Function | Return Type | Description |
|----------|-------------|-------------|
| `isGameOver(gameId)` | `bool` | Check if game ended |
| `getWinner(gameId)` | `Team?` | Get winner if game over |

### Enums

| Enum | Values |
|------|--------|
| `Team` | white, black |
| `PieceRole` | goalkeeper, defender, midfielder, attacker |
| `GameModeType` | quickMatch, standardMatch, goldenGoal |
| `Difficulty` | easy, medium |
| `ActionType` | move, pass, shoot, intercept |

---

## Phase 1 Requirements Analysis

**Goal:** Kids can play against the bot on a phone/tablet.

| Requirement | API Available | Status |
|-------------|---------------|--------|
| Create new game | `newGame(mode)` | ✅ |
| Get board state | `getBoard(gameId)` | ✅ |
| Display pieces | `BoardView.pieces` | ✅ |
| Show current turn | `BoardView.currentTurn` | ✅ |
| Show scores | `BoardView.whiteScore/blackScore` | ✅ |
| Get legal moves | `getLegalMoves(gameId, pieceId)` | ✅ |
| Get legal passes | `getLegalPasses(gameId, pieceId)` | ✅ |
| Get legal shoots | `getLegalShoots(gameId, pieceId)` | ✅ |
| Execute move | `executeMove(gameId, pieceId, to)` | ✅ |
| Execute pass | `executePass(gameId, pieceId, path)` | ✅ |
| Execute shoot | `executeShoot(gameId, pieceId, path)` | ✅ |
| Bot makes moves | `getBotAction(gameId, difficulty)` | ✅ |
| Detect game over | `isGameOver(gameId)` | ✅ |
| Get winner | `getWinner(gameId)` | ✅ |
| Clean up games | `deleteGame(gameId)` | ✅ |

**Phase 1 Verdict: ✅ READY TO BUILD**

---

## Phase 2 Requirements Analysis

**Goal:** A polished single-player experience.

| Requirement | API Available | Status |
|-------------|---------------|--------|
| Multiple bot difficulties | `Difficulty.easy/medium` | ✅ |
| Game mode selection | `GameModeType.*` | ✅ |
| Undo last move | - | ❌ NOT AVAILABLE |
| Match history navigation | - | ❌ NOT AVAILABLE |

**Phase 2 Verdict: ⚠️ MOSTLY READY (missing undo/history)**

---

## Missing APIs for Future Phases

### Full Action Coverage (Phase 1.5 - Optional Enhancement)

To expose all 7 engine actions, add:

```rust
// In api.rs - Add to ActionType enum:
pub enum ActionType {
    Move,
    Pass,
    Shoot,
    Intercept,
    Kick,      // NEW
    Defend,    // NEW
    Tackle,    // NEW
}

// Add execute functions for missing actions:
pub fn execute_intercept(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult;
pub fn execute_kick(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult;
pub fn execute_defend(game_id: String, piece_id: String, to: Position) -> ActionResult;
pub fn execute_tackle(game_id: String, piece_id: String, target: Position) -> ActionResult;

// Add getLegal functions:
pub fn get_legal_intercepts(game_id: String, piece_id: String) -> Vec<PositionPath>;
pub fn get_legal_kicks(game_id: String, piece_id: String) -> Vec<PositionPath>;
pub fn get_legal_defends(game_id: String, piece_id: String) -> Vec<Position>;
pub fn get_legal_tackles(game_id: String, piece_id: String) -> Vec<Position>;
```

**Priority:** Low for Phase 1. The bot uses all actions internally, so gameplay is complete. Player-facing UI for these actions can be added later.

### Undo/History (Phase 2)

```dart
// Proposed APIs needed:
Future<bool> undoLastAction({required String gameId});
Future<List<GameAction>> getMoveHistory({required String gameId});
Future<bool> goToPosition({required String gameId, required int moveIndex});
```

### Online Multiplayer (Phase 3)

The current bridge is designed for local single-player. Phase 3 will require a separate backend server for online play, not bridge extensions.

---

## Conclusion

### Can Start Building Now? ✅ YES

The bridge API is **complete** and provides:
- Complete game lifecycle management
- Full board state access
- All 7 action types (move, pass, shoot, intercept, kick, defend, push)
- Bot AI with configurable difficulty
- Game over detection and winner determination

### What to Build First

1. **Board Widget** - 8x8 grid displaying pieces from `BoardView`
2. **Piece Selection** - Tap to select, call `getLegalMoves/Passes/Shoots/etc.`
3. **Move Execution** - Tap destination, call appropriate `execute*` function
4. **Bot Turn** - After player, call `getBotAction` and animate
5. **Game HUD** - Turn indicator, scores, actions remaining
6. **Win Screen** - Check `isGameOver`, show `getWinner`

### Future Work

| Phase | Feature | Effort |
|-------|---------|--------|
| 2 | Undo functionality | ~4 hours |
| 2 | Move history navigation | ~4 hours |

---

## References

- [FT-011: Engine Integration](./ft_011_engine_integration.md)
- [FT-012: Bridge API Gaps](./ft_012_bridge_api_gaps.md)
- [Game Development Plan](../prototype/game_development_plan.md)
- [Bridge API Source](../../packages/xfutebol_flutter_bridge/lib/src/rust/api.dart)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-24 | Initial analysis |

