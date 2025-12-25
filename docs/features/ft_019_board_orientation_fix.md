# Feature Specification: Board Orientation Fix

**Feature ID:** FT-019  
**Status:** Implemented  
**Created:** December 25, 2025  
**Priority:** Critical  
**Effort:** ~10 minutes (actual)  
**Dependencies:** FT-015 (Flutter UI Implementation)  

---

## Summary

Fix the Flutter UI board rendering which displays the board upside down. Row 0 (A1, White's goal) renders at the TOP of the screen but should be at the BOTTOM to match chess conventions.

---

## Problem

### Current Behavior

| Engine Tile | Engine Index | Flutter Position | Flutter Label | Expected |
|-------------|--------------|------------------|---------------|----------|
| A1 | (0, 0) | TOP | "8" | BOTTOM, "1" |
| A8 | (7, 0) | BOTTOM | "1" | TOP, "8" |

The board is **upside down** in Flutter.

### Root Cause

```dart
// positioned_square.dart
top: position.row * squareSize  // Row 0 at TOP (wrong)

// game_board_widget.dart  
text: '${8 - row}'              // Row 0 labeled "8" (wrong)
```

### Impact

- White pieces appear at top instead of bottom
- Black pieces appear at bottom instead of top
- Bot attacks in visually wrong direction
- Confuses players familiar with chess notation

---

## Solution

### Fix: Flip Y-axis in rendering

**File:** `lib/src/game/widgets/board/positioned_square.dart`

```dart
// Before
top: position.row * squareSize,

// After
top: (7 - position.row) * squareSize,
```

### Labels Already Correct ✓

The label logic in `background_painter.dart` uses `'${8 - row}'` which produces:
- Visual row 0 (TOP) → "8" → Rank 8 (Black's side) ✓
- Visual row 7 (BOTTOM) → "1" → Rank 1 (White's side) ✓

After the position fix, this matches correctly.

---

## Why NOT Fix the Engine

The engine follows correct chess conventions:
- Row 1 (index 0) = White's back rank (bottom)
- Row 8 (index 7) = Black's back rank (top)

Changing the engine would break:
- CLI display
- All existing tests
- Notation system (v3 format)
- Bot logic

**The engine is correct. Flutter rendering is inverted.**

---

## Acceptance Criteria

- [ ] A1 (row index 0) renders at BOTTOM of screen
- [ ] A8 (row index 7) renders at TOP of screen
- [ ] Rank labels show "1" at bottom, "8" at top
- [ ] White pieces start at bottom
- [ ] Black pieces start at top
- [ ] White attacks upward (toward row 8)
- [ ] Black attacks downward (toward row 1)
- [ ] No engine changes required

---

## Test Verification

After fix, verify:

```
Visual Layout (Flutter screen):
    A   B   C   D   E   F   G   H
8   ♜   ·   ·   ·   ·   ·   ·   ♜   ← Black's goal (TOP)
7   ·   ·   ♞   ·   ·   ♞   ·   ·
6   ·   ♟   ·   ·   ·   ·   ♟   ·
5   ·   ·   ·   ·   ·   ·   ·   ·
4   ·   ·   ·   ·   ·   ·   ·   ·
3   ·   ♙   ·   ·   ·   ·   ♙   ·
2   ·   ·   ♘   ·   ·   ♘   ·   ·
1   ♖   ·   ·   ·   ·   ·   ·   ♖   ← White's goal (BOTTOM)
```

---

## Files Modified

| File | Change |
|------|--------|
| `lib/src/game/widgets/board/positioned_square.dart` | `(7 - position.row)` |

---

## Implementation Summary

**Implemented:** December 25, 2025  
**Branch:** `feature/ft-019-board-orientation-fix`

### Change Made

Single line change in `positioned_square.dart`:

```dart
// Before
top: position.row * squareSize,

// After  
top: (7 - position.row) * squareSize,
```

### Verification

- ✅ `flutter analyze`: No issues
- ✅ `flutter test`: All tests pass
- ✅ Labels already correct (no change needed)

### Result

| Position | Before | After |
|----------|--------|-------|
| A1 (engine row 0) | TOP | BOTTOM ✓ |
| A8 (engine row 7) | BOTTOM | TOP ✓ |
| White pieces | TOP | BOTTOM ✓ |
| Black pieces | BOTTOM | TOP ✓ |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2025-12-25 | Initial specification |
| 1.0.0 | 2025-12-25 | Implemented - single line fix |

