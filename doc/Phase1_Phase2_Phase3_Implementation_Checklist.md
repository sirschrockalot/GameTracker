# Phase 1–3 Implementation Checklist

Starts from current repo state. Reference: `lib/` structure, `doc/Backend_Spec_Heroku_MongoDB_REST_Sync.md` (v2), `doc/Model_Inventory_and_Sync_Readiness.md`.

**Current state:** Isar models (Team, JoinRequest, Player, Game, ScheduleEvent); repos in `lib/data/repositories/`; providers in `lib/providers/`; `SyncProvider` interface in `lib/domain/sync/sync_provider.dart` with `MockSyncProvider` in `lib/data/sync/mock_sync_provider.dart`; `currentUserIdProvider` placeholder in `lib/providers/current_user_provider.dart`; `TeamAuth` in `lib/domain/authorization/team_auth.dart`; no HTTP client or backend yet.

---

## Phase 1: Auth + team membership API + local integration stubs

### Backend (Heroku API + Mongo)

| ID | Task | Est. |
|----|------|------|
| B1.1 | Provision Heroku app and MongoDB Atlas cluster; set env vars (e.g. `MONGODB_URI`, `JWT_SECRET`). | 1–2h |
| B1.2 | Implement auth: issue JWT (or session) from chosen provider (e.g. Firebase Auth token verification, or custom email/password); expose `userId` in middleware for all protected routes. | 2–3h |
| B1.3 | Create Mongo collections: `teams`, `join_requests` (no `playerIds` on teams). Add indexes per Backend Spec §2 (uuid unique; teamId+status; userId; updatedAt). | 1h |
| B1.4 | Implement POST /teams (create), GET /teams/:uuid; set server `updatedAt`/`updatedBy`. Enforce: caller must have `status=active` membership for GET (or is creator for POST). | 2h |
| B1.5 | Implement POST /teams/:uuid/rotate-coach-code, POST /teams/:uuid/rotate-parent-code; owner-only; set server `updatedAt`/`updatedBy`. | 1h |
| B1.6 | Implement POST /membership/request-join (code → teamId, create JoinRequest status=pending); GET /membership/pending?teamId= (owner only); POST approve/reject/revoke; use status=active (not "approved"). Set server `updatedAt`/`updatedBy` on all mutations. | 2–3h |
| B1.7 | Add security middleware: resolve active teamIds for user (join_requests where status=active); reject 403 for any team-scoped route when teamId not in active teamIds. Document in code. | 1–2h |

### Mobile (Flutter: providers / repos / stubs)

| ID | Task | Est. |
|----|------|------|
| M1.1 | Add dependency (e.g. `http` or `dio`) in `pubspec.yaml`; create API client package or folder (e.g. `lib/data/api/` or `lib/core/api_client.dart`) with base URL from env/config and Bearer token injection. | 1h |
| M1.2 | Integrate real auth (e.g. Firebase Auth, Supabase, or custom): sign-in/sign-out; replace `lib/providers/current_user_provider.dart` so it returns real `userId` or null when unauthenticated. | 2–3h |
| M1.3 | Add auth gate in app: require sign-in before teams list / join / team detail (or show limited UI and prompt sign-in); wire router/guard using existing `lib/router/app_router.dart`. | 1–2h |
| M1.4 | Create team API client: create team (POST /teams), get team (GET /teams/:uuid), rotate coach code, rotate parent code; map JSON ↔ DTO; call from a stub or optional path so existing flows still use Isar-only until Phase 2. | 2h |
| M1.5 | Create membership API client: request-join (POST /membership/request-join), list pending (GET /membership/pending), approve/reject/revoke (POST /membership/:uuid/...); map status "active" ↔ local enum (e.g. keep `JoinRequestStatus.approved` locally and map to "active" in API). | 2h |
| M1.6 | Add “integration stubs”: e.g. after local Team create in `lib/features/teams/create_team_screen.dart` (and after creating owner JoinRequest locally), call API create team + membership in background; on join flow in `lib/features/teams/join_team_screen.dart`, call API request-join after local add. No sync queue yet—fire-and-forget or best-effort. | 2h |
| M1.7 | Update `lib/domain/authorization/team_auth.dart` to treat “active” membership as approved (e.g. use same `JoinRequestStatus.approved` for local; API contract uses "active"). Ensure `canViewTeam`, `canUseCoachTools`, `canManageTeam` remain consistent with Backend Spec authorization. | 0.5h |
| M1.8 | (Optional) Set `lib/core/feature_flags.dart` `enableMembershipAuthV2` to true behind a build/flag so Phase 2 UI is testable. | 0.5h |

### Minimal model changes (Phase 1)

| ID | Task | Est. |
|----|------|------|
| MC1.1 | **Team:** Add `updatedAt`, `updatedBy`; optionally `deletedAt`, `schemaVersion`. Remove `playerIds` from `lib/data/isar/models/team.dart`; run build_runner; update `lib/data/isar/isar_schemas.dart` if needed; fix any references (e.g. `team_detail_screen` that mutate `team.playerIds` → use PlayerRepository + `teamId` only). | 1–2h |
| MC1.2 | **JoinRequest:** Add `updatedAt`, `updatedBy`; optionally `deletedAt` in `lib/data/isar/models/join_request.dart`; run build_runner. Backend uses status "active"; keep Isar enum as-is and map in DTO. | 0.5h |

### Test checklist (Phase 1)

- [ ] Backend: Unauthenticated requests to protected routes return 401.
- [ ] Backend: Create team returns 201 and document has server `updatedAt`/`updatedBy`.
- [ ] Backend: GET /teams/:uuid returns 403 when user is not active member.
- [ ] Backend: Request-join with valid code creates pending JoinRequest; approve sets status=active; list pending returns only pending for that team.
- [ ] Backend: Rotate coach/parent code is owner-only; 403 for non-owner.
- [ ] Mobile: After sign-in, `currentUserIdProvider` returns non-placeholder id; after sign-out, null or unauthenticated.
- [ ] Mobile: Create team (local) then stub call to API succeeds when online; team list still loads from Isar.
- [ ] Mobile: Join by code (local + API request-join) succeeds when online; pending list shows for owner.
- [ ] Unit: TeamAuth helpers behave correctly for owner vs coach vs parent vs non-member (optional; may already be covered by UI).

---

## Phase 2: Sync provider (push/pull) for schedule + team members (parents read-only)

### Backend (Heroku API + Mongo)

| ID | Task | Est. |
|----|------|------|
| B2.1 | Add collections (if not present): `players`, `schedule_events`. Indexes per Backend Spec §2 (uuid unique; teamId+deletedAt; teamId+updatedAt). Use `updatedBy` (not updatedByUserId) in API. | 1h |
| B2.2 | Implement CRUD for players: POST/GET/PUT/DELETE under /teams/:teamId/players; soft-delete with `deletedAt`; server sets `updatedAt`/`updatedBy`; filter by active teamIds. | 2h |
| B2.3 | Implement CRUD for schedule_events: POST/GET/PUT/DELETE under /teams/:teamId/schedule-events; soft-delete; server sets `updatedAt`/`updatedBy`; filter by active teamIds. | 2h |
| B2.4 | Implement GET /sync/pull?since=: return teams, join_requests, players, schedule_events for **active teamIds only**; include tombstones (deletedAt set); use `updatedBy` in payloads. Do not include games yet. | 2h |
| B2.5 | Implement POST /sync/push: accept batch teams, join_requests, players, schedule_events; upsert by uuid (and teamId where scoped); set server `updatedAt`/`updatedBy`; reject 403 for any item with teamId not in user’s active teamIds. Do not accept games yet. | 2h |

### Mobile (Flutter: providers / repos / sync queue)

| ID | Task | Est. |
|----|------|------|
| M2.1 | Define sync payload DTOs and map Isar ↔ API JSON for Team, JoinRequest, Player, ScheduleEvent (including `updatedBy` ↔ ScheduleEvent.updatedByUserId in DTO). | 1–2h |
| M2.2 | Implement `ApiSyncProvider` (or similar) in `lib/data/sync/` implementing `lib/domain/sync/sync_provider.dart`: pull via GET /sync/pull?since=, parse response, merge into Isar (insert/update by uuid; apply soft-deletes via deletedAt). Use last-pulled timestamp (e.g. stored in Isar or preferences) for `since`. | 2–3h |
| M2.3 | Implement push in same provider: collect “dirty” or recently changed entities (Team, JoinRequest, Player, ScheduleEvent) since last successful push (or full push); POST /sync/push with batch; on success, clear dirty state or advance last-pushed marker. Set `SyncStatus.syncing` during push/pull, then `upToDate` or `offline`. | 2–3h |
| M2.4 | Introduce minimal “sync queue” or dirty tracking: e.g. table or in-memory set of entity type + uuid modified since last push; or timestamp per entity type. Hook into repos: after TeamRepository.add/update, JoinRequestRepository.add/approve/reject/revoke, PlayerRepository.add/update/delete, ScheduleRepository.add/update/softDelete, mark entity (or type) dirty. No need for full queue table in Phase 2 if “push all since last sync” is acceptable. | 1–2h |
| M2.5 | Wire real sync provider: in `lib/providers/sync_provider.dart` replace `MockSyncProvider()` with `ApiSyncProvider` (or factory that returns real when config present). Trigger pull on app foreground or after sign-in; trigger push after local repo writes (or on interval/foreground). | 1h |
| M2.6 | Filter team list by membership: ensure “My Teams” only shows teams where user has local JoinRequest with status=approved (active). Use `JoinRequestRepository.hasApprovedRequest` / watch; align with backend “active teamIds” so pulled data matches. | 0.5h |
| M2.7 | Parent read-only: when building schedule/team views for parent role, use existing `TeamAuth.canUseCoachTools` (false for parent); hide edit/delete for schedule; sync pull still returns schedule/players for active teamIds so parents see data. | 0.5h |

### Minimal model changes (Phase 2)

| ID | Task | Est. |
|----|------|------|
| MC2.1 | **Player:** Ensure soft-delete: add `deletedAt` and use it in repo list/get if not already (current PlayerRepository uses hard delete; add softDelete or filter by deletedAt and set deletedAt on “delete”). See Model Inventory: Player already has deletedAt. | 1h |
| MC2.2 | **ScheduleEvent:** DTO mapping only: API uses `updatedBy`; Isar has `updatedByUserId`—map in sync layer, no schema change. | 0.5h |

### Test checklist (Phase 2)

- [ ] Backend: GET /sync/pull returns only teams/join_requests/players/schedule_events for active teamIds; updatedAt > since.
- [ ] Backend: POST /sync/push with valid teamIds succeeds; server overwrites updatedAt; 403 for teamId not in active set.
- [ ] Mobile: After pull, new schedule events from another coach appear in ScheduleRepository watch.
- [ ] Mobile: After adding a schedule event locally, push runs and GET /sync/pull returns it with server updatedAt.
- [ ] Mobile: Parent role sees schedule/players but cannot edit (UI); coach/owner can edit.
- [ ] Mobile: Sync status shows syncing then upToDate when online; offline when no network.

---

## Phase 3: Sync provider for games + conflict guards (quarter completion lock, delete game)

### Backend (Heroku API + Mongo)

| ID | Task | Est. |
|----|------|------|
| B3.1 | Add collection `games`; indexes per Backend Spec §2. Do not store `quartersPlayedJson`; store `quarterLineupsJson`, `awardsJson`, `completedQuartersJson`. | 1h |
| B3.2 | Implement CRUD for games: POST/GET/PUT/DELETE under /teams/:teamId/games; soft-delete; server sets `updatedAt`/`updatedBy`. | 2h |
| B3.3 | **Completed-quarters guard:** On PUT /teams/:teamId/games/:uuid and in POST /sync/push (game items), reject (409 or 400) any payload that modifies or clears a quarter number present in existing document’s `completedQuartersJson`; or merge so completed quarters are never reverted. Document in code. | 1–2h |
| B3.4 | Extend GET /sync/pull to include games (for active teamIds); omit quartersPlayedJson; include tombstones. | 0.5h |
| B3.5 | Extend POST /sync/push to accept games; enforce completed-quarters guard; set server updatedAt/updatedBy; do not accept quartersPlayedJson. | 0.5h |

### Mobile (Flutter: providers / repos / sync queue)

| ID | Task | Est. |
|----|------|------|
| M3.1 | Map Game Isar ↔ API: quarterLineupsJson, awardsJson, completedQuartersJson only; never send or persist quartersPlayedJson; on pull, derive quartersPlayed locally from quarterLineups (or leave as empty and let GameSerialization.computeQuartersPlayedFromLineups). | 1h |
| M3.2 | Add games to sync pull: merge into Isar (upsert by uuid); apply soft-delete (deletedAt); ensure GameRepository and providers see deletedAt-filtered lists (already in place in `lib/data/repositories/game_repository.dart`). | 1h |
| M3.3 | Add games to sync push: mark game dirty on GameRepository.createGame, updateLineupForQuarter, updateCurrentQuarter, saveAwards, markQuarterCompleted, deleteGame; push batch including games; handle 409 from server (completed-quarters conflict) by e.g. re-pulling game and showing message or merging. | 2h |
| M3.4 | **Conflict handling:** On push rejection (409) for game, refresh game from pull and optionally notify user (“someone else completed a quarter”); local LWW: on pull, overwrite local game when server updatedAt > local updatedAt (already server-authoritative). | 1h |
| M3.5 | Ensure delete game flow: GameRepository.deleteGame sets deletedAt locally; sync push sends soft-delete; pull returns tombstone so other devices remove or hide game. | 0.5h |
| M3.6 | Game list scoped by team: if app shows games per team, filter by teamId (Game.teamId); align with backend (games under /teams/:teamId/games). Add team-scoped game list provider if not present (e.g. `gamesForTeamProvider` using GameRepository filter by teamId). | 1h |

### Minimal model changes (Phase 3)

| ID | Task | Est. |
|----|------|------|
| MC3.1 | None required if Game already has teamId, updatedAt, updatedBy, deletedAt, schemaVersion, and JSON fields per Model Inventory. Ensure schema includes scheduleEvents in Isar (for clearIsarDatabase if used); add scheduleEvents to clear in `lib/providers/isar_provider.dart` if needed. | 0.5h |

### Test checklist (Phase 3)

- [ ] Backend: PUT /games with change to a completed quarter returns 409 (or 400); completed quarters unchanged after request.
- [ ] Backend: POST /sync/push with game that alters completed quarter is rejected for that game.
- [ ] Mobile: Completing a quarter locally then push succeeds; second device pulling gets completed quarter.
- [ ] Mobile: Two devices: device A completes quarter 1; device B pushes older lineup for quarter 1—server rejects or ignores change to quarter 1.
- [ ] Mobile: Delete game locally → push → other device after pull no longer shows game (or shows as deleted).
- [ ] Mobile: Sync status and game list stay consistent after push/pull including games.

---

## File / location reference (no code changes)

| Area | Location |
|------|----------|
| Sync interface | `lib/domain/sync/sync_provider.dart` |
| Mock sync | `lib/data/sync/mock_sync_provider.dart` |
| Sync provider wiring | `lib/providers/sync_provider.dart` |
| Current user | `lib/providers/current_user_provider.dart` |
| Auth / roles | `lib/domain/authorization/team_auth.dart` |
| Repositories | `lib/data/repositories/team_repository.dart`, `join_request_repository.dart`, `player_repository.dart`, `schedule_repository.dart`, `game_repository.dart` |
| Providers | `lib/providers/teams_provider.dart`, `join_request_provider.dart`, `players_provider.dart`, `schedule_provider.dart`, `game_provider.dart` |
| Isar | `lib/providers/isar_provider.dart`, `lib/data/isar/isar_schemas.dart`, `lib/data/isar/models/*.dart` |
| Feature flags | `lib/core/feature_flags.dart` |
| Create team | `lib/features/teams/create_team_screen.dart` |
| Join team | `lib/features/teams/join_team_screen.dart` |
| Team detail (members, codes) | `lib/features/teams/team_detail_screen.dart` |
| Schedule CRUD | `lib/features/schedule/coach_schedule_screen.dart` |
| Game CRUD / dashboard | `lib/features/game/game_dashboard_screen.dart`, `lib/features/history/game_summary_screen.dart` |
| Game serialization | `lib/data/isar/models/game_serialization.dart` |
| Tests | `test/data/isar/`, `test/domain/services/`, `widget_test.dart` |

---

## Summary

- **Phase 1:** Backend auth + teams + membership API; mobile auth + API client + stubs calling API after local writes; remove Team.playerIds; add Team/JoinRequest updatedAt/updatedBy.
- **Phase 2:** Backend players + schedule_events CRUD and sync pull/push (no games); mobile ApiSyncProvider for pull/push + dirty tracking for Team, JoinRequest, Player, ScheduleEvent; parents read-only via existing TeamAuth.
- **Phase 3:** Backend games CRUD + sync + completed-quarters guard; mobile games in sync + conflict handling + delete game; optional team-scoped game list.

All tasks are intended to be 1–3 hours each. No code changes were made in this doc; it is implementation-ready.
