# Phase 2.5 — Parent Schedule (Read-Only) + Dual Join Codes (Coach/Parent)

## Goal
Add a parent-facing experience to view **game + practice schedules** for a team.
Parents must NOT access coach-only tools (lineups, fairness, awards, game history, admin).

Owners must approve all users, but we will introduce **two join codes**:
- **Coach Code**: used by coaches to request coach access
- **Parent Code**: used by parents to request parent access

Approval is still required for both; code determines the requested role.

---

## Non-Goals
- No push notifications (future)
- No calendar sync (ICS) in this phase (future)
- No parent access to player list, lineups, awards, or internal game tools

---

## Roles & Permissions

### Roles
- `owner`
- `coach`
- `parent`

### Statuses
- `pending`
- `active`
- `rejected`
- `revoked`

### Permission Rules (App + Backend later)
- Coach tools (lineups, awards, game control): `owner|coach` only, and `status=active`
- Schedule view:
  - `owner|coach|parent` can view schedule if `status=active`
- Schedule management (create/edit/delete):
  - `owner|coach` only, and `status=active`
- Team administration (approve/reject members, rotate codes):
  - `owner` only, and `status=active`

**Important:** Once cloud is added, these must also be enforced server-side.

---

## Team Codes (Dual Codes)

### Team fields
- `coachCode`: 6–8 chars, uppercase, exclude ambiguous chars (0,O,1,I)
- `parentCode`: same format

### Code Behavior
- Code is used only to create a **membership request** (pending).
- Owner must approve the request.
- Owner can rotate either code at any time:
  - Rotating does NOT affect existing members.
  - Rotating affects only future join requests.
- Dedupe requests:
  - same user cannot create multiple pending requests for same team/role.

---

## Data Model Changes

### Team
- `id` (uuid)
- `name`
- `coachCode`
- `parentCode`
- `ownerUserId`
- `createdAt`, `updatedAt`

### TeamMember
- `id` (uuid)
- `teamId`
- `userId` (auth identity; internal use)
- `coachName` (display label)
- `note` (optional, used in pending request UI only)
- `role` (`owner|coach|parent`)
- `status` (`pending|active|rejected|revoked`)
- `requestedAt`
- `approvedAt` (nullable)
- `approvedByUserId` (nullable)
- `updatedAt`

### ScheduleEvent (new)
- `id` (uuid)
- `teamId`
- `type` (`practice|game`)
- `startsAt` (DateTime)
- `endsAt` (DateTime, nullable)
- `location` (nullable)
- `opponent` (nullable; game only)
- `notes` (nullable)
- `createdAt`, `updatedAt`, `updatedBy`, `deletedAt` (nullable), `schemaVersion`

### Existing Models
- Add `teamId` (nullable) on `Player` and `Game` (if not already done).
- Prefer not to store derived fields in cloud path (quartersPlayed derived from lineups).

---

## UI / Navigation

### Join Team Screen
Inputs:
- Team Code
- Coach Name
- Note (optional; e.g., "Chris – Wednesday assistant coach")

Behavior:
- If code matches `coachCode` → request role = `coach`
- If code matches `parentCode` → request role = `parent`
- Otherwise error: invalid code

### Owner Admin — Team Management
- Display both codes with copy buttons:
  - Coach Code + Rotate
  - Parent Code + Rotate
- Pending requests list shows:
  - coachName + requestedAt
  - note (if present)
  - requestedRole (Coach/Parent)
  - Approve / Reject
- Member list grouped by role:
  - Active members with Remove (sets revoked)

### Parent Experience
- ParentHome (Schedule only)
- Schedule view:
  - Upcoming list grouped by date
  - Each item shows: time, Practice/Game badge, location, opponent (if game), notes
- Parents see no coach navigation, no coach screens, no deep-link access

### Coach Experience
- Add "Schedule" to coach navigation
- Schedule management (CRUD):
  - list events
  - add/edit/delete event via a form

---

## Validation Rules

### Coach Name
- required, trimmed
- length 2..40

### Note
- optional, trimmed
- length <= 80
- strip control chars, collapse repeated spaces

### Schedule Event
- startsAt required
- if endsAt present: endsAt > startsAt
- opponent shown only if type=game (store nullable)

---

## Implementation Strategy (Local-First, Cloud-Ready)
- Implement everything using local storage (Isar) first.
- Maintain repository abstractions and a SyncProvider interface for Phase 3.
- Enforce role-based routing and guard rails in-app now.

---

## Deliverables Checklist
1. Extend Team: add coachCode + parentCode, code generation, rotation
2. Join flow: code determines requestedRole; create pending TeamMember with role + note
3. Owner approval UI: show role + note; approve/reject; member list by role
4. Role-based routing:
   - parent -> ParentHome
   - coach/owner -> CoachHome
5. ScheduleEvent model + repo
6. Parent schedule read-only UI
7. Coach schedule CRUD UI
8. Validation + dedupe requests
9. (Optional) Sync interfaces / status badge stubs remain intact

---

## Testing Scenarios
- Parent joins with parentCode -> pending parent request -> approved -> sees schedule only
- Coach joins with coachCode -> pending coach request -> approved -> sees coach tools + schedule
- Parent cannot access coach screens via navigation/back stack
- Owner can rotate either code
- Schedule CRUD works; parent view updates from local storage
- Validation prevents invalid dates and overly long notes
