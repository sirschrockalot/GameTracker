# Model Inventory & Multi-Coach Sync Readiness

Source of truth: `lib/data/isar/models/`

---

## A) Model Inventory

### Team
- **Primary id:** `Id id = Isar.autoIncrement`
- **Ids:** `uuid` (String, unique index); app generates UUID on create.
- **Fields:**
  - uuid: String, non-null
  - name: String, non-null
  - playerIds: List\<String\>, non-null, default []
  - inviteCode: String, non-null, default from TeamCodeGenerator
  - inviteCodeRotatedAt: DateTime?, nullable
  - coachCode: String, non-null, default from TeamCodeGenerator
  - coachCodeRotatedAt: DateTime?, nullable
  - parentCode: String, non-null, default from TeamCodeGenerator
  - parentCodeRotatedAt: DateTime?, nullable
  - ownerUserId: String?, nullable
  - createdAt: DateTime, non-null, default DateTime.now()
  - logoKind: String?, nullable
  - templateId: String?, nullable
  - paletteId: String?, nullable
  - monogramText: String?, nullable
  - imagePath: String?, nullable
- **Relationships:** None (root entity). ownerUserId links to auth; playerIds references Player.uuid.
- **Serialization:** None (no JSON strings/maps).
- **Timestamps/version:** createdAt only. No updatedAt, updatedBy, deletedAt, schemaVersion.

---

### JoinRequest
- **Primary id:** `Id id = Isar.autoIncrement`
- **Ids:** `uuid` (String, unique index); app generates UUID on create.
- **Fields:**
  - uuid: String, non-null
  - teamId: String, non-null
  - userId: String, non-null
  - coachName: String, non-null
  - note: String?, nullable
  - role: TeamMemberRole (enum), non-null
  - status: JoinRequestStatus (enum), non-null, default pending
  - requestedAt: DateTime, non-null, default DateTime.now()
  - approvedAt: DateTime?, nullable
  - approvedByUserId: String?, nullable
- **Relationships:** teamId → Team.uuid; userId / approvedByUserId → auth.
- **Serialization:** None.
- **Timestamps/version:** requestedAt, approvedAt. No updatedAt, updatedBy, deletedAt, schemaVersion.

---

### Player
- **Primary id:** `Id id = Isar.autoIncrement`
- **Ids:** `uuid` (String, unique index); app generates UUID on create.
- **Fields:**
  - uuid: String, non-null
  - name: String, non-null
  - skill: Skill (enum), non-null, default developing
  - teamId: String?, nullable
  - createdAt: DateTime, non-null, default DateTime.now()
  - updatedAt: DateTime, non-null, default DateTime.now()
  - updatedBy: String?, nullable
  - deletedAt: DateTime?, nullable
  - schemaVersion: int, non-null, default 1
- **Relationships:** teamId → Team.uuid.
- **Serialization:** None.
- **Timestamps/version:** createdAt, updatedAt, updatedBy, deletedAt, schemaVersion.

---

### Game
- **Primary id:** `Id id = Isar.autoIncrement`
- **Ids:** `uuid` (String, unique index); app generates UUID on create.
- **Fields:**
  - uuid: String, non-null
  - startedAt: DateTime, non-null
  - quartersTotal: int, non-null, default 6
  - currentQuarter: int, non-null, default 1
  - presentPlayerIds: List\<String\>, non-null
  - teamId: String?, nullable
  - updatedAt: DateTime, non-null, default startedAt
  - updatedBy: String?, nullable
  - deletedAt: DateTime?, nullable
  - schemaVersion: int, non-null, default 1
  - quarterLineupsJson: String, non-null (stored)
  - quartersPlayedJson: String, non-null (stored)
  - awardsJson: String, non-null (stored)
  - completedQuartersJson: String, non-null (stored)
- **Relationships:** teamId → Team.uuid; presentPlayerIds / lineups / awards reference Player.uuid.
- **Serialization (game_serialization.dart):**
  - quarterLineupsJson ↔ Map\<int, List\<String\>> (quarter 1..6 → 5 player UUIDs); getter/setter quarterLineups (@ignore).
  - quartersPlayedJson ↔ Map\<String, int\> (player UUID → count); getter/setter quartersPlayed (@ignore). Comment: "Local cache only; sync derives from quarterLineups."
  - awardsJson ↔ Map\<AwardType, List\<String\>>; getter/setter awards (@ignore).
  - completedQuartersJson ↔ Set\<int\> (quarter numbers 1..6 locked); getter/setter completedQuarters (@ignore).
  - quartersPlayedDerived (@ignore getter): computed from quarterLineups via GameSerialization.computeQuartersPlayedFromLineups (not stored).
- **Timestamps/version:** updatedAt, updatedBy, deletedAt, schemaVersion.

---

### ScheduleEvent
- **Primary id:** `Id id = Isar.autoIncrement`
- **Ids:** `uuid` (String, unique index); app generates UUID on create.
- **Fields:**
  - uuid: String, non-null
  - teamId: String, non-null
  - type: ScheduleEventType (enum), non-null
  - startsAt: DateTime, non-null
  - endsAt: DateTime?, nullable
  - location: String?, nullable
  - opponent: String?, nullable
  - notes: String?, nullable
  - createdAt: DateTime, non-null, default DateTime.now()
  - updatedAt: DateTime, non-null, default DateTime.now()
  - updatedByUserId: String?, nullable
  - deletedAt: DateTime?, nullable
  - schemaVersion: int, non-null, default 1
- **Relationships:** teamId → Team.uuid.
- **Serialization:** None.
- **Timestamps/version:** createdAt, updatedAt, updatedByUserId, deletedAt, schemaVersion.

---

## B) Sync Readiness Gaps

- **Team:** No updatedAt, updatedBy, deletedAt, or schemaVersion; cannot track last change or soft-delete for sync.
- **JoinRequest:** No updatedAt, updatedBy, or deletedAt; status/role changes and revokes not timestamped for sync/conflict.
- **Game.quartersPlayedJson:** Documented as "Local cache only; sync derives from quarterLineups." Storing it remotely would duplicate derived state; sync should send only quarterLineups (and optionally not persist quartersPlayedJson in cloud).
- **Game.quartersPlayedDerived:** Correctly not stored; ensure backend/sync never persist this as a field.
- **Player:** Has teamId, updatedAt, updatedBy, deletedAt, schemaVersion — no gaps for sync fields.
- **ScheduleEvent:** Has teamId, updatedAt, updatedByUserId, deletedAt, schemaVersion — no gaps.
- **Game:** Has teamId, updatedAt, updatedBy, deletedAt, schemaVersion — no gaps except quartersPlayedJson treatment above.
- **JoinRequest:** Has teamId and userId; missing updatedAt/updatedBy makes "last modified" and conflict resolution harder for approve/reject/revoke.

---

## C) Minimal Change Recommendations

1. **Team:** Add `updatedAt` (DateTime), `updatedBy` (String?), and optionally `deletedAt` (DateTime?) and `schemaVersion` (int) for sync and soft-delete.
2. **JoinRequest:** Add `updatedAt` (DateTime) and `updatedBy` (String?) (and optionally `deletedAt` if you treat revoke as soft-delete) for sync and conflict ordering.
3. **Sync/backend contract:** Treat Game.quartersPlayedJson as local-only; do not persist or restore it from cloud; derive from quarterLineups on pull.
4. **Sync/backend contract:** Do not add a remote field for Game.quartersPlayedDerived; keep it app-side only.
5. **Team:** If teams can be "removed" for a user (e.g. leave team), add Team.deletedAt or equivalent and filter by it on sync; otherwise document that Team delete is hard-delete and out of scope for sync.
6. **JoinRequest:** Set updatedAt/updatedBy when status or role changes (approve, reject, revoke) so sync can order and merge correctly.
7. **Team:** Set updatedAt/updatedBy on any Team field change (name, codes, logo, playerIds) so sync can detect and push changes.
8. **Ids:** Keep using uuid as the stable business id for all entities in sync/API; keep Isar Id as local only.
9. **Schema versioning:** Use schemaVersion (or a single global schema version) in sync payloads so clients can migrate or reject incompatible data.
10. **Conflict strategy:** Document or implement last-write-wins using updatedAt (and optionally updatedBy) for Team, JoinRequest, Player, Game, ScheduleEvent so backend and clients converge.
