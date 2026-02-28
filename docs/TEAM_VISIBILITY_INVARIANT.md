# Team visibility invariant

**Rule (backend + mobile):**

A user sees a team in their app **only if** they have an **ACTIVE** membership for that team **or** they are the team owner (`ownerUserId === currentUserId`).

If membership becomes **revoked**, **rejected**, or **deleted** (soft-delete), the team **must** disappear from their device and all team-scoped data must become inaccessible.

**Backend:**  
- `GET /teams` returns only teams where caller has active membership or is owner.  
- `GET /sync/pull` returns entities only for `allowedTeamIds` (active memberships + owner teams).  
- `GET /me/memberships` returns all memberships for the caller (including revoked/rejected) so the client can remove teams.

**Mobile:**  
- Teams list shows only teams in `allowedTeamIds` (from local memberships: status active + owner teams).  
- On membership sync, revoke/reject causes team to be removed from `allowedTeamIds` and local team + roster/schedule/games data for that team are cleaned up.  
- Route guard: navigating to a team not in `allowedTeamIds` redirects to `/teams`.
