# FT-011 Implementation Plan

**Feature:** Engine Integration  
**Created:** December 24, 2025  
**Updated:** December 24, 2025  
**Status:** Ready to Implement  
**Estimated Effort:** ~3 hours  
**Context:** Completes FT-009 (Bridge Package) by wiring to real engine

---

## Current State vs Target

| Aspect | Current | Target |
|--------|---------|--------|
| Engine dependency | ✅ In Cargo.toml | ✅ Done |
| State management | ❌ None | `GAMES` HashMap with `GameMatch` |
| `PieceView.id` | `u8` | `String` ("WG01", "BA01") |
| Type conversions | ❌ None | `From` traits for all types |
| Function implementations | Placeholders (hardcoded) | Real engine calls |
| `execute_pass` | ❌ Missing | New function |
| `execute_shoot` | ❌ Missing | New function |
| `ActionResult` | Basic fields | Add `actions_remaining` |

---

## Engine Method Mapping (from FT-009)

| Dart Function | Engine Method | Notes |
|---------------|---------------|-------|
| `newGame()` | `GameMatch::standard(mode)` + `game.start()` | Store in `GAMES` |
| `getBoard()` | `game.all_pieces()`, `ball_holder()`, `score()` | Build `BoardView` |
| `getLegalMoves()` | `game.piece_by_id()` → `game.legal_moves()` | Returns `Vec<Position>` |
| `executeMove()` | `game.perform_move()` → `ActionOutcome` | Returns `ActionResult` |
| `executePass()` | `game.perform_pass()` → `ActionOutcome` | **NEW** |
| `executeShoot()` | `game.perform_shoot()` → `ActionOutcome` | **NEW** |
| `getBotMove()` | `Bot::new()` + `bot.choose_actions()` | Returns `BotAction` |
| `isGameOver()` | `game.is_over()` | Simple bool |
| `getWinner()` | `game.winner()` | `Option<Team>` |

---

## Piece ID Format

Engine uses stable, semantic IDs:

| ID Pattern | Meaning | Examples |
|------------|---------|----------|
| `W{Role}{Num}` | White piece | `WG01`, `WD01`, `WA01` |
| `B{Role}{Num}` | Black piece | `BG01`, `BD02`, `BA01` |

**Roles:** G=Goalkeeper, D=Defender, M=Midfielder, A=Attacker

No numeric mapping needed — pass strings directly through FFI.

---

## Implementation Checklist

### Phase 1: Dependencies (~10min)

- [ ] Add `once_cell = "1.19"` to Cargo.toml
- [ ] Add `uuid = { version = "1.6", features = ["v4"] }` to Cargo.toml
- [ ] Verify `cargo build` works

### Phase 2: Type Changes (~30min)

#### 2.1 Struct Updates
- [ ] Change `PieceView.id` from `u8` to `String`
- [ ] Add `actions_remaining: u8` to `ActionResult` (matches `ActionOutcome`)

#### 2.2 Conversion Traits
- [ ] `From<xfutebol_engine::Team> for Team`
- [ ] `From<Team> for xfutebol_engine::Team`
- [ ] `From<xfutebol_engine::PieceRole> for PieceRole`
- [ ] `From<PieceRole> for xfutebol_engine::PieceRole`
- [ ] `From<xfutebol_engine::Difficulty> for Difficulty`
- [ ] `From<Difficulty> for xfutebol_engine::Difficulty`
- [ ] `From<xfutebol_engine::BoardTile> for Position`
- [ ] `From<Position> for xfutebol_engine::BoardTile`

#### 2.3 Mode Conversion
- [ ] `GameModeType::QuickMatch` → `GameMode::quick_match()`
- [ ] `GameModeType::StandardMatch` → `GameMode::standard_match()`
- [ ] `GameModeType::GoldenGoal` → `GameMode::golden_goal()`

### Phase 3: State Management (~10min)

- [ ] Add imports for `HashMap`, `Mutex`, `Lazy`
- [ ] Add `use xfutebol_engine::{GameMatch, GameMode, Team as EngineTeam, Bot, Difficulty as EngineDifficulty};`
- [ ] Create `static GAMES: Lazy<Mutex<HashMap<String, GameMatch>>>`

### Phase 4: Function Implementations (~1.5h)

#### 4.1 Game Lifecycle
- [ ] `new_game(mode)` — Create `GameMatch::standard()`, call `start(Team::White)`, store in `GAMES`, return UUID

#### 4.2 Read Operations
- [ ] `get_board(game_id)` — Build `BoardView` from:
  - `game.all_pieces()` → `Vec<PieceView>`
  - `game.ball_holder()` → set `has_ball` flag
  - `game.current_turn()` → `current_turn`
  - `game.actions_remaining()` → `actions_remaining`
  - `game.score()` → `white_score`, `black_score`
  - `game.turn_number()` → `turn_number`
- [ ] `get_legal_moves(game_id, piece_id)` — Use `game.piece_by_id()` then `game.legal_moves(tile)`
- [ ] `is_game_over(game_id)` — Use `game.is_over()`
- [ ] `get_winner(game_id)` — Use `game.winner()`

#### 4.3 Write Operations
- [ ] `execute_move(game_id, piece_id, to)` — Use `game.perform_move(from, to)`
- [ ] `execute_pass(game_id, piece_id, path)` — **NEW** — Use `game.perform_pass(from, path)`
- [ ] `execute_shoot(game_id, piece_id, path)` — **NEW** — Use `game.perform_shoot(from, path)`

#### 4.4 Bot AI
- [ ] `get_bot_move(game_id, difficulty)` — Use `Bot::new(team, difficulty)` and `bot.choose_actions(board, 2)`

#### 4.5 Helper Methods
- [ ] `ActionResult::error(msg: impl Into<String>) -> Self`
- [ ] `ActionResult::from_outcome(outcome: ActionOutcome) -> Self`

### Phase 5: Code Generation (~10min)

- [ ] Run `flutter_rust_bridge_codegen generate`
- [ ] Verify generated Dart files compile
- [ ] Check `PieceView.id` is now `String` in Dart

### Phase 6: Update Tests (~30min)

#### Rust Tests (29 tests)
- [ ] Update `PieceView` construction to use `String` IDs
- [ ] Update `get_legal_moves` tests for `String` piece_id parameter
- [ ] Update `execute_move` tests for `String` piece_id parameter
- [ ] Update `get_bot_move` tests to verify real bot behavior
- [ ] Run `cargo test` — all 29 should pass

#### Dart Tests (57 tests)
- [ ] Update `mock_bridge_api.dart`:
  - Change `id: 0` to `id: "WG01"` etc.
  - Update `pieceId` parameters from `int` to `String`
- [ ] Update `api_contract_test.dart`:
  - Test `PieceView` with `String` id
- [ ] Update `xfutebol_flutter_bridge_test.dart`:
  - Update all `pieceId` usages to `String`
- [ ] Run `flutter test` — all 57 should pass

#### Integration Tests (13 tests)
- [ ] Run on device: `flutter test integration_test/ -d <device>`
- [ ] Verify real engine responses work end-to-end

---

## Files to Modify

| File | Changes |
|------|---------|
| `rust/Cargo.toml` | Add `once_cell`, `uuid` |
| `rust/src/api.rs` | All function implementations, type conversions, state management |
| `lib/src/rust/api.dart` | Regenerated (auto) — verify `String` id |
| `test/mocks/mock_bridge_api.dart` | String piece IDs, update signatures |
| `test/api_contract_test.dart` | String piece IDs in PieceView tests |
| `test/xfutebol_flutter_bridge_test.dart` | String piece IDs in all tests |
| `integration_test/bridge_integration_test.dart` | May need String ID updates |

---

## Key Code Snippets

### State Management

```rust
use std::collections::HashMap;
use std::sync::Mutex;
use once_cell::sync::Lazy;
use uuid::Uuid;
use xfutebol_engine::{GameMatch, GameMode, Team as EngineTeam, Bot, Difficulty as EngineDifficulty};

static GAMES: Lazy<Mutex<HashMap<String, GameMatch>>> = 
    Lazy::new(|| Mutex::new(HashMap::new()));
```

### Type Conversions

```rust
impl From<xfutebol_engine::Team> for Team {
    fn from(t: xfutebol_engine::Team) -> Self {
        match t {
            xfutebol_engine::Team::White => Team::White,
            xfutebol_engine::Team::Black => Team::Black,
            _ => Team::White,
        }
    }
}

impl From<Team> for xfutebol_engine::Team {
    fn from(t: Team) -> Self {
        match t {
            Team::White => xfutebol_engine::Team::White,
            Team::Black => xfutebol_engine::Team::Black,
        }
    }
}

impl From<xfutebol_engine::PieceRole> for PieceRole {
    fn from(r: xfutebol_engine::PieceRole) -> Self {
        match r {
            xfutebol_engine::PieceRole::Goalkeeper => PieceRole::Goalkeeper,
            xfutebol_engine::PieceRole::Defender => PieceRole::Defender,
            xfutebol_engine::PieceRole::Midfielder => PieceRole::Midfielder,
            xfutebol_engine::PieceRole::Attacker => PieceRole::Attacker,
        }
    }
}

impl From<xfutebol_engine::BoardTile> for Position {
    fn from(tile: xfutebol_engine::BoardTile) -> Self {
        let (row, col) = tile.to_coords();
        Position { row, col }
    }
}

impl From<Position> for xfutebol_engine::BoardTile {
    fn from(pos: Position) -> Self {
        xfutebol_engine::BoardTile::from_coords(pos.row, pos.col)
            .expect("Valid position")
    }
}
```

### Updated Structs

```rust
// PieceView with String ID
#[frb]
#[derive(Debug, Clone)]
pub struct PieceView {
    pub id: String,  // "WG01", "BA01", etc.
    pub team: Team,
    pub role: PieceRole,
    pub position: Position,
    pub has_ball: bool,
}

// ActionResult with actions_remaining
#[frb]
#[derive(Debug, Clone)]
pub struct ActionResult {
    pub success: bool,
    pub message: String,
    pub game_over: bool,
    pub winner: Option<Team>,
    pub actions_remaining: u8,  // NEW: matches ActionOutcome
}

impl ActionResult {
    fn error(msg: impl Into<String>) -> Self {
        ActionResult {
            success: false,
            message: msg.into(),
            game_over: false,
            winner: None,
            actions_remaining: 0,
        }
    }
    
    fn from_outcome(outcome: xfutebol_engine::ActionOutcome) -> Self {
        ActionResult {
            success: true,
            message: format!("Action completed"),
            game_over: outcome.game_over,
            winner: outcome.winner.map(Into::into),
            actions_remaining: outcome.actions_remaining,
        }
    }
}
```

### Example Function Implementation

```rust
#[frb]
pub fn new_game(mode: GameModeType) -> String {
    let game_id = Uuid::new_v4().to_string();
    
    let engine_mode = match mode {
        GameModeType::QuickMatch => GameMode::quick_match(),
        GameModeType::StandardMatch => GameMode::standard_match(),
        GameModeType::GoldenGoal => GameMode::golden_goal(),
    };
    
    let mut game = GameMatch::standard(engine_mode);
    game.start(xfutebol_engine::Team::White);
    
    GAMES.lock().unwrap().insert(game_id.clone(), game);
    game_id
}

#[frb]
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
        ball_position: None, // TODO: loose ball position
        current_turn: game.current_turn().into(),
        actions_remaining: game.actions_remaining(),
        white_score: game.score().0,
        black_score: game.score().1,
        turn_number: game.turn_number(),
    }
}
```

---

## Verification Commands

```bash
# Phase 1: Build
cd packages/xfutebol_flutter_bridge/rust
cargo build

# Phase 5: Regenerate bindings
cd packages/xfutebol_flutter_bridge
flutter_rust_bridge_codegen generate

# Phase 6: Run all tests
cd packages/xfutebol_flutter_bridge/rust
cargo test
# Expected: 29 passed

cd packages/xfutebol_flutter_bridge
flutter test
# Expected: 57 passed

flutter test integration_test/ -d <device>
# Expected: 13 passed
```

---

## Success Criteria

- [ ] `cargo build` succeeds with no warnings
- [ ] `cargo test` — 29 tests pass
- [ ] `flutter test` — 57 tests pass  
- [ ] Integration tests — 13 tests pass on device
- [ ] No placeholder/hardcoded data remains in api.rs
- [ ] `PieceView.id` is `String` matching engine format ("WG01", etc.)
- [ ] New functions `execute_pass` and `execute_shoot` work
- [ ] `ActionResult.actions_remaining` is populated correctly
- [ ] `get_board()` returns real piece positions from engine
- [ ] `get_legal_moves()` returns engine-calculated moves
- [ ] `get_bot_move()` returns real AI decisions

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Engine API mismatch | Run `cargo doc --open` in engine to verify methods |
| `BoardTile::from_coords` fails | Add bounds checking (0-7) before conversion |
| Test count changes | Tests may need adjustment for new behavior |
| Integration test failures | May need to update for String IDs before running |

---

## References

- [FT-011 Specification](./ft_011_engine_integration.md)
- [FT-009 Bridge Package Spec](../../../xfutebol-engine/docs/features/ft_009_flutter_bridge_package.md)
- [FT-010 Bridge Tests](./ft_010_bridge_package_tests.md)
- [Engine GameMatch API](../../../xfutebol-engine/docs/features/ft_010_game_match_export.md)
- [Engine Public API](../../../xfutebol-engine/docs/features/ft_007_public_api.md)
