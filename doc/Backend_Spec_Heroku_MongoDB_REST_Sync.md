# Backend Spec (v2): Heroku + MongoDB Atlas + REST Sync

Aligned to Isar models in `lib/data/isar/models/`. Deploy backend on Heroku; data in MongoDB Atlas; sync via REST.

---

## 1) Mongo collections + JSON schema per entity

**Conventions:** All ids in API/DB are `uuid` (string). `updatedAt` is server-set (UTC). Optional fields omitted from payload may be absent or null. **Update tracking:** All collections use `updatedAt` and `updatedBy` only; no mixed naming (e.g. no `updatedByUserId` in API/DB).

---

### teams

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| uuid | string | yes | Unique business id |
| name | string | yes | |
| inviteCode | string | yes | 6–8 char uppercase |
| inviteCodeRotatedAt | string (ISO 8601) | no | |
| coachCode | string | yes | |
| coachCodeRotatedAt | string (ISO 8601) | no | |
| parentCode | string | yes | |
| parentCodeRotatedAt | string (ISO 8601) | no | |
| ownerUserId | string | no | Auth user id |
| createdAt | string (ISO 8601) | yes | |
| logoKind | string | no | none \| template \| monogram \| image |
| templateId | string | no | |
| paletteId | string | no | |
| monogramText | string | no | |
| imagePath | string | no | |
| **updatedAt** | string (ISO 8601) | yes | **Required model addition** — server time |
| **updatedBy** | string | no | **Required model addition** — userId |
| **deletedAt** | string (ISO 8601) | no | **Required model addition** — tombstone (optional if no soft-delete) |
| **schemaVersion** | int | no | **Required model addition** — default 1 |

**Scoping:** No teamId (root). Access control by membership: user must have a JoinRequest for this team with `status=active`. Players are authoritative in the **players** collection (by `teamId`); do not store a player list on Team.

---

### join_requests

**Model choice: single collection.** One collection holds both pending requests and active (approved) memberships. Status drives behavior; no separate TeamMember collection.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| uuid | string | yes | Unique |
| teamId | string | yes | → teams.uuid |
| userId | string | yes | Auth user id |
| coachName | string | yes | Display only |
| note | string | no | |
| role | string | yes | "owner" \| "coach" \| "parent" |
| status | string | yes | **"pending" \| "active" \| "rejected" \| "revoked"** — use **active** (not "approved"); all authorization uses status=active |
| requestedAt | string (ISO 8601) | yes | |
| approvedAt | string (ISO 8601) | no | Set when status becomes active |
| approvedByUserId | string | no | |
| **updatedAt** | string (ISO 8601) | yes | **Required model addition** — server time |
| **updatedBy** | string | no | **Required model addition** — userId |
| **deletedAt** | string (ISO 8601) | no | **Required model addition** — optional; use for revoke tombstone |

**Scoping:** teamId; also userId for "my requests". **Authorization:** Only rows with `status=active` grant access to team-scoped resources.

---

### players

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| uuid | string | yes | Unique |
| name | string | yes | |
| skill | string | yes | "strong" \| "developing" |
| teamId | string | no | → teams.uuid (team scoped) |
| createdAt | string (ISO 8601) | yes | |
| updatedAt | string (ISO 8601) | yes | Server overwrites on write |
| updatedBy | string | no | userId |
| deletedAt | string (ISO 8601) | no | Tombstone |
| schemaVersion | int | yes | Default 1 |

**Scoping:** teamId.

---

### schedule_events

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| uuid | string | yes | Unique |
| teamId | string | yes | → teams.uuid |
| type | string | yes | "practice" \| "game" |
| startsAt | string (ISO 8601) | yes | |
| endsAt | string (ISO 8601) | no | |
| location | string | no | |
| opponent | string | no | |
| notes | string | no | |
| createdAt | string (ISO 8601) | yes | |
| updatedAt | string (ISO 8601) | yes | Server overwrites |
| updatedBy | string | no | userId — **DTO:** Isar model has `updatedByUserId`; map to/from `updatedBy` in API and sync payloads |
| deletedAt | string (ISO 8601) | no | Tombstone |
| schemaVersion | int | yes | Default 1 |

**Scoping:** teamId.

---

### games

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| uuid | string | yes | Unique |
| startedAt | string (ISO 8601) | yes | |
| quartersTotal | int | yes | Default 6 |
| currentQuarter | int | yes | 1..6 |
| presentPlayerIds | array of string | yes | Player UUIDs |
| teamId | string | no | → teams.uuid |
| updatedAt | string (ISO 8601) | yes | Server overwrites |
| updatedBy | string | no | userId |
| deletedAt | string (ISO 8601) | no | Tombstone |
| schemaVersion | int | yes | Default 1 |
| quarterLineupsJson | string | yes | JSON: {"1":["uuid",...], ...} quarter → 5 player UUIDs |
| awardsJson | string | yes | JSON: {"christlikeness":["uuid"], ...} (keys AwardType.name) |
| completedQuartersJson | string | yes | JSON: [1,2,...] quarter numbers locked |

**Not stored in DB (required backend contract):**  
- **quartersPlayedJson** — client/local only; server must never persist. Derive from quarterLineups when needed (e.g. for analytics).  
- **quartersPlayedDerived** — not a field; client-only computed.

**Scoping:** teamId.

---

## 2) Required indexes per collection

- **teams:** `{ uuid: 1 }` unique; `{ updatedAt: 1 }` for sync pull; `{ deletedAt: 1 }` if soft-delete.
- **join_requests:** `{ uuid: 1 }` unique; `{ teamId: 1, status: 1 }`; `{ userId: 1, status: 1 }` (for "my active teams"); `{ updatedAt: 1 }` for sync.
- **players:** `{ uuid: 1 }` unique; `{ teamId: 1, deletedAt: 1 }`; `{ teamId: 1, updatedAt: 1 }` for sync.
- **schedule_events:** `{ uuid: 1 }` unique; `{ teamId: 1, deletedAt: 1 }`; `{ teamId: 1, updatedAt: 1 }` for sync.
- **games:** `{ uuid: 1 }` unique; `{ teamId: 1, deletedAt: 1 }`; `{ teamId: 1, updatedAt: 1 }` for sync.

---

## 3) Canonical server fields

| Field | Meaning | Who sets |
|-------|---------|----------|
| teamId | Scope to team (all entities except Team) | Client on create; required for scoped resources |
| updatedAt | Last modification time (UTC) | **Server only** — always server-generated; client value is ignored |
| updatedBy | userId of last modifier | Server sets from auth token; client value ignored for authority |
| deletedAt | Tombstone for soft-delete | Server sets on delete; null = alive |

**Naming:** API and DB use **updatedAt** and **updatedBy** only. Where Isar uses a different name (e.g. ScheduleEvent.updatedByUserId), the client DTO must map to/from **updatedBy** in all sync and REST payloads.

---

## 4) Security: membership-scoped filtering

**Rule:** All team-scoped access is gated by **active membership** only.

- **Active teamIds:** The set of team UUIDs for which the authenticated user has at least one `join_requests` document with `status=active` (and no `deletedAt` if used).
- **Team-scoped routes:** For every request to `/teams/:teamId/...` (players, schedule-events, games, or GET /teams/:uuid), the server must verify that `teamId` (or `:uuid` for GET team) is in the user’s active teamIds. If not, respond **403 Forbidden**.
- **Sync pull:** `GET /sync/pull?since=` must return only entities whose `teamId` is in the user’s active teamIds (and teams the user is active on). Do not return data for teams where the user is only pending, rejected, or revoked.
- **Sync push:** Accept upserts only for entities whose `teamId` is in the user’s active teamIds (and teams for create). Reject with **403** any batch item referencing a team for which the user is not active.

Document this rule in auth/middleware and in sync handlers so Phase 3 implementation applies it consistently.

---

## 5) REST endpoints

**Base:** `https://<app>.herokuapp.com/api` (or env). Auth: Bearer token; `userId` from auth. All team-scoped access requires the user to have **status=active** membership for that team (see Security above).

---

### Teams

| Method | Path | Description |
|--------|------|-------------|
| POST | /teams | Create team. Body: uuid, name, inviteCode?, coachCode?, parentCode?, ownerUserId?, logoKind?, templateId?, paletteId?, monogramText?, imagePath?. **No playerIds.** Server sets createdAt, updatedAt, updatedBy. Returns full document. |
| POST | /teams/:uuid/rotate-coach-code | Rotate coachCode; set coachCodeRotatedAt, updatedAt, updatedBy. |
| POST | /teams/:uuid/rotate-parent-code | Rotate parentCode; set parentCodeRotatedAt, updatedAt, updatedBy. |
| GET | /teams/:uuid | Read one team (only if user has active membership for this team). |

---

### Membership (join requests — single collection, status=active)

| Method | Path | Description |
|--------|------|-------------|
| POST | /membership/request-join | Body: code (inviteCode \| coachCode \| parentCode), userId, coachName, note?, role. Server resolves code → teamId, creates JoinRequest with status=pending, sets requestedAt, updatedAt, updatedBy. Returns JoinRequest. |
| GET | /membership/pending | Query: teamId (required). List join_requests where teamId + status=pending. Caller must be owner (active + role=owner) for that team. |
| POST | /membership/:uuid/approve | Body: approvedByUserId. Set **status=active**, approvedAt, updatedAt, updatedBy. |
| POST | /membership/:uuid/reject | Set status=rejected, updatedAt, updatedBy. |
| POST | /membership/:uuid/revoke | Set status=revoked (or deletedAt if using tombstone), updatedAt, updatedBy. |

All authorization for team data and sync uses **status=active** only.

---

### CRUD (team-scoped)

**Players**

| Method | Path | Description |
|--------|------|-------------|
| POST | /teams/:teamId/players | Create. Body: uuid, name, skill?, teamId (= teamId). Server sets createdAt, updatedAt, updatedBy. |
| GET | /teams/:teamId/players | List players for team (exclude deletedAt set, or include for sync). |
| GET | /teams/:teamId/players/:uuid | Read one. |
| PUT | /teams/:teamId/players/:uuid | Full update. Server sets updatedAt, updatedBy. |
| DELETE | /teams/:teamId/players/:uuid | Soft-delete: set deletedAt, updatedAt, updatedBy. |

**Schedule events**

| Method | Path | Description |
|--------|------|-------------|
| POST | /teams/:teamId/schedule-events | Create. Body: uuid, teamId, type, startsAt, endsAt?, location?, opponent?, notes?. Server sets createdAt, updatedAt, updatedBy. |
| GET | /teams/:teamId/schedule-events | List (optionally filter deletedAt). |
| GET | /teams/:teamId/schedule-events/:uuid | Read one. |
| PUT | /teams/:teamId/schedule-events/:uuid | Full update. Server sets updatedAt, updatedBy. |
| DELETE | /teams/:teamId/schedule-events/:uuid | Soft-delete: set deletedAt, updatedAt, updatedBy. |

**Games**

| Method | Path | Description |
|--------|------|-------------|
| POST | /teams/:teamId/games | Create. Body: uuid, startedAt, quartersTotal?, currentQuarter?, presentPlayerIds, teamId?, quarterLineupsJson?, awardsJson?, completedQuartersJson?. Server sets updatedAt, updatedBy. Do not accept quartersPlayedJson. |
| GET | /teams/:teamId/games | List (optionally filter deletedAt). |
| GET | /teams/:teamId/games/:uuid | Read one. |
| PUT | /teams/:teamId/games/:uuid | Full update. Server sets updatedAt, updatedBy. **Enforce completed-quarters guard:** do not allow changes to quarter lineups or completedQuartersJson for any quarter number that exists in the current document’s completedQuartersJson. Reject with **409 Conflict** or **400** if payload attempts such a change. Do not accept quartersPlayedJson. |
| DELETE | /teams/:teamId/games/:uuid | Soft-delete: set deletedAt, updatedAt, updatedBy. |

---

### Sync

| Method | Path | Description |
|--------|------|-------------|
| GET | /sync/pull | Query: since (ISO 8601). Return only entities for **active teamIds** (see Security). Response: teams (user is active), join_requests (for those teams), players, schedule_events, games with teamId in active teamIds, where updatedAt > since. Include tombstones (deletedAt set). Shape: { teams: [], joinRequests: [], players: [], scheduleEvents: [], games: [] }. Use **updatedBy** (not updatedByUserId). For games, omit quartersPlayedJson. |
| POST | /sync/push | Body: { teams?: [], joinRequests?: [], players?: [], scheduleEvents?: [], games?: [] }. Only accept items whose teamId is in the user’s **active teamIds**. For each item: upsert by uuid (and teamId where scoped), set **updatedAt = server time** (override client), **updatedBy** from auth. **Games:** enforce completed-quarters guard: do not apply changes to quarter lineups or completedQuartersJson for quarters already in the existing document’s completedQuartersJson; reject or merge so completed quarters are never reverted. Do not accept or store quartersPlayedJson. Optional: accept deletes as { uuid, deletedAt } or list of uuids to soft-delete. |

---

## 6) Conflict strategy (LWW)

- **LWW (last-write-wins):** Conflict resolution uses **server-generated updatedAt** only. The server **always** overwrites `updatedAt` with server clock on every create and update; client-supplied `updatedAt` is ignored. On pull, the client should treat server `updatedAt` as authoritative and overwrite local state when server `updatedAt` is newer (or follow a documented merge policy per entity).
- **Entities with no extra guard:** Team, JoinRequest, Player, ScheduleEvent — LWW is sufficient.
- **Games — server-side guard:**  
  - **Completed quarters:** On **PUT /teams/:teamId/games/:uuid** and on **POST /sync/push** (for games), the server must **enforce** that no modification is applied to lineup or completed status for any quarter number that is already in the stored `completedQuartersJson`. If the incoming payload would change or clear a completed quarter, reject that update (e.g. 409/400) or merge so completed quarters are preserved.  
  - **Enforcement locations:** PUT /teams/:teamId/games/:uuid and POST /sync/push (game items).

---

## 7) Required model additions and DTO mapping (summary)

- **Team (Isar):** Add `updatedAt`, `updatedBy`; optionally `deletedAt`, `schemaVersion`. **Remove** `playerIds` from schema and API; players are authoritative in the players collection.
- **JoinRequest (Isar):** Add `updatedAt`, `updatedBy`; optionally `deletedAt`. **Status:** Backend uses **active** (not "approved"). If Isar keeps `JoinRequestStatus.approved`, client DTO must map approved → active for API/sync and active → approved for local storage, or Isar can add an `active` value and deprecate `approved`.
- **ScheduleEvent (Isar):** Isar field `updatedByUserId` → API/sync always use **updatedBy**. Client DTO must map `updatedByUserId` ↔ `updatedBy` in all REST and sync payloads.
- **Backend/contract:** Never persist or return `quartersPlayedJson` or `quartersPlayedDerived` for games; client derives from `quarterLineupsJson`.

---

## Summary of changes (v1 → v2)

| # | Change |
|---|--------|
| 1 | **Removed playerIds** from Team schema and from all Team API contracts (create, responses). Players are authoritative in the players collection only. |
| 2 | **Standardized update tracking:** All collections use `updatedAt` and `updatedBy` only. ScheduleEvent: API/DB use `updatedBy`; DTO mapping from Isar `updatedByUserId` documented. No mixed naming in API. |
| 3 | **Membership model:** Single collection (JoinRequest only; no TeamMember). Status **active** replaces "approved". All authorization uses `status=active`. Pending / approve / reject / revoke documented; approve sets status=active. |
| 4 | **Membership-scoped filtering:** New **Security** section. All team-scoped routes and sync pull/push filter by active teamIds (teams where user has status=active). /sync/pull returns only entities for active teamIds; push accepts only items for active teamIds. |
| 5 | **Completed-quarters guard:** Documented and enforced on **PUT /teams/:teamId/games/:uuid** and **POST /sync/push** (game items). Server must not allow modifications to quarters already in completedQuartersJson. |
| 6 | **LWW clarified:** Server-generated `updatedAt` always overrides client time; client-supplied `updatedAt` is ignored. Documented in Canonical server fields and Conflict strategy. |
