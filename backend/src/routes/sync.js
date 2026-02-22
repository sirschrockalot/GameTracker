const express = require('express');
const { Team } = require('../models/Team');
const { TeamMember } = require('../models/TeamMember');
const { ScheduleEvent } = require('../models/ScheduleEvent');
const { getActiveTeamIds, canWriteSchedule } = require('../utils/membership');
const { toTeamJson, toMemberJson } = require('./teams');
const { toEventJson } = require('./schedule');

const router = express.Router();

router.get('/pull', async (req, res, next) => {
  try {
    const userId = req.userId;
    const since = req.query.since ? new Date(req.query.since) : new Date(0);
    const teamIds = await getActiveTeamIds(userId);
    const serverTime = new Date();

    const [teams, teamMembers, scheduleEvents] = await Promise.all([
      Team.find({ uuid: { $in: teamIds }, updatedAt: { $gt: since } }).lean(),
      TeamMember.find({ teamId: { $in: teamIds }, updatedAt: { $gt: since } }).lean(),
      ScheduleEvent.find({ teamId: { $in: teamIds }, updatedAt: { $gt: since } }).lean(),
    ]);

    res.json({
      serverTime: serverTime.toISOString(),
      teams: teams.map(toTeamJson),
      teamMembers: teamMembers.map(toMemberJson),
      scheduleEvents: scheduleEvents.map(toEventJson),
    });
  } catch (e) {
    next(e);
  }
});

router.post('/push', async (req, res, next) => {
  try {
    const userId = req.userId;
    const { scheduleEventsUpserts = [], scheduleEventsDeletes = [] } = req.body;
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

    res.json({ ok: true, serverTime: serverTime.toISOString() });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
