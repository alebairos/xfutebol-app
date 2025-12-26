# FT-024: Action UI System

## Status: Draft

## Summary

Implement a complete action system with drag gestures for physical actions (MOVE, PUSH, INTERCEPT) and a bottom action bar for ball trajectory actions (PASS, SHOOT, KICK). Design emphasizes physics-like feedback with haptics and sound.

## Design Principles

1. **Physics First** - Actions should feel like real soccer (body contact, momentum, impact)
2. **Board Visibility** - Never obscure the game board with UI elements
3. **Thumb Ergonomics** - Controls in natural reach zone (bottom of screen)
4. **Feedback Through Feel** - Failed actions provide haptic/visual feedback, teaching rules naturally

---

## Action Classification

### Physical Actions (Drag Gesture)

| Action | Trigger | Haptic | Sound |
|--------|---------|--------|-------|
| **MOVE** | Drag piece → empty tile | Light tap | Slide |
| **PUSH** | Drag piece → opponent (no ball) | Heavy impact | Thud |
| **INTERCEPT** | Drag piece → opponent with ball | Quick snap | Tackle |

### Ball Trajectory Actions (Bottom Bar + Path Building)

| Action | Trigger | Animation | Sound |
|--------|---------|-----------|-------|
| **PASS** | [PASS] → tap tiles → execute | Ball arc | Kick |
| **SHOOT** | [SHOOT] → tap target → execute | Power shot | Crowd roar |
| **KICK** | [KICK] → tap tiles → execute | Long arc | Boot |

---

## UI States

### State 1: No Selection (Default)

```
┌─────────────────────────────────────┐
│                                     │
│            GAME BOARD               │
│                                     │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│      Tap a piece to select          │  ← Hint text, greyed
└─────────────────────────────────────┘
```

- Bottom bar visible but inactive
- Hint text guides new players

### State 2: Piece Selected (Has Ball)

```
┌─────────────────────────────────────┐
│            GAME BOARD               │
│    ● ● ●  (valid moves shown)       │
│                                     │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ [PASS]   [SHOOT]   [KICK]      [×]  │  ← Active buttons
└─────────────────────────────────────┘
```

- All ball action buttons active
- SHOOT only if in shooting range (else greyed)
- Valid MOVE destinations shown on board
- Drag to MOVE, or tap button for ball action

### State 3: Piece Selected (No Ball)

```
┌─────────────────────────────────────┐
│            GAME BOARD               │
│    ● ● ●  (valid moves shown)       │
│                                     │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│    Drag to move or tackle      [×]  │  ← Context hint
└─────────────────────────────────────┘
```

- No ball action buttons (piece doesn't have ball)
- Drag to MOVE, PUSH, or INTERCEPT
- Action auto-detected based on drag target

### State 4: Path Building Mode (PASS/SHOOT/KICK)

```
┌─────────────────────────────────────┐
│            GAME BOARD               │
│    ◉ ◉ ◉  (valid targets pulsing)   │
│                                     │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ PASS: D4 → E5 → ___   [UNDO] [CANCEL]│
└─────────────────────────────────────┘
```

- Shows current path being built
- Valid next tiles pulse/highlight
- UNDO removes last tile from path
- CANCEL returns to piece selected state
- Auto-executes when max path length reached

---

## Drag Behavior

### Valid Drag (MOVE to empty tile)

```
1. User starts drag on piece
2. Valid destinations highlight (green circles)
3. Piece follows finger (semi-transparent ghost)
4. On release over valid tile:
   - Piece animates to destination
   - Light haptic feedback
   - Slide sound effect
```

### Valid Drag (PUSH opponent)

```
1. User drags piece toward adjacent opponent
2. Opponent highlights (yellow/orange)
3. Arrow shows push direction
4. On release:
   - IF valid push (tile behind opponent is empty):
     - Impact haptic (heavy)
     - "Thud" sound
     - Opponent slides backward
     - Your piece moves to their former position
   - IF invalid push (no space behind):
     - Rebound haptic
     - "Blocked" sound
     - Your piece bounces back to start
     - Brief shake animation
```

### Valid Drag (INTERCEPT)

```
1. User drags piece toward opponent with ball
2. Opponent highlights (orange with ball icon)
3. On release:
   - IF valid intercept path:
     - Snap haptic
     - "Tackle" sound
     - Your piece moves to target
     - Ball transfers to you
   - IF invalid (out of range):
     - Rebound haptic
     - Your piece returns
```

### Invalid Drag

```
1. User drags to invalid destination
2. Target shows red X or no highlight
3. On release:
   - Piece rubber-bands back to start
   - Soft error haptic
   - No sound (silent failure)
```

---

## Bottom Action Bar

### Component Structure

```dart
class ActionBar extends StatelessWidget {
  final PieceView? selectedPiece;
  final bool isInShootingRange;
  final PathBuildingState? pathState;
  final VoidCallback onCancel;
  final Function(ActionType) onActionSelected;
  
  @override
  Widget build(BuildContext context) {
    if (pathState != null) {
      return _buildPathBuildingBar(pathState);
    }
    
    if (selectedPiece == null) {
      return _buildHintBar("Tap a piece to select");
    }
    
    if (selectedPiece.hasBall) {
      return _buildBallActionsBar();
    }
    
    return _buildDragHintBar("Drag to move or tackle");
  }
}
```

### Button States

| Button | Enabled When |
|--------|--------------|
| PASS | Piece has ball AND teammates in range |
| SHOOT | Piece has ball AND in shooting range (rows 5-7 for White, 0-2 for Black) |
| KICK | Piece has ball AND valid kick targets exist |
| CANCEL | Always (when piece selected) |
| UNDO | Path has at least one tile |

### Visual Design

```
┌────────────────────────────────────────────────┐
│                                                │
│  ┌──────┐  ┌──────┐  ┌──────┐      ┌────┐     │
│  │ PASS │  │SHOOT │  │ KICK │      │ ×  │     │
│  │  ⚽   │  │  🎯  │  │  👟  │      │    │     │
│  └──────┘  └──────┘  └──────┘      └────┘     │
│                                                │
│  Height: 60-70pt                               │
│  Background: Semi-transparent dark             │
│  Active: Team color (white/black + accent)     │
│  Inactive: Greyed out, 50% opacity             │
│                                                │
└────────────────────────────────────────────────┘
```

---

## Path Building

### Flow

```
1. User taps [PASS] button
2. Bottom bar changes to path building mode
3. Valid first-hop tiles highlight on board
4. User taps Tile A
   - Path updates: "PASS: D4 → A"
   - Valid second-hop tiles highlight
5. User taps Tile B
   - Path updates: "PASS: D4 → A → B"
   - If max length (2) reached → auto-execute
   - Else show more options or [CONFIRM] button
```

### Path Visualization

```
On board during path building:
- Start tile: Piece location (no marker)
- Path tiles: Numbered circles (1, 2, 3...)
- Current path: Dotted line connecting tiles
- Valid next: Pulsing circles (can tap)
- Invalid: No highlight
```

### Max Path Lengths

| Action | Current Max | With Boost |
|--------|-------------|------------|
| PASS | 2 tiles | 4 tiles |
| SHOOT | 3 tiles | 5 tiles |
| KICK | 3 tiles | 5 tiles |

---

## Failed Action Feedback

### Push Blocked (No Space Behind Opponent)

```
Visual:
- Your piece bounces back with elastic animation
- Red flash on blocked direction
- Opponent briefly shakes (they held ground)

Haptic: Heavy thud then light rebound
Sound: "Oof" or blocked impact
Duration: 300ms
```

### Intercept Out of Range

```
Visual:
- Your piece slides partway then returns
- Range indicator briefly shows

Haptic: Medium tap then soft return
Sound: Whistle or "too far"
Duration: 400ms
```

### Pass Path Blocked

```
Visual:
- Ball starts then bounces back
- Blocking piece highlighted

Haptic: Sharp stop
Sound: "Intercepted" or ball thud
Duration: 350ms
```

---

## Implementation Phases

### Phase 1: Core Mechanics (MVP)

**Scope:**
- Bottom bar with PASS/SHOOT buttons
- Basic drag for MOVE
- Tap to execute (existing flow, enhanced)
- No haptics yet

**Effort:** 4-6 hours

**Files:**
- `lib/src/game/widgets/action_bar.dart` (new)
- `lib/src/game/game_controller.dart` (modify)
- `lib/src/game/widgets/board/game_board.dart` (add drag)

### Phase 2: Full Drag System

**Scope:**
- Drag detection for MOVE/PUSH/INTERCEPT
- Auto-action detection based on target
- Ghost piece during drag
- Valid target highlighting

**Effort:** 6-8 hours

**Files:**
- `lib/src/game/widgets/board/draggable_piece.dart` (new)
- `lib/src/game/game_controller.dart` (add drag handling)

### Phase 3: Path Building

**Scope:**
- Path building mode for PASS/SHOOT/KICK
- Sequential tile selection
- Path visualization (lines, numbers)
- UNDO/CANCEL controls

**Effort:** 4-6 hours

**Files:**
- `lib/src/game/widgets/path_builder.dart` (new)
- `lib/src/game/widgets/board/path_overlay.dart` (new)

### Phase 4: Physics Feedback

**Scope:**
- Haptic feedback for all actions
- Sound effects
- Failed action animations (rebound, shake)
- Success animations (slide, impact)

**Effort:** 4-6 hours

**Files:**
- `lib/src/game/services/haptics_service.dart` (new)
- `lib/src/game/services/audio_service.dart` (new)
- `assets/sounds/` (new audio files)

### Phase 5: Polish

**Scope:**
- Particle effects on impact
- Screen shake on goals
- Crowd ambient sounds
- Slow-mo on critical moments

**Effort:** 4-8 hours

---

## Acceptance Criteria

### Phase 1
- [ ] Bottom action bar appears when piece selected
- [ ] PASS/SHOOT buttons work for ball holder
- [ ] Bar shows hint when no piece selected
- [ ] Cancel button deselects piece

### Phase 2
- [ ] Drag piece to empty tile = MOVE
- [ ] Drag piece to opponent = PUSH or INTERCEPT
- [ ] Ghost piece follows finger during drag
- [ ] Valid targets highlight during drag

### Phase 3
- [ ] PASS enters path building mode
- [ ] Can tap tiles to build path
- [ ] UNDO removes last tile
- [ ] Auto-executes at max length

### Phase 4
- [ ] Light haptic on MOVE
- [ ] Heavy haptic on PUSH
- [ ] Snap haptic on INTERCEPT
- [ ] Rebound animation on failed PUSH

---

## Technical Notes

### Drag Detection

```dart
class DraggablePiece extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        // Start drag, show ghost
        controller.startDrag(piece);
      },
      onPanUpdate: (details) {
        // Move ghost, update target highlight
        controller.updateDrag(details.localPosition);
      },
      onPanEnd: (details) {
        // Determine action and execute
        final target = controller.getDragTarget();
        controller.executeDragAction(piece, target);
      },
      child: PieceWidget(piece: piece),
    );
  }
}
```

### Action Detection

```dart
ActionType detectDragAction(PieceView piece, Position target) {
  final targetPiece = board.getPieceAt(target);
  
  if (targetPiece == null) {
    return ActionType.move;
  }
  
  if (targetPiece.team != piece.team) {
    if (targetPiece.hasBall) {
      return ActionType.intercept;
    } else {
      return ActionType.push;
    }
  }
  
  // Teammate - invalid drag target
  return ActionType.invalid;
}
```

---

## Dependencies

- FT-022: Bot AI fix (should be complete before user can fully play)
- FT-021: Goal validation (complete ✅)
- FT-020: Match logging (complete ✅)

## Related Issues

- FT-023: Bot Offensive Strategy (AI uses these same actions)
- Future: Boost system (extends path lengths)

---

## Open Questions

1. **KICK vs PASS distinction** - Is KICK needed in MVP or can wait?
2. **Path confirmation** - Auto-execute at max length, or require confirm tap?
3. **Haptic intensity** - Need to test on device for right feel
4. **Sound licensing** - Need to source/create sound effects

---

## Appendix: Haptic Patterns

```dart
enum GameHaptic {
  move,       // HapticFeedback.lightImpact()
  push,       // HapticFeedback.heavyImpact()
  intercept,  // HapticFeedback.mediumImpact()
  pass,       // HapticFeedback.selectionClick()
  shoot,      // HapticFeedback.heavyImpact() + vibrate
  blocked,    // HapticFeedback.heavyImpact() + lightImpact()
  goal,       // Long vibration pattern
  error,      // HapticFeedback.vibrate() short
}
```

