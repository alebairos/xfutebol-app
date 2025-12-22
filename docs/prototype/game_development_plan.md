# Xfutebol Game Development Plan

**Date:** December 2024  
**Developer:** Solo  
**Goal:** Kids playing ASAP, elegant minimalist design, global launch potential

---

## Vision Statement

A strategic soccer-themed board game that feels like digital chess meets beautiful simplicity. Offline-first, elegant, and maintainable by one person.

---

## Development Phases

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Playable Prototype          Target: 1 week       │
│  Phase 2: Polish & Features           Target: 2-3 weeks    │
│  Phase 3: Backend & Multiplayer       Target: 4-6 weeks    │
│  Phase 4: Monetization & Launch       Target: 4-6 weeks    │
│  Phase 5: Competitive Features        Target: Ongoing      │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Playable Prototype (1 Week)

**Goal:** Kids can play against the bot on a phone/tablet.

### Day 1-2: FFI Bridge

| Task | Details |
|------|---------|
| Set up flutter_rust_bridge | In xfutebol_flutter project |
| Expose core API | `new_game()`, `get_board()`, `make_move()`, `get_legal_moves()` |
| Test bridge | Verify Rust logic callable from Dart |

```rust
// Minimal API surface
pub fn new_game(mode: GameMode) -> GameState;
pub fn get_board_state(game: &GameState) -> BoardView;
pub fn get_legal_moves(game: &GameState, piece_id: u8) -> Vec<Tile>;
pub fn execute_action(game: &mut GameState, action: Action) -> ActionResult;
pub fn get_bot_move(game: &GameState) -> Action;
```

### Day 3-4: Basic UI

| Task | Details |
|------|---------|
| Board widget | 8x8 GridView with tap handling |
| Piece widget | Colored circles (white/black team) |
| Ball indicator | Orange dot or icon on ball holder |
| Turn display | "White's Turn" / "Black's Turn" |
| Score display | Simple "0 - 0" |

```dart
// Core widgets needed
class GameBoard extends StatelessWidget { ... }
class Square extends StatelessWidget { ... }
class Piece extends StatelessWidget { ... }
class GameHUD extends StatelessWidget { ... }
```

### Day 5: Interaction

| Task | Details |
|------|---------|
| Piece selection | Tap piece → highlight |
| Legal move display | Show valid destinations |
| Move execution | Tap destination → move |
| Bot response | After player turn, bot moves |
| Turn switching | Alternate white/black |

### Day 6-7: Polish & Test

| Task | Details |
|------|---------|
| Basic animations | Smooth piece movement |
| Visual feedback | Selected state, valid moves |
| Play testing | Kids try it, gather feedback |
| Bug fixes | Address obvious issues |

### Phase 1 Deliverable

✅ Playable game: Human vs Bot on mobile
✅ Minimalist but clean visuals
✅ Kids can test and provide feedback

---

## Phase 2: Polish & Features (2-3 Weeks)

**Goal:** A polished single-player experience.

### Week 1: Visual Polish

| Task | Priority |
|------|----------|
| Color palette refinement | High |
| Typography (one good font) | High |
| Smooth animations (300ms transitions) | High |
| Selected piece glow effect | Medium |
| Board grid lines refined | Medium |
| Goal area visual distinction | Medium |

### Week 2: Game Features

| Task | Priority |
|------|----------|
| Multiple bot difficulties | High |
| Game mode selection (Quick/Standard/Golden Goal) | High |
| Undo last move | Medium |
| Match history navigation (forward/back) | Medium |
| Sound effects (optional, minimal) | Low |

### Week 3: UX Polish

| Task | Priority |
|------|----------|
| Main menu | High |
| Settings screen | Medium |
| How to play / Tutorial | Medium |
| Win/Lose screen | High |
| Play again flow | High |

### Phase 2 Deliverable

✅ Polished single-player game
✅ Multiple difficulties
✅ Clean, intuitive UX
✅ Ready for external testers

---

## Phase 3: Backend & Multiplayer (4-6 Weeks)

**Goal:** Play against other humans online.

### Week 1-2: Backend Foundation

| Component | Technology |
|-----------|------------|
| Server | Rust (Axum or Actix) |
| Database | PostgreSQL or SQLite |
| Auth | Simple email/password or social login |
| Hosting | Fly.io, Railway, or similar |

```rust
// Backend API
POST /auth/register
POST /auth/login
GET  /user/profile
POST /game/create
POST /game/join/{id}
WS   /game/{id}/play  // WebSocket for real-time
```

### Week 3-4: Multiplayer Logic

| Task | Details |
|------|---------|
| Game room creation | Create/join games |
| Real-time sync | WebSocket for moves |
| Turn validation | Server authoritative |
| Reconnection handling | Resume interrupted games |
| Basic matchmaking | Find opponent |

### Week 5-6: Integration & Testing

| Task | Details |
|------|---------|
| Flutter WebSocket client | Connect to backend |
| Online game flow | Menu → Find game → Play |
| Connection status UI | Online/offline indicator |
| Error handling | Network failures gracefully |
| Play testing | Real multiplayer games |

### Phase 3 Deliverable

✅ Play against humans online
✅ User accounts
✅ Basic matchmaking
✅ Stable connection handling

---

## Phase 4: Monetization & Launch (4-6 Weeks)

**Goal:** Revenue and public launch.

### Week 1-2: Monetization

| Model | Implementation |
|-------|----------------|
| Free tier | Play vs bot, limited online games |
| Premium | Unlimited online, no ads |
| Cosmetics | Board themes, piece styles |

| Task | Details |
|------|---------|
| RevenueCat or in_app_purchase | Payment integration |
| Premium unlock flow | Purchase → unlock features |
| Restore purchases | Required for App Store |

### Week 3-4: Launch Prep

| Task | Details |
|------|---------|
| App Store assets | Screenshots, description |
| Play Store assets | Same |
| Privacy policy | Required |
| Terms of service | Required |
| App icons | All sizes |
| Splash screen | Brand moment |

### Week 5-6: Launch

| Task | Details |
|------|---------|
| TestFlight beta | iOS testers |
| Google Play beta | Android testers |
| Feedback collection | Fix critical issues |
| Public launch | Both stores |
| Basic analytics | Firebase or similar |

### Phase 4 Deliverable

✅ Live on App Store & Play Store
✅ Revenue generating
✅ Analytics in place

---

## Phase 5: Competitive Features (Ongoing)

**Goal:** Build the dream - rankings, championships, community.

### ELO Rating System

| Task | Details |
|------|---------|
| ELO calculation | Backend logic |
| Rating display | Profile and leaderboards |
| Ranked matchmaking | Match similar skill |
| Seasons | Rating resets, rewards |

### Leaderboards

| Task | Details |
|------|---------|
| Global leaderboard | Top 100 players |
| Friends leaderboard | Compare with friends |
| Regional leaderboards | Country/region |

### Championships

| Task | Details |
|------|---------|
| Tournament system | Brackets, scheduling |
| Local tournaments | In-person events |
| Online championships | Seasonal competitions |
| Prizes/rewards | Cosmetics, titles |

### Community

| Task | Details |
|------|---------|
| Friend system | Add/invite friends |
| Game invitations | Challenge friends |
| Spectator mode | Watch live games |
| Replay sharing | Share great games |

---

## Technical Architecture

### Repository Structure

```
xfutebol-engine/        ← Rust game logic (existing)
├── src/
│   ├── core/           ← Board, pieces, rules
│   ├── bot/            ← AI opponent
│   └── history/        ← Match history
└── Cargo.toml

xfutebol-app/           ← Flutter client (new)
├── lib/
│   ├── core/           ← FFI bridge
│   ├── game/           ← Game UI
│   ├── menu/           ← Menus, settings
│   └── online/         ← Multiplayer
├── rust/               ← Submodule to engine
└── pubspec.yaml

xfutebol-server/        ← Rust backend (Phase 3)
├── src/
│   ├── api/            ← HTTP endpoints
│   ├── game/           ← Game rooms
│   ├── auth/           ← User auth
│   └── matchmaking/    ← Find opponents
└── Cargo.toml
```

### Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │────►│    Rust     │     │   Server    │
│     UI      │◄────│   Engine    │     │  (online)   │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                    │
      │    FFI Bridge     │                    │
      │   (local games)   │                    │
      │                   │                    │
      └───────────────────┼────────────────────┘
                          │
                    WebSocket (online games)
```

---

## Success Metrics

### Phase 1
- [ ] Kids can play a complete game
- [ ] Game runs on iOS and Android
- [ ] No crashes during normal play

### Phase 2
- [ ] 10+ games played without issues
- [ ] Positive feedback on visuals
- [ ] Bot provides appropriate challenge

### Phase 3
- [ ] 2 players can complete online game
- [ ] <200ms latency for moves
- [ ] Reconnection works

### Phase 4
- [ ] 100+ downloads first month
- [ ] 4+ star rating
- [ ] Some revenue

### Phase 5
- [ ] Active player community
- [ ] Regular tournaments
- [ ] Sustainable growth

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Graphics taking too long | Embrace minimalism, avoid scope creep |
| FFI bridge issues | Start with bridge, validate early |
| Multiplayer complexity | Ship single-player first, multiplayer later |
| Burnout | Phase 1 → kids playing = motivation boost |
| Platform issues | Test on real devices early and often |

---

## Immediate Next Steps

1. **Today:** Set up flutter_rust_bridge in xfutebol_flutter
2. **Tomorrow:** Expose minimal Rust API
3. **This week:** Basic board rendering + tap handling
4. **Weekend:** Kids playing prototype

---

## Related Documents

- `solo_dev_platform_decision.md` - Platform choice rationale
- `cross_platform_framework_analysis.md` - Framework comparison
- `../features/ft_004_match_history.md` - Match history spec
- `../xfutebol-ui-design-specification.md` - Full UI spec

