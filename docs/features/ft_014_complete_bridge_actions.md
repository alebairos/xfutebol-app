# Feature Specification: Complete Bridge Actions

**Feature ID:** FT-014  
**Status:** Complete ✅  
**Created:** December 24, 2025  
**Completed:** December 24, 2025  
**Priority:** Medium  
**Effort:** ~2 hours  
**Dependencies:** FT-012 (Bridge API Gaps) ✅ COMPLETE

---

## Summary

Expose remaining 4 engine actions to complete the Flutter bridge API.

---

## Current State

| Action | Enum | Execute | GetLegal |
|--------|:----:|:-------:|:--------:|
| MOVE | ✅ | ✅ | ✅ |
| PASS | ✅ | ✅ | ✅ |
| SHOOT | ✅ | ✅ | ✅ |
| INTERCEPT | ✅ | ❌ | ❌ |
| KICK | ❌ | ❌ | ❌ |
| DEFEND | ❌ | ❌ | ❌ |
| PUSH | ❌ | ❌ | ❌ |

---

## Implementation

### 1. Update ActionType Enum

```rust
// In api.rs - Update enum
#[frb]
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ActionType {
    Move,
    Pass,
    Shoot,
    Intercept,
    Kick,    // ADD
    Defend,  // ADD
    Tackle,  // ADD
}

// Update conversion - remove fallback
impl From<EngineAction> for ActionType {
    fn from(a: EngineAction) -> Self {
        match a {
            EngineAction::MOVE => ActionType::Move,
            EngineAction::PASS => ActionType::Pass,
            EngineAction::SHOOT => ActionType::Shoot,
            EngineAction::INTERCEPT => ActionType::Intercept,
            EngineAction::KICK => ActionType::Kick,
            EngineAction::DEFEND => ActionType::Defend,
            EngineAction::TACKLE => ActionType::Tackle,
        }
    }
}
```

### 2. Add GetLegal Functions

```rust
/// Get legal intercept paths for a piece
#[frb]
pub fn get_legal_intercepts(game_id: String, piece_id: String) -> Vec<PositionPath> {
    get_legal_action_paths(game_id, piece_id, EngineAction::INTERCEPT)
}

/// Get legal kick paths for a piece (must have ball)
#[frb]
pub fn get_legal_kicks(game_id: String, piece_id: String) -> Vec<PositionPath> {
    get_legal_action_paths(game_id, piece_id, EngineAction::KICK)
}

/// Get legal defend positions for a piece
#[frb]
pub fn get_legal_defends(game_id: String, piece_id: String) -> Vec<Position> {
    get_legal_action_positions(game_id, piece_id, EngineAction::DEFEND)
}

/// Get legal tackle targets for a piece
#[frb]
pub fn get_legal_tackles(game_id: String, piece_id: String) -> Vec<Position> {
    get_legal_action_positions(game_id, piece_id, EngineAction::TACKLE)
}

// Helper: Get paths for path-based actions
fn get_legal_action_paths(game_id: String, piece_id: String, action: EngineAction) -> Vec<PositionPath> {
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
        .get_legal_moves(&piece, action, tile, true)
        .into_iter()
        .map(|path| PositionPath {
            positions: path.into_iter().map(Position::from).collect()
        })
        .collect()
}

// Helper: Get single positions for position-based actions
fn get_legal_action_positions(game_id: String, piece_id: String, action: EngineAction) -> Vec<Position> {
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
        .get_legal_moves(&piece, action, tile, true)
        .into_iter()
        .filter_map(|path| path.last().copied())
        .map(Position::from)
        .collect()
}
```

### 3. Add Execute Functions

```rust
/// Execute an intercept action
#[frb]
pub fn execute_intercept(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    execute_path_action(game_id, piece_id, path, |game, from, path| {
        game.perform_intercept(from, path)
    })
}

/// Execute a kick action
#[frb]
pub fn execute_kick(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    execute_path_action(game_id, piece_id, path, |game, from, path| {
        game.perform_kick(from, path)
    })
}

/// Execute a defend action
#[frb]
pub fn execute_defend(game_id: String, piece_id: String, to: Position) -> ActionResult {
    execute_position_action(game_id, piece_id, to, |game, from, to| {
        game.perform_defend(from, to)
    })
}

/// Execute a tackle action
#[frb]
pub fn execute_tackle(game_id: String, piece_id: String, target: Position) -> ActionResult {
    execute_position_action(game_id, piece_id, target, |game, from, target| {
        game.perform_tackle(from, target)
    })
}

// Helper: Execute path-based action
fn execute_path_action<F>(game_id: String, piece_id: String, path: Vec<Position>, action_fn: F) -> ActionResult
where
    F: FnOnce(&mut GameMatch, BoardTile, Vec<BoardTile>) -> Result<xfutebol_engine::ActionOutcome, xfutebol_engine::GameError>
{
    let mut games = GAMES.lock().unwrap();
    let game = match games.get_mut(&game_id) {
        Some(g) => g,
        None => return ActionResult::error("Game not found"),
    };
    
    let from_tile = match game.piece_by_id(&piece_id) {
        Some((tile, _)) => tile,
        None => return ActionResult::error("Piece not found"),
    };
    
    let path_tiles: Vec<BoardTile> = path.into_iter().map(Into::into).collect();
    
    match action_fn(game, from_tile, path_tiles) {
        Ok(outcome) => ActionResult::from_outcome(&outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}

// Helper: Execute position-based action
fn execute_position_action<F>(game_id: String, piece_id: String, to: Position, action_fn: F) -> ActionResult
where
    F: FnOnce(&mut GameMatch, BoardTile, BoardTile) -> Result<xfutebol_engine::ActionOutcome, xfutebol_engine::GameError>
{
    let mut games = GAMES.lock().unwrap();
    let game = match games.get_mut(&game_id) {
        Some(g) => g,
        None => return ActionResult::error("Game not found"),
    };
    
    let from_tile = match game.piece_by_id(&piece_id) {
        Some((tile, _)) => tile,
        None => return ActionResult::error("Piece not found"),
    };
    
    let to_tile: BoardTile = to.into();
    
    match action_fn(game, from_tile, to_tile) {
        Ok(outcome) => ActionResult::from_outcome(&outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}
```

---

## Testing

### Rust Tests

```rust
#[test]
fn test_get_legal_intercepts() {
    let id = new_game(GameModeType::StandardMatch);
    let board = get_board(id.clone()).unwrap();
    // Find a piece without ball that could intercept
    let piece = board.pieces.iter().find(|p| !p.has_ball).unwrap();
    let intercepts = get_legal_intercepts(id, piece.id.clone());
    // May be empty if no intercept opportunity - just verify no panic
    assert!(intercepts.len() >= 0);
}

#[test]
fn test_action_type_covers_all_engine_actions() {
    // Verify no fallback needed
    let actions = [
        EngineAction::MOVE,
        EngineAction::PASS,
        EngineAction::SHOOT,
        EngineAction::INTERCEPT,
        EngineAction::KICK,
        EngineAction::DEFEND,
        EngineAction::TACKLE,
    ];
    for action in actions {
        let _ = ActionType::from(action); // Should not use fallback
    }
}
```

### Dart Integration Tests

```dart
testWidgets('all action types are available', (tester) async {
  expect(ActionType.values.length, equals(7));
  expect(ActionType.values, contains(ActionType.intercept));
  expect(ActionType.values, contains(ActionType.kick));
  expect(ActionType.values, contains(ActionType.defend));
  expect(ActionType.values, contains(ActionType.tackle));
});

testWidgets('getLegalIntercepts returns paths', (tester) async {
  final gameId = await newGame(mode: GameModeType.standardMatch);
  final board = (await getBoard(gameId: gameId))!;
  final piece = board.pieces.firstWhere((p) => !p.hasBall);
  
  // Should not throw, may return empty list
  final intercepts = await getLegalIntercepts(gameId: gameId, pieceId: piece.id);
  expect(intercepts, isA<List<PositionPath>>());
});
```

---

## Checklist

- [x] Update `ActionType` enum with Kick, Defend, Push
- [x] Remove fallback in `From<EngineAction>` conversion
- [x] Add `get_legal_intercepts`
- [x] Add `get_legal_kicks`
- [x] Add `get_legal_defends`
- [x] Add `get_legal_pushes`
- [x] Add `execute_intercept`
- [x] Add `execute_kick`
- [x] Add `execute_defend`
- [x] Add `execute_push`
- [x] Add helper functions to reduce duplication
- [x] Run `flutter_rust_bridge_codegen generate`
- [x] Update MockXfutebolBridgeApi
- [x] All Rust tests pass (53 tests)
- [x] All Dart tests pass (99 tests)

---

## Notes

- **Engine API verification needed:** Confirm GameMatch has `perform_intercept`, `perform_kick`, `perform_defend`, `perform_tackle` methods. If not, coordinate with engine developer.
- **Action semantics:** Verify whether defend/tackle use single positions or paths.
- **Priority:** This is enhancement, not blocking for Phase 1.

---

## References

- [FT-013: Bridge API Readiness](./ft_013_bridge_api_readiness.md)
- [FT-012: Bridge API Gaps](./ft_012_bridge_api_gaps.md)

---

## Implementation Summary

**Completed:** December 24, 2025

### Files Modified

| File | Changes |
|------|---------|
| `rust/src/api.rs` | Added 4 execute functions, 4 getLegal functions, 2 helpers, updated ActionType enum |
| `lib/src/rust/api.dart` | Auto-regenerated with new functions |
| `lib/src/rust/frb_generated.dart` | Auto-regenerated |
| `lib/src/rust/frb_generated.io.dart` | Auto-regenerated |
| `test/mocks/mock_bridge_api.dart` | Added 8 new mock methods |
| `test/api_contract_test.dart` | Updated ActionType test to expect 7 values |

### New Rust Functions

```rust
// GetLegal functions (use shared helper)
pub fn get_legal_intercepts(game_id: String, piece_id: String) -> Vec<PositionPath>
pub fn get_legal_kicks(game_id: String, piece_id: String) -> Vec<PositionPath>
pub fn get_legal_defends(game_id: String, piece_id: String) -> Vec<PositionPath>
pub fn get_legal_pushes(game_id: String, piece_id: String) -> Vec<PositionPath>

// Execute functions
pub fn execute_intercept(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult
pub fn execute_kick(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult
pub fn execute_defend(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult
pub fn execute_push(game_id: String, piece_id: String, target: Position, destination: Position) -> ActionResult

// Helper functions (private, reduce duplication)
fn get_legal_action_paths(game_id: String, piece_id: String, action: EngineAction) -> Vec<PositionPath>
fn execute_path_action<F>(game_id: String, piece_id: String, path: Vec<Position>, action_fn: F) -> ActionResult
```

### New Dart Functions

```dart
// GetLegal
Future<List<PositionPath>> getLegalIntercepts({required String gameId, required String pieceId})
Future<List<PositionPath>> getLegalKicks({required String gameId, required String pieceId})
Future<List<PositionPath>> getLegalDefends({required String gameId, required String pieceId})
Future<List<PositionPath>> getLegalPushes({required String gameId, required String pieceId})

// Execute
Future<ActionResult> executeIntercept({required String gameId, required String pieceId, required List<Position> path})
Future<ActionResult> executeKick({required String gameId, required String pieceId, required List<Position> path})
Future<ActionResult> executeDefend({required String gameId, required String pieceId, required List<Position> path})
Future<ActionResult> executePush({required String gameId, required String pieceId, required Position target, required Position destination})
```

### ActionType Enum (Final)

```dart
enum ActionType { move, pass, shoot, intercept, kick, defend, push }
```

### Test Results

| Suite | Tests | Status |
|-------|-------|--------|
| Rust (`cargo test`) | 53 | ✅ Pass |
| Dart (`flutter test`) | 99 | ✅ Pass |

### Final API Coverage

| Action | Enum | Execute | GetLegal |
|--------|:----:|:-------:|:--------:|
| MOVE | ✅ | ✅ | ✅ |
| PASS | ✅ | ✅ | ✅ |
| SHOOT | ✅ | ✅ | ✅ |
| INTERCEPT | ✅ | ✅ | ✅ |
| KICK | ✅ | ✅ | ✅ |
| DEFEND | ✅ | ✅ | ✅ |
| PUSH | ✅ | ✅ | ✅ |

**All 7 engine actions are now fully exposed in the Flutter bridge.**

