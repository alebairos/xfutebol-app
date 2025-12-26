# FT-020: Match History Logging

## Status: Proposed

## Overview

Expose the engine's `MatchHistory` system through the Flutter bridge and combine it with UI-level events to create comprehensive debug logs for match replay and issue diagnosis.

## Problem Statement

Currently, when issues occur during gameplay:
- No visibility into engine-level state changes
- No record of what actions were attempted vs executed
- No way to reproduce bugs reliably
- Console logs are ephemeral and unstructured

## Goals

1. **Engine History Access** - Expose `MatchHistory` via FFI bridge
2. **UI Event Logging** - Track user interactions (taps, selections, gestures)
3. **Unified Log Format** - Combine engine + UI events in chronological order
4. **File Export** - Persist logs to file for post-mortem debugging
5. **Match Replay** - Enable reproducing exact match state from logs

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │  GameController │───>│        MatchLogger              │ │
│  │  (UI Events)    │    │  - UI events (taps, selections) │ │
│  └─────────────────┘    │  - Engine events (via bridge)   │ │
│                         │  - Writes to file                │ │
│                         └─────────────────────────────────┘ │
│                                    │                         │
│                                    ▼                         │
│                         ┌─────────────────────────────────┐ │
│                         │   XfutebolBridge (FFI)          │ │
│                         │   - getMatchHistory()           │ │
│                         │   - getActionRecords()          │ │
│                         └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│                      Rust Engine                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                   MatchHistory                           ││
│  │  - ActionRecord[] (turn, team, action, path, result)    ││
│  │  - BoardSnapshot[] (sparse, for navigation)             ││
│  │  - MatchMetadata (mode, timestamps, result)             ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Data Structures

### Engine-side (Rust)

Already exists in `xfutebol-engine/src/core/history/`:

```rust
// ActionRecord - already exists
pub struct ActionRecord {
    pub turn: usize,
    pub team: Team,
    pub action: Action,
    pub source: BoardTile,
    pub target: BoardTile,
    pub path: Vec<BoardTile>,
    pub result: ActionResult,
    pub effects: Vec<Effect>,
}

// ActionResult - already exists
pub enum ActionResult {
    Success,
    Goal(Team),
    Intercepted(PieceId),
    Blocked(PieceId),
    OutOfBounds,
    TurnLimitReached,
}

// Effect - already exists
pub enum Effect {
    BallTransfer { from: Option<PieceId>, to: Option<PieceId> },
    BallMoved { from: BoardTile, to: BoardTile },
    PieceMoved { piece: PieceId, from: BoardTile, to: BoardTile },
    ScoreChanged { team: Team, old: u8, new: u8 },
    TurnChanged { from: Team, to: Team },
}
```

### Bridge API (new functions)

```rust
// In api.rs - new FFI types

#[frb]
#[derive(Debug, Clone)]
pub struct ActionRecordView {
    pub turn: u32,
    pub team: Team,
    pub action_type: ActionType,
    pub source: Position,
    pub target: Position,
    pub path: Vec<Position>,
    pub result: ActionResultType,
    pub effects: Vec<EffectView>,
    pub timestamp_ms: u64,  // When action was executed
}

#[frb]
#[derive(Debug, Clone, Copy)]
pub enum ActionResultType {
    Success,
    GoalWhite,
    GoalBlack,
    Intercepted,
    Blocked,
    OutOfBounds,
    TurnLimitReached,
    Error,  // For failed/illegal actions
}

#[frb]
#[derive(Debug, Clone)]
pub enum EffectView {
    BallTransfer { from_piece: Option<String>, to_piece: Option<String> },
    BallMoved { from: Position, to: Position },
    PieceMoved { piece_id: String, from: Position, to: Position },
    ScoreChanged { team: Team, old_score: u8, new_score: u8 },
    TurnChanged { from: Team, to: Team },
}

#[frb]
#[derive(Debug, Clone)]
pub struct MatchHistoryView {
    pub game_id: String,
    pub mode: GameModeType,
    pub started_at: String,  // ISO 8601
    pub actions: Vec<ActionRecordView>,
    pub current_turn: u32,
    pub score_white: u8,
    pub score_black: u8,
    pub is_finished: bool,
    pub winner: Option<Team>,
}

// New bridge functions
#[frb]
pub fn get_match_history(game_id: String) -> Option<MatchHistoryView>;

#[frb]
pub fn get_action_records(game_id: String) -> Vec<ActionRecordView>;

#[frb]
pub fn get_last_n_actions(game_id: String, n: u32) -> Vec<ActionRecordView>;

#[frb]
pub fn export_match_notation(game_id: String) -> String;  // Board notation v3 format
```

### Dart-side (UI Events)

```dart
/// Types of UI events to log
enum UIEventType {
  // User interactions
  pieceTapped,
  squareTapped,
  actionButtonPressed,
  gestureDetected,
  
  // UI state changes
  selectionChanged,
  validMovesComputed,
  animationStarted,
  animationCompleted,
  
  // System events
  bridgeCallStarted,
  bridgeCallCompleted,
  bridgeCallFailed,
  screenNavigated,
  
  // Errors
  uiError,
  validationError,
}

/// A single UI event
class UIEvent {
  final DateTime timestamp;
  final UIEventType type;
  final String description;
  final Map<String, dynamic>? data;
  final String? error;
  
  String toLogLine() {
    final ts = timestamp.toIso8601String();
    final dataStr = data != null ? json.encode(data) : '';
    return '[$ts] UI:${type.name} $description $dataStr${error != null ? ' ERROR: $error' : ''}';
  }
}

/// Combined log entry (engine or UI)
class MatchLogEntry {
  final DateTime timestamp;
  final String source;  // 'ENGINE' or 'UI'
  final String event;
  final Map<String, dynamic> data;
  
  String toLogLine();
  Map<String, dynamic> toJson();
}
```

### Log File Format

```
================================================================================
XFUTEBOL MATCH LOG
================================================================================
Game ID: game_StandardMatch_1735156789
Mode: StandardMatch
Started: 2025-12-25T19:30:00.000Z
Device: iPhone 15 Pro (iOS 18.3)
App Version: 1.0.0+1
Engine Version: 0.1.0
--------------------------------------------------------------------------------

[2025-12-25T19:30:00.123Z] ENGINE:GAME_STARTED mode=StandardMatch
[2025-12-25T19:30:00.125Z] ENGINE:INITIAL_STATE notation="8x8|t=w|b=D4|..."
[2025-12-25T19:30:01.456Z] UI:pieceTapped piece=WA01 position=(3,3)
[2025-12-25T19:30:01.458Z] UI:bridgeCallStarted method=getLegalMoves
[2025-12-25T19:30:01.462Z] UI:bridgeCallCompleted method=getLegalMoves duration=4ms
[2025-12-25T19:30:01.463Z] UI:validMovesComputed count=5 moves=[(4,3),(4,4),(3,4),(2,3),(2,4)]
[2025-12-25T19:30:02.789Z] UI:squareTapped position=(4,4)
[2025-12-25T19:30:02.791Z] UI:bridgeCallStarted method=executeMove
[2025-12-25T19:30:02.795Z] ENGINE:ACTION turn=0 team=White action=MOVE from=D4 to=E5 result=Success
[2025-12-25T19:30:02.796Z] ENGINE:EFFECT BallMoved from=D4 to=E5
[2025-12-25T19:30:02.797Z] UI:bridgeCallCompleted method=executeMove duration=6ms
[2025-12-25T19:30:02.800Z] UI:animationStarted type=pieceMove piece=WA01
[2025-12-25T19:30:03.100Z] UI:animationCompleted type=pieceMove duration=300ms
[2025-12-25T19:30:03.101Z] ENGINE:BOT_TURN team=Black
[2025-12-25T19:30:03.450Z] ENGINE:ACTION turn=1 team=Black action=MOVE from=E5 to=E4 result=Success
...
[2025-12-25T19:35:45.678Z] ENGINE:ACTION turn=42 team=White action=SHOOT from=F7 to=F8 result=GoalWhite
[2025-12-25T19:35:45.679Z] ENGINE:EFFECT ScoreChanged team=White old=0 new=1
[2025-12-25T19:35:45.680Z] ENGINE:GAME_OVER winner=White score=1-0

--------------------------------------------------------------------------------
MATCH SUMMARY
--------------------------------------------------------------------------------
Duration: 5m 45s
Total Turns: 42
Actions by White: 21
Actions by Black: 21
Goals: White 1, Black 0
Winner: White

UI Events: 156
Bridge Calls: 89 (avg 5.2ms)
Errors: 0
================================================================================
```

## Implementation Plan

### Phase 1: Bridge API (Rust)

1. **Enable MatchHistory in GameMatch**
   - Ensure `GameMatch` stores history during play
   - Record all actions with full effects

2. **Add FFI functions**
   - `get_match_history(game_id)` - Full history
   - `get_action_records(game_id)` - Just actions
   - `get_last_n_actions(game_id, n)` - Recent actions

3. **Add error logging**
   - Log illegal move attempts with reason
   - Log validation failures

### Phase 2: Dart Logger

1. **Create MatchLogger class**
   ```dart
   class MatchLogger {
     final String gameId;
     final List<MatchLogEntry> _entries = [];
     File? _logFile;
     
     void logUIEvent(UIEventType type, String description, {Map<String, dynamic>? data});
     void logEngineAction(ActionRecordView action);
     void logError(String source, String error, {StackTrace? stackTrace});
     
     Future<void> syncFromEngine();  // Pull engine history
     Future<File> exportToFile();
     String exportToString();
   }
   ```

2. **Integrate with GameController**
   - Log all user interactions
   - Log all bridge calls with timing
   - Sync engine history periodically

3. **File management**
   - Store in app documents directory
   - Rotate logs (keep last N matches)
   - Option to share/export

### Phase 3: Debug UI (Optional)

1. **In-app log viewer**
   - Scrollable log display
   - Filter by source (Engine/UI)
   - Search functionality

2. **Share button**
   - Export log as file
   - Copy to clipboard
   - Share via system share sheet

## File Storage

```
Documents/
  xfutebol_logs/
    match_2025-12-25_193000_game123.log
    match_2025-12-25_194500_game456.log
    match_2025-12-25_200000_game789.log
```

- Keep last 10 matches
- Auto-delete older logs
- Size limit per log: 1MB

## Testing

### Unit Tests (Rust)
- History recording captures all action types
- Effects are properly tracked
- Serialization to FFI types works

### Unit Tests (Dart)
- UI events are logged correctly
- Engine history sync works
- File export produces valid format

### Integration Tests
- Full match produces complete log
- Log can be used to reproduce game state
- No performance degradation during play

## Acceptance Criteria

- [ ] Bridge exposes `get_match_history()` returning full action list
- [ ] Each action includes: turn, team, type, positions, result, effects
- [ ] Illegal/failed actions are logged with error reason
- [ ] UI events (taps, selections) are logged with timestamps
- [ ] Bridge calls log start/complete/fail with duration
- [ ] Logs are written to file in documents directory
- [ ] Log format is human-readable and parseable
- [ ] Match can be replayed/debugged from log alone
- [ ] Performance: <1ms overhead per action logging
- [ ] Storage: Logs rotate, keeping last 10 matches

## Future Enhancements

- **Match replay mode**: Step through logged match visually
- **Remote logging**: Send logs to server for analysis
- **Crash reports**: Auto-attach recent match log
- **Analytics**: Aggregate stats from match logs
- **Bug reports**: One-tap export with context

