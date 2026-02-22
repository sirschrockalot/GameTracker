const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { Team } = require('../models/Team');
const { TeamMember } = require('../models/TeamMember');
const { getActiveTeamIds, isOwner, canManageTeam } = require('../utils/membership');
const { generateUniqueCode } = require('../utils/codes');
const { joinLimiter } = require('../middleware/rateLimit');

const router = express.Router();

function normalizeCode(code) {
  return (code || '').trim().toUpperCase();
}

router.post('/', async (req, res, next) => {
  try {
    const userId = req.userId;
    const body = { ...req.body, uuid: req.body.uuid || uuidv4() };
    if (!body.name) {
      return res.status(400).json({ error: 'validation', message: 'name is required' });
    }
    const team = await Team.createWithCodes(body, userId);
    await TeamMember.create({
      uuid: uuidv4(),
      teamId: team.uuid,
      userId,
      coachName: req.body.coachName || 'Owner',
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
    const { code, coachName, note } = req.body;
    if (!code || !coachName) {
      return res.status(400).json({ error: 'validation', message: 'code and coachName are required' });
    }
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
        error: 'conflict',
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
      coachName: (coachName || '').trim().slice(0, 200),
      note: note ? String(note).slice(0, 500) : null,
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

router.get('/:teamId/requests', async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId } = req.params;
    const ok = await canManageTeam(teamId, userId);
    if (!ok) {
      return res.status(403).json({ error: 'forbidden', message: 'Owner only' });
    }
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

router.post('/:teamId/requests/:requestId/approve', async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, requestId } = req.params;
    const ok = await canManageTeam(teamId, userId);
    if (!ok) {
      return res.status(403).json({ error: 'forbidden', message: 'Owner only' });
    }
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

router.post('/:teamId/requests/:requestId/reject', async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, requestId } = req.params;
    const ok = await canManageTeam(teamId, userId);
    if (!ok) {
      return res.status(403).json({ error: 'forbidden', message: 'Owner only' });
    }
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

router.post('/:teamId/members/:memberId/revoke', async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, memberId } = req.params;
    const ok = await canManageTeam(teamId, userId);
    if (!ok) {
      return res.status(403).json({ error: 'forbidden', message: 'Owner only' });
    }
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

router.post('/:teamId/rotate-code', async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId } = req.params;
    const type = (req.query.type || '').toLowerCase();
    if (!['coach', 'parent'].includes(type)) {
      return res.status(400).json({ error: 'validation', message: 'query type must be coach or parent' });
    }
    const ok = await canManageTeam(teamId, userId);
    if (!ok) {
      return res.status(403).json({ error: 'forbidden', message: 'Owner only' });
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
