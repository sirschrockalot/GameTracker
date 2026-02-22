const express = require('express');
const { Team } = require('../models/Team');
const { TeamMember } = require('../models/TeamMember');
const { ScheduleEvent } = require('../models/ScheduleEvent');
const { Game } = require('../models/Game');
const { getActiveTeamIds, canWriteSchedule } = require('../utils/membership');
const { toTeamJson, toMemberJson } = require('./teams');
const { toEventJson } = require('./schedule');
const { toGameJson } = require('./games');

const router = express.Router();

function parseCompletedQuarters(jsonStr) {
  if (!jsonStr || typeof jsonStr !== 'string') return new Set();
  try {
    const arr = JSON.parse(jsonStr);
    return new Set(Array.isArray(arr) ? arr.filter((n) => Number.isInteger(n)) : []);
  } catch (_) {
    return new Set();
  }
}

function completedQuarterProtectionViolation(existingCompleted, incomingLineups) {
  const incoming = incomingLineups || {};
  for (const q of existingCompleted) {
    if (incoming[String(q)] !== undefined) return true;
  }
  return false;
}

router.get('/pull', async (req, res, next) => {
  try {
    const userId = req.userId;
    const since = req.query.since ? new Date(req.query.since) : new Date(0);
    const teamIds = await getActiveTeamIds(userId);
    const serverTime = new Date();

    const [teams, teamMembers, scheduleEvents, games] = await Promise.all([
      Team.find({ uuid: { $in: teamIds }, updatedAt: { $gt: since } }).lean(),
      TeamMember.find({ teamId: { $in: teamIds }, updatedAt: { $gt: since } }).lean(),
      ScheduleEvent.find({ teamId: { $in: teamIds }, updatedAt: { $gt: since } }).lean(),
      Game.find({ teamId: { $in: teamIds }, updatedAt: { $gt: since } }).lean(),
    ]);

    res.json({
      serverTime: serverTime.toISOString(),
      teams: teams.map(toTeamJson),
      teamMembers: teamMembers.map(toMemberJson),
      scheduleEvents: scheduleEvents.map(toEventJson),
      games: games.map(toGameJson),
    });
  } catch (e) {
    next(e);
  }
});

router.post('/push', async (req, res, next) => {
  try {
    const userId = req.userId;
    const body = req.body || {};
    const scheduleEventsUpserts = Array.isArray(body.scheduleEventsUpserts) ? body.scheduleEventsUpserts : [];
    const scheduleEventsDeletes = Array.isArray(body.scheduleEventsDeletes) ? body.scheduleEventsDeletes : [];
    const gamesUpserts = Array.isArray(body.gamesUpserts) ? body.gamesUpserts : [];
    const gamesDeletes = Array.isArray(body.gamesDeletes) ? body.gamesDeletes : [];
    const serverTime = new Date();

    for (const item of scheduleEventsUpserts) {
      const teamId = item.teamId;
      if (!teamId) continue;
      const canWrite = await canWriteSchedule(teamId, userId);
      if (!canWrite) {
        return res.status(403).json({
          error: 'forbidden',
          message: `Not allowed to write schedule for team ${teamId}`,
        });
      }
      const existing = await ScheduleEvent.findOne({
        uuid: item.uuid,
        teamId,
      });
      const payload = {
        teamId,
        type: item.type,
        startsAt: new Date(item.startsAt),
        endsAt: item.endsAt ? new Date(item.endsAt) : null,
        location: item.location ?? null,
        opponent: item.opponent ?? null,
        notes: item.notes ?? null,
        updatedAt: serverTime,
        updatedBy: userId,
        schemaVersion: item.schemaVersion ?? 1,
      };
      if (existing) {
        if (existing.deletedAt) {
          existing.deletedAt = null;
        }
        existing.type = payload.type;
        existing.startsAt = payload.startsAt;
        existing.endsAt = payload.endsAt;
        existing.location = payload.location;
        existing.opponent = payload.opponent;
        existing.notes = payload.notes;
        existing.updatedAt = serverTime;
        existing.updatedBy = userId;
        existing.schemaVersion = payload.schemaVersion;
        await existing.save();
      } else {
        await ScheduleEvent.create({
          uuid: item.uuid,
          ...payload,
        });
      }
    }

    const teamIds = await getActiveTeamIds(userId);
    for (const uuid of scheduleEventsDeletes) {
      const event = await ScheduleEvent.findOne({ uuid });
      if (!event || !teamIds.includes(event.teamId)) continue;
      const canWrite = await canWriteSchedule(event.teamId, userId);
      if (!canWrite) continue;
      event.deletedAt = serverTime;
      event.updatedAt = serverTime;
      event.updatedBy = userId;
      await event.save();
    }

    for (const item of gamesUpserts) {
      const teamId = item.teamId;
      if (!teamId) continue;
      const canWrite = await canWriteSchedule(teamId, userId);
      if (!canWrite) {
        return res.status(403).json({
          error: 'forbidden',
          message: `Not allowed to write games for team ${teamId}`,
        });
      }
      const existing = await Game.findOne({ uuid: item.uuid, teamId });
      const startedAt = item.startedAt ? new Date(item.startedAt) : serverTime;
      const quarterLineupsJson = typeof item.quarterLineupsJson === 'string' ? item.quarterLineupsJson : '{}';
      const completedQuartersJson = typeof item.completedQuartersJson === 'string' ? item.completedQuartersJson : '[]';
      const awardsJson = typeof item.awardsJson === 'string' ? item.awardsJson : '{}';
      const notes = item.notes != null ? String(item.notes).slice(0, 1000) : null;
      const schemaVersion = typeof item.schemaVersion === 'number' ? item.schemaVersion : 1;
      if (existing) {
        const existingCompleted = parseCompletedQuarters(existing.completedQuartersJson);
        let incomingLineups = {};
        try {
          incomingLineups = JSON.parse(quarterLineupsJson || '{}');
        } catch (_) {}
        if (completedQuarterProtectionViolation(existingCompleted, incomingLineups)) continue;
        existing.startedAt = Number.isNaN(startedAt.getTime()) ? existing.startedAt : startedAt;
        existing.quarterLineupsJson = quarterLineupsJson;
        existing.completedQuartersJson = completedQuartersJson;
        existing.awardsJson = awardsJson;
        existing.notes = notes;
        existing.schemaVersion = schemaVersion;
        existing.updatedAt = serverTime;
        existing.updatedBy = userId;
        await existing.save();
      } else {
        await Game.create({
          uuid: item.uuid,
          teamId,
          startedAt: Number.isNaN(startedAt.getTime()) ? serverTime : startedAt,
          quarterLineupsJson,
          completedQuartersJson,
          awardsJson,
          notes,
          schemaVersion,
          createdAt: serverTime,
          updatedAt: serverTime,
          updatedBy: userId,
          deletedAt: null,
        });
      }
    }

    for (const uuid of gamesDeletes) {
      const game = await Game.findOne({ uuid });
      if (!game || !teamIds.includes(game.teamId)) continue;
      const canWrite = await canWriteSchedule(game.teamId, userId);
      if (!canWrite) continue;
      game.deletedAt = serverTime;
      game.updatedAt = serverTime;
      game.updatedBy = userId;
      await game.save();
    }

    res.json({ ok: true, serverTime: serverTime.toISOString() });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
