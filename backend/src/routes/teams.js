const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { Team } = require('../models/Team');
const { TeamMember } = require('../models/TeamMember');
const { Player } = require('../models/Player');
const { ScheduleEvent } = require('../models/ScheduleEvent');
const { getActiveTeamIds, isOwner, canManageTeam, canBootstrapTeam } = require('../utils/membership');
const { generateUniqueCode } = require('../utils/codes');
const { joinLimiter, bootstrapLimiter } = require('../middleware/rateLimit');
const { requireOwner } = require('../middleware/guards');
const { validateTeamName, validateCoachName, validateNote, sanitizeString, LIMITS, isString } = require('../utils/validation');

const router = express.Router();

function normalizeCode(code) {
  return (code || '').trim().toUpperCase();
}

router.post('/', async (req, res, next) => {
  try {
    const userId = req.userId;
    const nameResult = validateTeamName(req.body);
    if (nameResult.error) return res.status(400).json(nameResult);
    const body = { ...req.body, name: nameResult.value, uuid: req.body?.uuid || uuidv4() };
    if (typeof body.uuid !== 'string') body.uuid = uuidv4();
    const team = await Team.createWithCodes(body, userId);
    const coachResult = validateCoachName(req.body?.coachName);
    const coachName = coachResult.error ? 'Owner' : (coachResult.value || 'Owner');
    await TeamMember.create({
      uuid: uuidv4(),
      teamId: team.uuid,
      userId,
      coachName,
      role: 'owner',
      status: 'active',
      requestedAt: new Date(),
      approvedAt: new Date(),
      approvedByUserId: userId,
      updatedAt: new Date(),
      updatedBy: userId,
    });
    res.status(201).json(toTeamJson(team));
  } catch (e) {
    next(e);
  }
});

router.post('/join', joinLimiter, async (req, res, next) => {
  try {
    const userId = req.userId;
    const code = req.body?.code;
    if (!code || !isString(code)) {
      return res.status(400).json({ error: 'validation', message: 'code and coachName are required' });
    }
    const coachResult = validateCoachName(req.body?.coachName);
    if (coachResult.error) return res.status(400).json(coachResult);
    const noteResult = validateNote(req.body?.note);
    if (noteResult.error) return res.status(400).json(noteResult);
    const normalized = normalizeCode(code);
    const team = await Team.findOne({
      $or: [{ inviteCode: normalized }, { coachCode: normalized }, { parentCode: normalized }],
      deletedAt: null,
    }).lean();
    if (!team) {
      return res.status(404).json({ error: 'not_found', message: 'Invalid or expired code' });
    }
    const activeMember = await TeamMember.findOne({
      teamId: team.uuid,
      userId,
      status: 'active',
      deletedAt: null,
    });
    if (activeMember) {
      return res.status(409).json({
        error: 'already_member',
        message: 'Already an active member of this team',
      });
    }
    const existingPending = await TeamMember.findOne({
      teamId: team.uuid,
      userId,
      status: 'pending',
      deletedAt: null,
    });
    if (existingPending) {
      return res.status(200).json(toMemberJson(existingPending));
    }
    let role = 'coach';
    if (team.coachCode === normalized) role = 'coach';
    else if (team.parentCode === normalized) role = 'parent';
    const now = new Date();
    const member = await TeamMember.create({
      uuid: uuidv4(),
      teamId: team.uuid,
      userId,
      coachName: coachResult.value,
      note: noteResult.value,
      role,
      status: 'pending',
      requestedAt: now,
      updatedAt: now,
      updatedBy: userId,
    });
    res.status(201).json(toMemberJson(member));
  } catch (e) {
    next(e);
  }
});

router.get('/', async (req, res, next) => {
  try {
    const userId = req.userId;
    const teamIds = await getActiveTeamIds(userId);
    if (teamIds.length === 0) {
      return res.json([]);
    }
    const teams = await Team.find({ uuid: { $in: teamIds }, deletedAt: null }).lean();
    res.json(teams.map(toTeamJson));
  } catch (e) {
    next(e);
  }
});

router.get('/:teamId/requests', requireOwner, async (req, res, next) => {
  try {
    const { teamId } = req.params;
    const list = await TeamMember.find({
      teamId,
      status: 'pending',
      deletedAt: null,
    })
      .sort({ requestedAt: -1 })
      .lean();
    res.json(list.map(toMemberJson));
  } catch (e) {
    next(e);
  }
});

router.post('/:teamId/requests/:requestId/approve', requireOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, requestId } = req.params;
    const member = await TeamMember.findOne({
      uuid: requestId,
      teamId,
      status: 'pending',
      deletedAt: null,
    });
    if (!member) {
      return res.status(404).json({ error: 'not_found', message: 'Request not found' });
    }
    const now = new Date();
    member.status = 'active';
    member.approvedAt = now;
    member.approvedByUserId = userId;
    member.updatedAt = now;
    member.updatedBy = userId;
    await member.save();
    res.json(toMemberJson(member));
  } catch (e) {
    next(e);
  }
});

router.post('/:teamId/requests/:requestId/reject', requireOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, requestId } = req.params;
    const member = await TeamMember.findOne({
      uuid: requestId,
      teamId,
      status: 'pending',
      deletedAt: null,
    });
    if (!member) {
      return res.status(404).json({ error: 'not_found', message: 'Request not found' });
    }
    const now = new Date();
    member.status = 'rejected';
    member.updatedAt = now;
    member.updatedBy = userId;
    await member.save();
    res.json(toMemberJson(member));
  } catch (e) {
    next(e);
  }
});

router.post('/:teamId/members/:memberId/revoke', requireOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, memberId } = req.params;
    const member = await TeamMember.findOne({
      uuid: memberId,
      teamId,
      status: 'active',
      deletedAt: null,
    });
    if (!member) {
      return res.status(404).json({ error: 'not_found', message: 'Member not found' });
    }
    if (member.userId === userId && (await isOwner(teamId, userId))) {
      return res.status(400).json({ error: 'validation', message: 'Cannot revoke yourself as owner' });
    }
    const now = new Date();
    member.status = 'revoked';
    member.updatedAt = now;
    member.updatedBy = userId;
    member.deletedAt = now;
    await member.save();
    res.json(toMemberJson(member));
  } catch (e) {
    next(e);
  }
});

router.post('/:teamId/rotate-code', requireOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId } = req.params;
    const type = (req.query.type || '').toLowerCase();
    if (!['coach', 'parent'].includes(type)) {
      return res.status(400).json({ error: 'validation', message: 'query type must be coach or parent' });
    }
    const team = await Team.findOne({ uuid: teamId, deletedAt: null });
    if (!team) {
      return res.status(404).json({ error: 'not_found', message: 'Team not found' });
    }
    const existing = await Team.find(
      {},
      type === 'coach' ? { coachCode: 1 } : { parentCode: 1 }
    ).lean();
    const codes = new Set(existing.flatMap((t) => (type === 'coach' ? [t.coachCode] : [t.parentCode])));
    const newCode = generateUniqueCode(codes);
    const now = new Date();
    if (type === 'coach') {
      team.coachCode = newCode;
      team.coachCodeRotatedAt = now;
    } else {
      team.parentCode = newCode;
      team.parentCodeRotatedAt = now;
    }
    team.updatedAt = now;
    team.updatedBy = userId;
    await team.save();
    res.json(toTeamJson(team));
  } catch (e) {
    next(e);
  }
});

const BOOTSTRAP_MAX_PLAYERS = 30;
const BOOTSTRAP_MAX_SCHEDULE_EVENTS = 200;

router.post('/:teamId/bootstrap', bootstrapLimiter, requireOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId } = req.params;
    const team = await Team.findOne({ uuid: teamId, deletedAt: null });
    if (!team) {
      return res.status(404).json({ error: 'not_found', message: 'Team not found' });
    }
    const rawBody = req.body || {};
    const playersPayload = Array.isArray(rawBody.players) ? rawBody.players : [];
    const eventsPayload = Array.isArray(rawBody.scheduleEvents) ? rawBody.scheduleEvents : [];
    if (playersPayload.length > BOOTSTRAP_MAX_PLAYERS) {
      return res.status(400).json({ error: 'validation', message: `players must not exceed ${BOOTSTRAP_MAX_PLAYERS}` });
    }
    if (eventsPayload.length > BOOTSTRAP_MAX_SCHEDULE_EVENTS) {
      return res.status(400).json({ error: 'validation', message: `scheduleEvents must not exceed ${BOOTSTRAP_MAX_SCHEDULE_EVENTS}` });
    }
    const now = new Date();
    const outPlayers = [];
    for (const p of playersPayload) {
      if (!p || typeof p !== 'object' || !p.uuid || !isString(p.uuid)) continue;
      if (p.teamId != null && p.teamId !== teamId) {
        return res.status(400).json({ error: 'validation', message: `Player ${p.uuid} teamId does not match` });
      }
      const teamIdEnforced = teamId;
      const createdAt = p.createdAt ? new Date(p.createdAt) : null;
      const deletedAt = p.deletedAt ? new Date(p.deletedAt) : null;
      const doc = {
        uuid: p.uuid,
        teamId: teamIdEnforced,
        name: sanitizeString(p.name, LIMITS.playerName) || 'Player',
        skill: ['strong', 'developing'].includes(p.skill) ? p.skill : 'developing',
        updatedAt: now,
        updatedBy: userId,
        schemaVersion: typeof p.schemaVersion === 'number' ? p.schemaVersion : 1,
      };
      const existing = await Player.findOne({ uuid: p.uuid });
      if (existing) {
        existing.teamId = doc.teamId;
        existing.name = doc.name;
        existing.skill = doc.skill;
        existing.updatedAt = now;
        existing.updatedBy = userId;
        existing.schemaVersion = doc.schemaVersion;
        existing.deletedAt = deletedAt ?? existing.deletedAt;
        await existing.save();
        outPlayers.push(toPlayerJson(existing));
      } else {
        const created = await Player.create({
          ...doc,
          createdAt: createdAt && !Number.isNaN(createdAt.getTime()) ? createdAt : now,
          deletedAt: deletedAt && !Number.isNaN(deletedAt.getTime()) ? deletedAt : null,
        });
        outPlayers.push(toPlayerJson(created));
      }
    }
    const outEvents = [];
    for (const e of eventsPayload) {
      if (!e || typeof e !== 'object' || !e.uuid || !isString(e.uuid)) continue;
      if (e.teamId != null && e.teamId !== teamId) {
        return res.status(400).json({ error: 'validation', message: `ScheduleEvent ${e.uuid} teamId does not match` });
      }
      const startsAt = e.startsAt ? new Date(e.startsAt) : null;
      if (!startsAt || Number.isNaN(startsAt.getTime())) continue;
      const deletedAt = e.deletedAt ? new Date(e.deletedAt) : null;
      const doc = {
        uuid: e.uuid,
        teamId,
        type: ['practice', 'game'].includes(e.type) ? e.type : 'practice',
        startsAt,
        endsAt: e.endsAt ? new Date(e.endsAt) : null,
        location: e.location != null ? sanitizeString(e.location, LIMITS.location) : null,
        opponent: e.opponent != null ? sanitizeString(e.opponent, LIMITS.opponent) : null,
        notes: e.notes != null ? sanitizeString(e.notes, LIMITS.scheduleNotes) : null,
        updatedAt: now,
        updatedBy: userId,
        deletedAt: deletedAt && !Number.isNaN(deletedAt.getTime()) ? deletedAt : null,
        schemaVersion: typeof e.schemaVersion === 'number' ? e.schemaVersion : 1,
      };
      const existing = await ScheduleEvent.findOne({ uuid: e.uuid });
      if (existing) {
        existing.teamId = doc.teamId;
        existing.type = doc.type;
        existing.startsAt = doc.startsAt;
        existing.endsAt = doc.endsAt;
        existing.location = doc.location;
        existing.opponent = doc.opponent;
        existing.notes = doc.notes;
        existing.updatedAt = now;
        existing.updatedBy = userId;
        existing.deletedAt = doc.deletedAt;
        existing.schemaVersion = doc.schemaVersion;
        await existing.save();
        outEvents.push(toEventJson(existing));
      } else {
        const created = await ScheduleEvent.create(doc);
        outEvents.push(toEventJson(created));
      }
    }
    res.status(200).json({
      serverTime: now.toISOString(),
      players: outPlayers,
      scheduleEvents: outEvents,
    });
  } catch (err) {
    next(err);
  }
});

function toPlayerJson(doc) {
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    uuid: d.uuid,
    teamId: d.teamId,
    name: d.name,
    skill: d.skill,
    createdAt: d.createdAt?.toISOString?.() ?? d.createdAt,
    updatedAt: d.updatedAt?.toISOString?.() ?? d.updatedAt,
    updatedBy: d.updatedBy,
    deletedAt: d.deletedAt?.toISOString?.() ?? d.deletedAt,
    schemaVersion: d.schemaVersion,
  };
}

function toEventJson(doc) {
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    uuid: d.uuid,
    teamId: d.teamId,
    type: d.type,
    startsAt: d.startsAt?.toISOString?.() ?? d.startsAt,
    endsAt: d.endsAt?.toISOString?.() ?? d.endsAt,
    location: d.location,
    opponent: d.opponent,
    notes: d.notes,
    updatedAt: d.updatedAt?.toISOString?.() ?? d.updatedAt,
    updatedBy: d.updatedBy,
    deletedAt: d.deletedAt?.toISOString?.() ?? d.deletedAt,
    schemaVersion: d.schemaVersion,
  };
}

function toTeamJson(doc) {
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    uuid: d.uuid,
    name: d.name,
    ownerUserId: d.ownerUserId,
    inviteCode: d.inviteCode,
    inviteCodeRotatedAt: d.inviteCodeRotatedAt?.toISOString?.() ?? d.inviteCodeRotatedAt,
    coachCode: d.coachCode,
    coachCodeRotatedAt: d.coachCodeRotatedAt?.toISOString?.() ?? d.coachCodeRotatedAt,
    parentCode: d.parentCode,
    parentCodeRotatedAt: d.parentCodeRotatedAt?.toISOString?.() ?? d.parentCodeRotatedAt,
    createdAt: d.createdAt?.toISOString?.() ?? d.createdAt,
    updatedAt: d.updatedAt?.toISOString?.() ?? d.updatedAt,
    updatedBy: d.updatedBy,
    deletedAt: d.deletedAt?.toISOString?.() ?? d.deletedAt,
  };
}

function toMemberJson(doc) {
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    uuid: d.uuid,
    teamId: d.teamId,
    userId: d.userId,
    coachName: d.coachName,
    note: d.note,
    role: d.role,
    status: d.status,
    requestedAt: d.requestedAt?.toISOString?.() ?? d.requestedAt,
    approvedAt: d.approvedAt?.toISOString?.() ?? d.approvedAt,
    approvedByUserId: d.approvedByUserId,
    updatedAt: d.updatedAt?.toISOString?.() ?? d.updatedAt,
    updatedBy: d.updatedBy,
    deletedAt: d.deletedAt?.toISOString?.() ?? d.deletedAt,
  };
}

module.exports = router;
module.exports.toTeamJson = toTeamJson;
module.exports.toMemberJson = toMemberJson;
