# Flutter Rust Bridge Bindings Guide

## Overview

This document explains how the Flutter Rust Bridge (FRB) bindings work in xfutebol-app and when regeneration is required.

## Architecture

```
xfutebol-app/
├── packages/xfutebol_flutter_bridge/
│   ├── rust/
│   │   ├── Cargo.toml          ← References engine via path dependency
│   │   └── src/api.rs          ← FFI wrapper functions (#[frb] annotated)
│   └── lib/src/rust/
│       ├── frb_generated.dart  ← AUTO-GENERATED Dart bindings
│       └── api/*.dart          ← AUTO-GENERATED from api.rs
└── xfutebol-engine/            ← Sibling directory (game logic)
```

## Path Dependency

The bridge references the engine via a local path:

```toml
# packages/xfutebol_flutter_bridge/rust/Cargo.toml
[dependencies]
xfutebol-engine = { path = "../../../../xfutebol-engine" }
```

**Key insight**: Rust code automatically uses the latest engine code because it's a **path dependency** (not a version from crates.io).

---

## When Regeneration is Required

| Scenario | Regenerate? | Reason |
|----------|-------------|--------|
| Engine internal logic changes (bug fixes) | **NO** ❌ | API contract unchanged |
| Engine performance optimizations | **NO** ❌ | API contract unchanged |
| New functions added to `api.rs` | **YES** ✅ | New Dart bindings needed |
| Changed function signatures in `api.rs` | **YES** ✅ | Dart bindings must match |
| New types exposed via `#[frb]` | **YES** ✅ | New Dart types needed |
| Engine adds new public types used by bridge | **YES** ✅ | Bridge must expose them |

### Example: FT-021 Goal Validation Fix

**NO regeneration needed** because:

```rust
// Before and after FT-021 - SAME signature
pub fn perform_move(from: BoardTile, to: BoardTile) -> Result<ActionOutcome, GameError>
```

The `ActionOutcome` struct still has `goal_scored: Option<Team>` - the fix just ensures it correctly returns `None` when there's no ball. This is internal logic, not an API change.

---

## How to Regenerate

When changes to `api.rs` require new bindings:

```bash
cd /Users/alebairos/Projects/xfutebol-app/packages/xfutebol_flutter_bridge
flutter_rust_bridge_codegen generate
```

This reads `api.rs` and generates:
- `lib/src/rust/frb_generated.dart`
- `lib/src/rust/frb_generated.io.dart`
- `lib/src/rust/api/*.dart`

---

## How to Rebuild Without Regeneration

For engine-only changes (bug fixes, optimizations):

```bash
cd /Users/alebairos/Projects/xfutebol-app
flutter clean
flutter run -d "iPhone 15 Pro"
```

The Rust compiler automatically recompiles the engine because:
1. Path dependency points to local engine
2. Engine source changed
3. Cargo detects the change and rebuilds

---

## Avoiding Common Problems

### Problem 1: "Do I need to regenerate?"

**Solution**: Check if `api.rs` changed

```bash
#!/bin/bash
# scripts/check_bridge_sync.sh

cd packages/xfutebol_flutter_bridge

# Check if api.rs changed since last generation
API_HASH=$(md5 -q rust/src/api.rs)
LAST_HASH=$(cat .api_hash 2>/dev/null || echo "none")

if [ "$API_HASH" != "$LAST_HASH" ]; then
    echo "⚠️  api.rs changed - regeneration may be needed"
    echo "Run: flutter_rust_bridge_codegen generate"
else
    echo "✅ Bridge bindings are up to date"
fi
```

### Problem 2: Forgetting to regenerate after api.rs changes

**Solution**: Add CI check

```yaml
# .github/workflows/check-bridge.yml
- name: Check bridge bindings are current
  run: |
    cd packages/xfutebol_flutter_bridge
    flutter_rust_bridge_codegen generate
    git diff --exit-code lib/src/rust/ || {
      echo "❌ Bridge bindings are stale! Run flutter_rust_bridge_codegen generate"
      exit 1
    }
```

### Problem 3: Stale Rust build cache

**Solution**: Clean and rebuild

```bash
cd packages/xfutebol_flutter_bridge/rust
cargo clean
cd ../../../..
flutter clean
flutter run
```

---

## Quick Reference

### Engine bug fix (internal logic)
```bash
flutter clean && flutter run
```

### New bridge function added
```bash
cd packages/xfutebol_flutter_bridge
flutter_rust_bridge_codegen generate
cd ../..
flutter run
```

### Full clean rebuild
```bash
cd packages/xfutebol_flutter_bridge/rust && cargo clean
cd ../../../..
flutter clean
flutter pub get
flutter run
```

---

## Related Documentation

- [FT-009: Flutter Bridge Package](features/ft_009_flutter_bridge_package.md)
- [FT-010: Bridge Package Tests](features/ft_010_bridge_package_tests.md)
- [Flutter Rust Bridge Docs](https://cjycode.com/flutter_rust_bridge/)

