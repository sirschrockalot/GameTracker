# Multi-Coach & Multi-Device Sync — Implementation Plan

This plan enables multiple coaches to see and share the same team data and have data sync across users’ devices. Work items are ordered by priority and dependency; complete in sequence where dependencies exist.

---

## Phase 1: Backend & Identity (Foundation)

### 1.1 Choose and provision backend
- [ ] **1.1.1** Choose backend stack (e.g. Firebase Firestore + Cloud Functions, Supabase, or custom REST/GraphQL API).
- [ ] **1.1.2** Define backend data model for: Team, JoinRequest (membership), Player, ScheduleEvent, Game — aligned with existing Isar models and team-scoping (`teamId`).
- [ ] **1.1.3** Add `updatedAt` / `updatedBy` (or equivalent) to all synced entities on the backend for conflict detection and audit.
- [ ] **1.1.4** Implement server-side access control: only members of a team can read/write that team’s data; enforce owner-only for team admin, owner/coach for coach tools, and read-only for parents where applicable (mirror `lib/domain/authorization/team_auth.dart`).

### 1.2 Authentication
- [ ] **1.2.1** Integrate a real auth provider (e.g. Firebase Auth, Supabase Auth, or custom) so every user has a stable, unique `userId` across devices.
- [ ] **1.2.2** Replace `currentUserIdProvider` in `lib/providers/current_user_provider.dart` with the real authenticated user id (and handle unauthenticated state: sign-in/sign-out flows).
- [ ] **1.2.3** Ensure sign-in is required before accessing team list / join / team detail (or show limited UI and prompt sign-in).
- [ ] **1.2.4** (Optional) Add display name or email from auth for “who approved” / “who changed” in UI and sync metadata.

---

## Phase 2: Backend API for Teams & Membership

### 2.1 Teams and membership API
- [ ] **2.1.1** Implement API to create/read/update Team (create = owner; update = owner only; include `ownerUserId`, `coachCode`, `parentCode`, etc.).
- [ ] **2.1.2** Implement API for join requests: create pending request (by code → role), list pending by team (owner only), approve/reject/revoke (owner only), list approved members by team.
- [ ] **2.1.3** Enforce: only owner can rotate codes, approve/reject, revoke; coaches/parents cannot modify membership.
- [ ] **2.1.4** Add backend validation for coach name, note, and dedupe rules (e.g. one pending per user/team/role; no duplicate approved membership).

### 2.2 Team-scoped data API
- [ ] **2.2.1** Players: CRUD scoped by `teamId`; access only for team members; optional `teamId` on client already — align backend with that.
- [ ] **2.2.2** Schedule events: CRUD by `teamId`; create/update/delete only for owner/coach; read for all approved members (including parents).
- [ ] **2.2.3** Games: CRUD by `teamId` (Game already has `teamId`); restrict write to owner/coach; include quarter lineups, awards, completed quarters in API payload.
- [ ] **2.2.4** Return only data for teams the authenticated user is an approved member of (or is owner of).

---

## Phase 3: Sync Layer (Replace MockSyncProvider)

### 3.1 Sync provider implementation
- [ ] **3.1.1** Implement a real `SyncProvider` (e.g. `FirebaseSyncProvider` or `ApiSyncProvider`) that:
  - Pushes local changes (create/update/delete) for Team, JoinRequest, Player, ScheduleEvent, Game to the backend.
  - Pulls from backend the set of teams the user is a member of plus all related entities (or incremental updates).
- [ ] **3.1.2** Define which operations trigger a push (e.g. on repo add/update/delete for synced entities) and when to pull (e.g. app foreground, after push, periodic, or real-time listeners).
- [ ] **3.1.3** Map backend entities to Isar models and vice versa; handle UUIDs consistently so the same entity has the same id in backend and local DB.

### 3.2 Conflict handling and ordering
- [ ] **3.2.1** Choose a strategy: last-write-wins (LWW) using `updatedAt`, or version vectors / server-authoritative for critical fields.
- [ ] **3.2.2** On pull: merge into Isar (insert or update by id); handle soft deletes (e.g. ScheduleEvent) so deleted items are removed or marked locally.
- [ ] **3.2.3** On push: send only changed entities (or full state for simplicity); ensure backend rejects or overwrites in a consistent way when conflicts occur.
- [ ] **3.2.4** Update `SyncStatus` (offline / syncing / upToDate) in the real provider based on push/pull success and connectivity; keep `syncStatusStreamProvider` so UI can show sync state if desired.

### 3.3 Local-first behavior
- [ ] **3.3.1** Keep writes going to Isar first; sync in the background so the app remains usable offline.
- [ ] **3.3.2** When offline, queue pushes (or mark dirty) and flush when back online; show offline/syncing state in UI if needed.
- [ ] **3.3.3** Ensure repositories (team, player, schedule, game, join request) remain the single place for reads/writes; sync layer subscribes or is invoked from repos/app lifecycle, not from random widgets.

---

## Phase 4: Onboarding and “My Teams” Across Devices

### 4.1 First-time and new device
- [ ] **4.1.1** After sign-in, pull list of teams the user is a member of (from backend); create or update local Team and JoinRequest records so “My Teams” matches backend.
- [ ] **4.1.2** For each team the user has access to, pull players, schedule events, and games (or subscribe to real-time updates) so local Isar is populated.
- [ ] **4.1.3** When a user joins a new team (via code + approval), ensure the new membership and team metadata are synced to all their devices on next pull or push.

### 4.2 Owner-created teams
- [ ] **4.2.1** When owner creates a team locally, push Team to backend and set `ownerUserId`; then push initial membership (owner) so backend is source of truth.
- [ ] **4.2.2** Ensure invite codes and join requests flow through backend so other coaches/parents can join and see the same team id and data.

---

## Phase 5: Validation and Edge Cases

### 5.1 Data integrity
- [ ] **5.1.1** Validate on backend: team exists, user is approved member (with correct role) before allowing read/write of that team’s data.
- [ ] **5.1.2** Ensure revoke/remove member is synced so revoked users lose access on all devices after next pull.
- [ ] **5.1.3** Handle “owner leaves” or “last coach leaves” if applicable (e.g. transfer ownership or block delete).

### 5.2 Schema and migrations
- [ ] **5.2.1** Version backend schema and/or API; support backward-compatible additions so existing clients keep working during rollout.
- [ ] **5.2.2** If Isar schema changes for sync (e.g. add `updatedAt` or sync flags), add migration and ensure sync layer reads/writes only fields that exist.

---

## Phase 6: Optional Enhancements

### 6.1 Real-time and UX
- [ ] **6.1.1** (Optional) Use real-time listeners (e.g. Firestore snapshots, Supabase realtime) for teams the user is in so changes from other coaches appear without manual refresh.
- [ ] **6.1.2** (Optional) Re-enable or refine sync status indicator in UI (e.g. “Syncing…” / “Up to date” / “Offline”) using `syncStatusStreamProvider`.

### 6.2 Performance and scale
- [ ] **6.2.1** (Optional) Incremental sync: only fetch entities updated since last sync timestamp to reduce payload size.
- [ ] **6.2.2** (Optional) Paginate or limit large lists (e.g. games per team) on backend and in pull.

---

## Reference: Existing Codebase

| Area | Location | Notes |
|------|----------|--------|
| Roles & permissions | `lib/domain/authorization/team_auth.dart` | Mirror server-side: canViewTeam, canUseCoachTools, canManageTeam |
| Membership model | `lib/data/isar/models/join_request.dart` | teamId, userId, role, status; map to backend |
| Sync interface | `lib/domain/sync/sync_provider.dart`, `lib/data/sync/mock_sync_provider.dart` | Replace mock with real implementation |
| Current user | `lib/providers/current_user_provider.dart` | Replace placeholder with real auth |
| Team-scoped data | Game.teamId, ScheduleEvent.teamId, Player.teamId | Already scoped; ensure backend uses same ids |
| Repositories | `lib/data/repositories/*` | Keep as single write path; hook sync from here or app lifecycle |

---

## Priority Summary

1. **Phase 1** — Backend choice + auth (required for everything else).
2. **Phase 2** — Backend APIs so data has a shared home and access is enforced.
3. **Phase 3** — Sync implementation so devices read/write the same data.
4. **Phase 4** — Onboarding and “my teams” so multiple coaches and devices see the same teams and data.
5. **Phase 5** — Validation and edge cases so behavior is correct and secure.
6. **Phase 6** — Optional improvements (real-time, incremental sync, UX).

Work in this order; later phases can be broken into smaller tickets as needed.
