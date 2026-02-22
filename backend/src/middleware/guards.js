'use strict';

const { getActiveTeamIds, canBootstrapTeam, canWriteSchedule } = require('../utils/membership');

async function requireActiveMember(req, res, next) {
  const teamId = req.params.teamId;
  if (!teamId) return res.status(400).json({ error: 'validation', message: 'teamId required' });
  const userId = req.userId;
  const teamIds = await getActiveTeamIds(userId);
  if (!teamIds.includes(teamId)) {
    return res.status(403).json({ error: 'forbidden', message: 'Not a member of this team' });
  }
  next();
}

async function requireOwner(req, res, next) {
  const teamId = req.params.teamId;
  if (!teamId) return res.status(400).json({ error: 'validation', message: 'teamId required' });
  const userId = req.userId;
  const ok = await canBootstrapTeam(teamId, userId);
  if (!ok) {
    return res.status(403).json({ error: 'forbidden', message: 'Owner only' });
  }
  next();
}

async function requireCoachOrOwner(req, res, next) {
  const teamId = req.params.teamId;
  if (!teamId) return res.status(400).json({ error: 'validation', message: 'teamId required' });
  const userId = req.userId;
  const teamIds = await getActiveTeamIds(userId);
  if (!teamIds.includes(teamId)) {
    return res.status(403).json({ error: 'forbidden', message: 'Not a member of this team' });
  }
  const canWrite = await canWriteSchedule(teamId, userId);
  if (!canWrite) {
    return res.status(403).json({ error: 'forbidden', message: 'Coach or owner only' });
  }
  next();
}

module.exports = { requireActiveMember, requireOwner, requireCoachOrOwner };
