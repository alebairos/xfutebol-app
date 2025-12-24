# Feature Specification: Bridge API Gaps

**Feature ID:** FT-012  
**Status:** Complete ✅  
**Created:** December 24, 2025  
**Completed:** December 24, 2025  
**Priority:** High  
**Effort:** ~2 hours  
**Dependencies:**  
- FT-011 (Engine Integration) ✅ COMPLETE

---

## Summary

Fill gaps in the `xfutebol_flutter_bridge` API to enable complete gameplay testing and reliable UI implementation. The current API lacks essential functions for:

1. Getting bot actions with full action type and path
2. Getting legal pass/shoot paths for pieces
3. Cleaning up game sessions
4. Safe error handling for invalid game IDs

---

## Gap Analysis

### Gap 1: Incomplete Bot Action Return

**Current State:**
```rust
pub fn get_bot_move(game_id: String, difficulty: Difficulty) -> Option<(String, Position)>
```

**Problem:** Returns only piece ID and final position. Loses:
- Action type (MOVE vs PASS vs SHOOT vs INTERCEPT)
- Full path for PASS/SHOOT actions
- Cannot correctly execute the bot's chosen action

**Impact:** UI cannot reliably execute bot turns when bot chooses PASS or SHOOT.

---

### Gap 2: Missing Legal Pass/Shoot Paths

**Current State:**
```rust
pub fn get_legal_moves(game_id: String, piece_id: String) -> Vec<Position>
```

**Problem:** Only returns legal move destinations. No API for:
- `get_legal_passes` - Valid pass target paths
- `get_legal_shoots` - Valid shoot paths toward goal

**Impact:** UI cannot show valid pass/shoot options to player.

---

### Gap 3: No Game Cleanup

**Current State:**
```rust
static GAMES: Lazy<Mutex<HashMap<String, GameMatch>>> = ...
```

**Problem:** No way to remove completed games from memory.

**Impact:** Memory leak in long sessions or many games.

---

### Gap 4: Panic on Invalid Game ID

**Current State:**
```rust
let game = games.get(&game_id).expect("Game not found");  // PANICS!
```

**Problem:** Functions panic if game_id doesn't exist. Should return error gracefully.

**Impact:** App crashes if game_id is invalid (e.g., after app restart).

---

## Implementation

### 1. Add ActionType Enum

```rust
/// Action types available in the game
#[frb]
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ActionType {
    Move,
    Pass,
    Shoot,
    Intercept,
}

impl From<xfutebol_engine::Action> for ActionType {
    fn from(a: xfutebol_engine::Action) -> Self {
        match a {
            xfutebol_engine::Action::MOVE => ActionType::Move,
            xfutebol_engine::Action::PASS => ActionType::Pass,
            xfutebol_engine::Action::SHOOT => ActionType::Shoot,
            xfutebol_engine::Action::INTERCEPT => ActionType::Intercept,
            _ => ActionType::Move, // Fallback
        }
    }
}
```

### 2. Add BotAction Struct

```rust
/// A complete action returned by the bot AI
#[frb]
#[derive(Debug, Clone)]
pub struct BotAction {
    pub piece_id: String,
    pub action_type: ActionType,
    pub path: Vec<Position>,  // Full path for the action
}
```

### 3. Replace get_bot_move with get_bot_action

```rust
/// Get the bot's recommended action for the current position
#[frb]
pub fn get_bot_action(game_id: String, difficulty: Difficulty) -> Option<BotAction> {
    let games = GAMES.lock().unwrap();
    let game = match games.get(&game_id) {
        Some(g) => g,
        None => return None,
    };
    
    let bot = Bot::new(game.current_turn(), difficulty.into());
    let actions = bot.choose_actions(game.board(), 1);
    
    actions.first().map(|bot_move| {
        let piece_id = game.all_pieces()
            .into_iter()
            .find(|(_, tile, _)| *tile == bot_move.piece_tile)
            .map(|(id, _, _)| id)
            .unwrap_or_default();
        
        BotAction {
            piece_id,
            action_type: bot_move.action.into(),
            path: bot_move.path.iter().map(|t| Position::from(*t)).collect(),
        }
    })
}
```

### 4. Add get_legal_passes

```rust
/// Get legal pass paths for a piece (must have ball)
#[frb]
pub fn get_legal_passes(game_id: String, piece_id: String) -> Vec<Vec<Position>> {
    let games = GAMES.lock().unwrap();
    let game = match games.get(&game_id) {
        Some(g) => g,
        None => return Vec::new(),
    };
    
    let (tile, piece) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return Vec::new(),
    };
    
    game.board()
        .get_legal_moves(&piece, xfutebol_engine::Action::PASS, tile, true)
        .into_iter()
        .map(|path| path.into_iter().map(Position::from).collect())
        .collect()
}
```

### 5. Add get_legal_shoots

```rust
/// Get legal shoot paths for a piece (must have ball)
#[frb]
pub fn get_legal_shoots(game_id: String, piece_id: String) -> Vec<Vec<Position>> {
    let games = GAMES.lock().unwrap();
    let game = match games.get(&game_id) {
        Some(g) => g,
        None => return Vec::new(),
    };
    
    let (tile, piece) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return Vec::new(),
    };
    
    game.board()
        .get_legal_moves(&piece, xfutebol_engine::Action::SHOOT, tile, true)
        .into_iter()
        .map(|path| path.into_iter().map(Position::from).collect())
        .collect()
}
```

### 6. Add delete_game

```rust
/// Delete a game session and free memory
#[frb]
pub fn delete_game(game_id: String) -> bool {
    let mut games = GAMES.lock().unwrap();
    games.remove(&game_id).is_some()
}
```

### 7. Add game_exists Check

```rust
/// Check if a game exists
#[frb]
pub fn game_exists(game_id: String) -> bool {
    let games = GAMES.lock().unwrap();
    games.contains_key(&game_id)
}
```

### 8. Fix Panic Points (Return Option/Result)

Update all functions to handle missing game gracefully:

```rust
/// Get the current board state for display
#[frb]
pub fn get_board(game_id: String) -> Option<BoardView> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id)?;
    
    // ... rest of implementation
    Some(BoardView { ... })
}
```

**Functions to update:**
- `get_board` → `Option<BoardView>`
- `get_legal_moves` → Already returns empty vec (OK)
- `execute_move` → Already returns ActionResult with error (OK)
- `is_game_over` → `Option<bool>` or default to `true`
- `get_winner` → Already returns Option (OK, but should distinguish None from game-not-found)

---

## API Summary After Changes

### New Types

| Type | Description |
|------|-------------|
| `ActionType` | Enum: Move, Pass, Shoot, Intercept |
| `BotAction` | Struct with piece_id, action_type, path |

### New Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `get_bot_action` | `Option<BotAction>` | Complete bot action with type and path |
| `get_legal_passes` | `Vec<Vec<Position>>` | All valid pass paths |
| `get_legal_shoots` | `Vec<Vec<Position>>` | All valid shoot paths |
| `delete_game` | `bool` | Remove game, returns success |
| `game_exists` | `bool` | Check if game ID is valid |

### Modified Functions

| Function | Old Return | New Return |
|----------|------------|------------|
| `get_board` | `BoardView` | `Option<BoardView>` |
| `get_bot_move` | Keep for compatibility or deprecate |

---

## Testing Requirements

### Rust Tests

```rust
#[test]
fn test_get_bot_action_returns_full_action() {
    let id = new_game(GameModeType::StandardMatch);
    let action = get_bot_action(id, Difficulty::Medium);
    
    assert!(action.is_some());
    let bot_action = action.unwrap();
    assert!(!bot_action.piece_id.is_empty());
    assert!(!bot_action.path.is_empty());
}

#[test]
fn test_get_legal_passes_for_ball_holder() {
    let id = new_game(GameModeType::StandardMatch);
    let board = get_board(id.clone()).unwrap();
    let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
    
    let passes = get_legal_passes(id, ball_holder.id.clone());
    // Ball holder should have pass options
    assert!(!passes.is_empty());
}

#[test]
fn test_delete_game_frees_memory() {
    let id = new_game(GameModeType::StandardMatch);
    assert!(game_exists(id.clone()));
    
    assert!(delete_game(id.clone()));
    assert!(!game_exists(id));
}

#[test]
fn test_get_board_invalid_id_returns_none() {
    let board = get_board("invalid_game_id".to_string());
    assert!(board.is_none());
}
```

### Dart Tests

```dart
test('get_bot_action returns complete action', () async {
  final gameId = await newGame(mode: GameModeType.standardMatch);
  final action = await getBotAction(gameId: gameId, difficulty: Difficulty.medium);
  
  expect(action, isNotNull);
  expect(action!.pieceId, isNotEmpty);
  expect(action.actionType, isA<ActionType>());
  expect(action.path, isNotEmpty);
});

test('get_legal_passes returns paths for ball holder', () async {
  final gameId = await newGame(mode: GameModeType.standardMatch);
  final board = await getBoard(gameId: gameId);
  final ballHolder = board!.pieces.firstWhere((p) => p.hasBall);
  
  final passes = await getLegalPasses(gameId: gameId, pieceId: ballHolder.id);
  expect(passes, isNotEmpty);
});

test('delete_game cleans up memory', () async {
  final gameId = await newGame(mode: GameModeType.standardMatch);
  expect(await gameExists(gameId: gameId), isTrue);
  
  expect(await deleteGame(gameId: gameId), isTrue);
  expect(await gameExists(gameId: gameId), isFalse);
});
```

---

## Migration Notes

### Breaking Changes

1. `get_board` returns `Option<BoardView>` - callers must handle `null`
2. `get_bot_move` deprecated in favor of `get_bot_action`

### Dart Side Updates

After regenerating bindings, update:
- `MockXfutebolBridgeApi` with new function signatures
- Existing tests to handle nullable `getBoard`
- Add tests for new functions

---

## Acceptance Criteria

- [x] `ActionType` enum exposed to Dart
- [x] `BotAction` struct with piece_id, action_type, path
- [x] `get_bot_action` returns complete bot decision
- [x] `get_legal_passes` returns all valid pass paths (as `Vec<PositionPath>`)
- [x] `get_legal_shoots` returns all valid shoot paths (as `Vec<PositionPath>`)
- [x] `delete_game` removes game from memory
- [x] `game_exists` checks game validity
- [x] `get_board` returns `Option<BoardView>`
- [x] All Rust tests pass (53 tests)
- [x] Dart bindings regenerated
- [x] Mock updated for Dart tests
- [x] All Dart tests pass (96 tests)

---

## References

- [FT-011: Engine Integration](./ft_011_engine_integration.md) ✅
- [xfutebol-engine Bot](../../../xfutebol-engine/src/core/bot.rs)
- [xfutebol-engine Actions](../../../xfutebol-engine/src/core/actions.rs)

---

## Implementation Notes

### PositionPath Wrapper

The original design specified returning `Vec<Vec<Position>>` for pass/shoot paths. However, flutter_rust_bridge codegen has a bug with nested vectors. **Workaround:** Added a `PositionPath` wrapper struct, so functions return `Vec<PositionPath>` instead.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2025-12-24 | Initial specification |
| 1.0.0 | 2025-12-24 | Implementation complete with PositionPath workaround |

