const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { ScheduleEvent } = require('../models/ScheduleEvent');
const { canWriteSchedule } = require('../utils/membership');
const { getActiveTeamIds } = require('../utils/membership');

const router = express.Router();

async function requireScheduleWrite(req, res, next) {
  const { teamId } = req.params;
  const allowed = await getActiveTeamIds(req.userId);
  if (!allowed.includes(teamId)) {
    return res.status(403).json({ error: 'forbidden', message: 'Not a member of this team' });
  }
  const canWrite = await canWriteSchedule(teamId, req.userId);
  if (!canWrite) {
    return res.status(403).json({ error: 'forbidden', message: 'Coach or owner only' });
  }
  next();
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

router.get('/:teamId/schedule', async (req, res, next) => {
  try {
    const teamIds = await getActiveTeamIds(req.userId);
    if (!teamIds.includes(req.params.teamId)) {
      return res.status(403).json({ error: 'forbidden', message: 'Not a member of this team' });
    }
    const list = await ScheduleEvent.find({
      teamId: req.params.teamId,
      deletedAt: null,
    })
      .sort({ startsAt: 1 })
      .lean();
    res.json(list.map(toEventJson));
  } catch (e) {
    next(e);
  }
});

router.post('/:teamId/schedule', requireScheduleWrite, async (req, res, next) => {
  try {
    const { teamId } = req.params;
    const body = req.body;
    if (!body.type || !body.startsAt) {
      return res.status(400).json({ error: 'validation', message: 'type and startsAt are required' });
    }
    const now = new Date();
    const event = await ScheduleEvent.create({
      uuid: body.uuid || uuidv4(),
      teamId,
      type: body.type,
      startsAt: new Date(body.startsAt),
      endsAt: body.endsAt ? new Date(body.endsAt) : null,
      location: body.location || null,
      opponent: body.opponent || null,
      notes: body.notes || null,
      updatedAt: now,
      updatedBy: req.userId,
      schemaVersion: body.schemaVersion ?? 1,
    });
    res.status(201).json(toEventJson(event));
  } catch (e) {
    next(e);
  }
});

router.put('/:teamId/schedule/:eventId', requireScheduleWrite, async (req, res, next) => {
  try {
    const { teamId, eventId } = req.params;
    const body = req.body;
    const event = await ScheduleEvent.findOne({
      uuid: eventId,
      teamId,
      deletedAt: null,
    });
    if (!event) {
      return res.status(404).json({ error: 'not_found', message: 'Event not found' });
    }
    const now = new Date();
    if (body.type != null) event.type = body.type;
    if (body.startsAt != null) event.startsAt = new Date(body.startsAt);
    if (body.endsAt != null) event.endsAt = body.endsAt ? new Date(body.endsAt) : null;
    if (body.location !== undefined) event.location = body.location;
    if (body.opponent !== undefined) event.opponent = body.opponent;
    if (body.notes !== undefined) event.notes = body.notes;
    if (body.schemaVersion != null) event.schemaVersion = body.schemaVersion;
    event.updatedAt = now;
    event.updatedBy = req.userId;
    await event.save();
    res.json(toEventJson(event));
  } catch (e) {
    next(e);
  }
});

router.delete('/:teamId/schedule/:eventId', requireScheduleWrite, async (req, res, next) => {
  try {
    const { teamId, eventId } = req.params;
    const event = await ScheduleEvent.findOne({
      uuid: eventId,
      teamId,
      deletedAt: null,
    });
    if (!event) {
      return res.status(404).json({ error: 'not_found', message: 'Event not found' });
    }
    const now = new Date();
    event.deletedAt = now;
    event.updatedAt = now;
    event.updatedBy = req.userId;
    await event.save();
    res.json(toEventJson(event));
  } catch (e) {
    next(e);
  }
});

module.exports = router;
module.exports.toEventJson = toEventJson;
