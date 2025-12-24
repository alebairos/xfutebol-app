# Feature Specification: Engine Integration

**Feature ID:** FT-011  
**Status:** Ready  
**Created:** December 24, 2025  
**Priority:** Critical  
**Effort:** ~3 hours  
**Dependencies:**  
- FT-009 (Flutter Bridge Package) ✅  
- FT-010 (Bridge Tests) ✅  
- FT-010-ENGINE (GameMatch Export) ✅ **UNBLOCKED**  

---

## Summary

Wire the placeholder implementations in `xfutebol_flutter_bridge` to the actual `xfutebol-engine` Rust crate. This transforms the bridge from returning mock data to executing real game logic.

**PREREQUISITE COMPLETE:** The engine now exports `GameMatch` and `ActionOutcome` (see `xfutebol-engine/docs/features/ft_010_game_match_export.md`). Implementation can proceed.

---

## Motivation

### Current State

```rust
// api.rs - Placeholder implementation
pub fn get_board(game_id: String) -> BoardView {
    let _ = game_id;  // Ignored!
    
    // Returns hardcoded data
    let mut pieces = Vec::new();
    pieces.push(PieceView { id: 0, ... });
    // ...
}
```

### After Implementation

```rust
// api.rs - Real implementation
pub fn get_board(game_id: String) -> BoardView {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id).expect("Game not found");
    
    // Reads from actual engine state
    BoardView::from_game_match(game)
}
```

---

## Requirements

### 1. State Management

Store active game sessions using the engine's `GameMatch`:

```rust
use std::collections::HashMap;
use std::sync::Mutex;
use once_cell::sync::Lazy;
use xfutebol_engine::GameMatch;

// Game state storage - uses engine's GameMatch directly
static GAMES: Lazy<Mutex<HashMap<String, GameMatch>>> = 
    Lazy::new(|| Mutex::new(HashMap::new()));
```

**No custom GameSession needed** — `GameMatch` handles everything:
- Turn switching
- Action counting  
- Score tracking
- Win condition checking
- Action logging
- Replay/history

### 2. Type Mapping

| Bridge Type | Engine Type | Conversion |
|-------------|-------------|------------|
| `Team` | `xfutebol_engine::Team` | Direct 1:1 |
| `PieceRole` | `xfutebol_engine::PieceRole` | Direct 1:1 |
| `Position` | `xfutebol_engine::BoardTile` | `from_coords(row, col)` |
| `Difficulty` | `xfutebol_engine::Difficulty` | Direct 1:1 |
| `GameModeType` | `xfutebol_engine::GameMode` | Factory methods |
| `String` (piece_id) | `String` (engine piece.id) | **Already compatible!** |

### 3. Piece IDs — Already Solved

The engine uses stable, semantic piece IDs:

```rust
// Engine's Piece.id examples:
"WG01"  // White Goalkeeper #1
"WA01"  // White Attacker #1 (ball holder)
"BD02"  // Black Defender #2
```

The bridge can use these directly as `String`:

```rust
// Bridge type
pub struct PieceView {
    pub id: String,  // Use engine's piece.id directly
    // ...
}
```

No numeric ID mapping needed. No stability issues.

---

## API Function Implementations

With `GameMatch` exported from the engine, implementations become trivial:

### 1. `new_game(mode: GameModeType) -> String`

```rust
use uuid::Uuid;
use xfutebol_engine::{GameMatch, GameMode, Team};

pub fn new_game(mode: GameModeType) -> String {
    let game_id = Uuid::new_v4().to_string();
    
    let engine_mode = match mode {
        GameModeType::QuickMatch => GameMode::quick_match(),
        GameModeType::StandardMatch => GameMode::standard_match(),
        GameModeType::GoldenGoal => GameMode::golden_goal(),
    };
    
    let mut game = GameMatch::standard(engine_mode);
    game.start(Team::White);
    
    GAMES.lock().unwrap().insert(game_id.clone(), game);
    game_id
}
```

### 2. `get_board(game_id: String) -> BoardView`

```rust
pub fn get_board(game_id: String) -> BoardView {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id).expect("Game not found");
    
    let ball_holder_id = game.ball_holder();
    
    let pieces: Vec<PieceView> = game.all_pieces()
        .into_iter()
        .map(|(id, tile, piece)| PieceView {
            id: id.clone(),
            team: piece.team.into(),
            role: piece.role.into(),
            position: Position::from(tile),
            has_ball: ball_holder_id.as_ref() == Some(&id),
        })
        .collect();
    
    BoardView {
        pieces,
        ball_position: game.ball_position().map(Position::from),
        current_turn: game.current_turn().into(),
        actions_remaining: game.actions_remaining(),
        white_score: game.score().0,
        black_score: game.score().1,
        turn_number: game.turn_number() as u8,
    }
}
```

### 3. `get_legal_moves(game_id: String, piece_id: String) -> Vec<Position>`

```rust
pub fn get_legal_moves(game_id: String, piece_id: String) -> Vec<Position> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id).expect("Game not found");
    
    if let Some((tile, _)) = game.piece_by_id(&piece_id) {
        return game.legal_moves(tile)
            .into_iter()
            .map(Position::from)
            .collect();
    }
    
    Vec::new()
}
```

### 4. `execute_move(game_id: String, piece_id: String, to: Position) -> ActionResult`

```rust
pub fn execute_move(game_id: String, piece_id: String, to: Position) -> ActionResult {
    let mut games = GAMES.lock().unwrap();
    let game = games.get_mut(&game_id).expect("Game not found");
    
    let (from_tile, _) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return ActionResult::error("Piece not found"),
    };
    
    match game.perform_move(from_tile, to.into()) {
        Ok(outcome) => ActionResult {
            success: true,
            message: format!("Moved {} to {:?}", outcome.piece_id, outcome.to),
            game_over: outcome.game_over,
            winner: outcome.winner.map(Into::into),
        },
        Err(e) => ActionResult {
            success: false,
            message: format!("{:?}", e),
            game_over: false,
            winner: None,
        },
    }
}
```

### 5. `execute_pass(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult`

```rust
pub fn execute_pass(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    let mut games = GAMES.lock().unwrap();
    let game = games.get_mut(&game_id).expect("Game not found");
    
    let (from_tile, _) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return ActionResult::error("Piece not found"),
    };
    
    let path_tiles: Vec<_> = path.into_iter().map(Into::into).collect();
    
    match game.perform_pass(from_tile, path_tiles) {
        Ok(outcome) => ActionResult::from_outcome(outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}
```

### 6. `execute_shoot(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult`

```rust
pub fn execute_shoot(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    let mut games = GAMES.lock().unwrap();
    let game = games.get_mut(&game_id).expect("Game not found");
    
    let (from_tile, _) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return ActionResult::error("Piece not found"),
    };
    
    let path_tiles: Vec<_> = path.into_iter().map(Into::into).collect();
    
    match game.perform_shoot(from_tile, path_tiles) {
        Ok(outcome) => ActionResult::from_outcome(outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}
```

### 7. `get_bot_move(game_id: String, difficulty: Difficulty) -> Option<BotAction>`

```rust
pub fn get_bot_move(game_id: String, difficulty: Difficulty) -> Option<BotAction> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id).expect("Game not found");
    
    let bot = xfutebol_engine::Bot::new(game.current_turn(), difficulty.into());
    
    bot.choose_move(game.board()).map(|bot_move| BotAction {
        piece_id: bot_move.piece_id.clone(),
        action_type: bot_move.action.into(),
        target: Position::from(bot_move.to),
        path: bot_move.path.into_iter().map(Position::from).collect(),
    })
}
```

### 8. `is_game_over(game_id: String) -> bool`

```rust
pub fn is_game_over(game_id: String) -> bool {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id).expect("Game not found");
    game.is_over()
}
```

### 9. `get_winner(game_id: String) -> Option<Team>`

```rust
pub fn get_winner(game_id: String) -> Option<Team> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id).expect("Game not found");
    game.winner().map(Into::into)
}
```

---

## Dependencies to Add

### Cargo.toml

```toml
[dependencies]
flutter_rust_bridge = "=2.11.1"
xfutebol-engine = { path = "../../../../xfutebol-engine" }
once_cell = "1.19"
uuid = { version = "1.6", features = ["v4"] }
```

---

## Engine API (Available Now ✅)

The engine now exports `GameMatch` and full game orchestration:

```rust
// From xfutebol-engine (lib.rs)
pub use game::game_match::{GameMatch, ActionOutcome};
pub use core::board::{GameBoard, BoardTile, Ball, GameError};
pub use core::pieces::{Piece, Team, PieceRole};
pub use core::bot::{Bot, BotMove, Difficulty};
pub use core::game::{GameMode, GameEnding, GameMatchStatus};
```

**Key GameMatch methods (all implemented):**

| Method | Description |
|--------|-------------|
| `GameMatch::standard(mode)` | Create game with 14-piece setup |
| `game.start(team)` | Start the game |
| `game.all_pieces()` | Get `Vec<(String, BoardTile, Piece)>` |
| `game.piece_by_id(id)` | Find `Option<(BoardTile, Piece)>` |
| `game.team_pieces(team)` | Get pieces for a team |
| `game.legal_moves(tile)` | Get `Vec<BoardTile>` destinations |
| `game.legal_passes(tile)` | Get pass paths |
| `game.legal_shots(tile)` | Get shot paths |
| `game.perform_move(from, to)` | Returns `Result<ActionOutcome, GameError>` |
| `game.perform_pass(from, path)` | Returns `Result<ActionOutcome, GameError>` |
| `game.perform_shoot(from, path)` | Returns `Result<ActionOutcome, GameError>` |
| `game.perform_kick(from, path)` | Returns `Result<ActionOutcome, GameError>` |
| `game.current_turn()` | Get whose turn it is |
| `game.actions_remaining()` | Get actions left this turn |
| `game.score()` | Get `(u8, u8)` white/black score |
| `game.is_over()` | Check game end |
| `game.winner()` | Get `Option<Team>` |
| `game.ball_holder()` | Get `Option<String>` piece ID |

**ActionOutcome struct:**
```rust
pub struct ActionOutcome {
    pub action: Action,
    pub piece_id: String,
    pub from: BoardTile,
    pub to: BoardTile,
    pub path: Vec<BoardTile>,
    pub turn_ended: bool,
    pub goal_scored: Option<Team>,
    pub game_over: bool,
    pub winner: Option<Team>,
    pub actions_remaining: u8,
}
```

**Documentation:** Run `cargo doc --open` in `xfutebol-engine` to browse full API.

---

## Implementation Phases

### Phase 1: Add Dependencies (~30min)

1. Add `once_cell` and `uuid` to Cargo.toml
2. Import `GameMatch` from engine
3. Create `GAMES` static storage

### Phase 2: Type Conversions (~30min)

1. Implement `From` traits for `Team`, `PieceRole`, `Difficulty`
2. Implement `Position ↔ BoardTile` conversion
3. Update `PieceView.id` from `u8` to `String`

### Phase 3: Implement All Functions (~2h)

1. `new_game()` — Create and store GameMatch
2. `get_board()` — Read from GameMatch
3. `get_legal_moves()` — Use `game.legal_moves()`
4. `execute_move()` — Use `game.perform_move()`
5. `execute_pass()` — Use `game.perform_pass()`
6. `execute_shoot()` — Use `game.perform_shoot()`
7. `get_bot_move()` — Use `Bot::choose_move()`
8. `is_game_over()` — Use `game.is_over()`
9. `get_winner()` — Use `game.winner()`

---

## Test Strategy

### Update Rust Tests

Update the 29 Rust tests to verify real engine integration:

```rust
#[test]
fn test_new_game_creates_game_match() {
    let id = new_game(GameModeType::StandardMatch);
    let games = GAMES.lock().unwrap();
    assert!(games.contains_key(&id));
}

#[test]
fn test_get_board_returns_engine_state() {
    let id = new_game(GameModeType::StandardMatch);
    let board = get_board(id);
    
    // Engine's standard setup: 12 pieces (6 per team)
    assert_eq!(board.pieces.len(), 12);
    
    // Verify stable piece IDs from engine
    let white_gk = board.pieces.iter()
        .find(|p| p.id == "WG01")
        .expect("White goalkeeper should exist");
    assert_eq!(white_gk.role, PieceRole::Goalkeeper);
    assert_eq!(white_gk.team, Team::White);
}

#[test]
fn test_execute_move_uses_engine_logic() {
    let id = new_game(GameModeType::StandardMatch);
    
    // Get ball holder (WA01 - White Attacker)
    let board = get_board(id.clone());
    let ball_holder = board.pieces.iter()
        .find(|p| p.has_ball)
        .expect("Someone has the ball");
    
    // Get legal moves from engine
    let moves = get_legal_moves(id.clone(), ball_holder.id.clone());
    assert!(!moves.is_empty(), "Ball holder should have legal moves");
    
    // Execute move through engine
    let result = execute_move(id.clone(), ball_holder.id.clone(), moves[0].clone());
    assert!(result.success);
    
    // Verify state changed
    let board_after = get_board(id);
    let moved_piece = board_after.pieces.iter()
        .find(|p| p.id == ball_holder.id)
        .unwrap();
    assert_eq!(moved_piece.position, moves[0]);
}
```

### Integration Tests

Existing integration tests should pass with no changes:

```bash
flutter test integration_test/bridge_integration_test.dart -d <device>
```

---

## Acceptance Criteria

- [ ] `new_game()` creates real `GameSession` in storage
- [ ] `get_board()` returns actual engine board state
- [ ] `get_legal_moves()` returns engine-calculated moves
- [ ] `execute_move()` mutates game state correctly
- [ ] `get_bot_move()` uses engine's `Bot` AI
- [ ] `is_game_over()` checks real game ending conditions
- [ ] `get_winner()` returns correct winner
- [ ] All 29 Rust unit tests updated and passing
- [ ] Integration tests pass on device
- [ ] No placeholder/hardcoded data remains

---

## Timeline

| Phase | Task | Estimate |
|-------|------|----------|
| 1 | Add dependencies | 30min |
| 2 | Type conversions | 30min |
| 3 | Implement all functions | 2h |
| **Total** | | **~3h** |

**Ready to implement.** FT-010-ENGINE (GameMatch Export) is complete.

---

## Acceptance Criteria

- [ ] `GameMatch` from engine is used (no custom GameSession)
- [ ] Piece IDs are strings matching engine's format (e.g., "WA01")
- [ ] All action types supported: move, pass, shoot
- [ ] All 29 Rust tests pass with real engine
- [ ] Integration tests pass on device
- [ ] No placeholder/hardcoded data remains

---

## API Changes from Placeholder

| Function | Before (Placeholder) | After (Real) |
|----------|---------------------|--------------|
| `piece_id` type | `u8` | `String` ("WA01") |
| `get_legal_moves` | Hardcoded 3 positions | Engine-calculated |
| `execute_move` | Always success | Engine validation |
| `get_bot_move` | Fixed (7, (5,2)) | Real Bot AI |
| NEW: `execute_pass` | N/A | Added |
| NEW: `execute_shoot` | N/A | Added |

---

## References

- [FT-009: Flutter Bridge Package](./ft_009_flutter_bridge_package.md)
- [FT-010: Bridge Package Tests](./ft_010_bridge_package_tests.md)
- [FT-010-ENGINE: GameMatch Export](../../../xfutebol-engine/docs/features/ft_010_game_match_export.md) ✅ COMPLETE
- [xfutebol-engine Public API](../../../xfutebol-engine/docs/features/ft_007_public_api.md)
- [Engine Rustdoc](../../../xfutebol-engine/target/doc/xfutebol_engine/index.html) (run `cargo doc`)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2025-12-24 | Initial specification |
| 0.2.0 | 2025-12-24 | Simplified after FT-010-ENGINE spec; removed workarounds |
| 0.3.0 | 2025-12-24 | **UNBLOCKED** - FT-010-ENGINE complete; updated API reference |

