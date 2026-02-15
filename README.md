# Upward Lineup Tracker

iOS-first Flutter MVP for tracking Upward basketball lineups. Offline-only, no login.

## Tech stack

- **Flutter** (iOS only for MVP)
- **Riverpod** for state
- **Isar** for local storage
- **go_router** for navigation

## File / folder structure

```
lib/
├── main.dart                 # Entry: ProviderScope + UpwardLineupApp
├── app.dart                  # MaterialApp.router
├── core/
│   └── constants.dart        # quartersPerGame, playersOnCourt, awardsPerCategory
├── data/
│   ├── isar/
│   │   ├── isar_schemas.dart # Schema list for Isar.open
│   │   └── models/
│   │       ├── player.dart   # Player + SkillTag enum
│   │       ├── game.dart     # Game (createdAt, presentPlayerIds)
│   │       ├── quarter_lineup.dart  # gameId, quarterIndex, onCourtPlayerIds
│   │       └── award.dart    # Award (gameId, category, playerId)
│   └── repositories/
│       ├── player_repository.dart
│       └── game_repository.dart
├── providers/
│   ├── isar_provider.dart    # FutureProvider<Isar>
│   ├── players_provider.dart
│   └── game_provider.dart    # currentGameId, lineups, suggest logic, etc.
├── router/
│   └── app_router.dart       # go_router routes
└── features/
    ├── team_setup/           # Team Setup screen
    │   └── team_setup_screen.dart
    ├── game/                  # Game Dashboard
    │   └── game_dashboard_screen.dart
    ├── awards/                # Post-game awards
    │   └── awards_screen.dart
    └── history/               # History + game summary
        ├── history_screen.dart
        └── game_summary_screen.dart
```

## Game rules

- 6 quarters per game; 5 players on court (lineup always legal).
- Track quarters played only (no minutes).
- Coach sets “present” players before game; each quarter lineup can change.
- “Suggest Next Quarter” suggests quarter = currentQuarter + 1 (prefer who sat last, soft mix by skill).
- Quick swap: tap one on-court + one sitting to swap.

## Screens

1. **Team Setup** – List players, add/edit name, toggle present, toggle skill (strong/developing), Start Game.
2. **Game Dashboard** – Quarter tabs Q1–Q6, On Court (5) chips, Sitting chips, fairness row (played count + behind icon), Suggest Next Quarter + Apply Suggestion, Quick Swap.
3. **Awards** – Christlike / Offense / Defense / Hustle; each category awarded exactly 2 times.
4. **History** – List games; tap to view game summary (date, quarters played, lineups by quarter, awards).

## Run

```bash
flutter pub get
flutter run
```

(Use an iOS simulator or device; no web/backend.)

## Regenerate Isar / Riverpod code

```bash
dart run build_runner build --delete-conflicting-outputs
```
