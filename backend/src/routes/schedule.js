const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { ScheduleEvent } = require('../models/ScheduleEvent');
const { requireActiveMember, requireCoachOrOwner } = require('../middleware/guards');
const { validateScheduleDates, validateLocation, validateOpponent, validateScheduleNotes, isString } = require('../utils/validation');

const router = express.Router();

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

router.get('/:teamId/schedule', requireActiveMember, async (req, res, next) => {
  try {
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

router.post('/:teamId/schedule', requireCoachOrOwner, async (req, res, next) => {
  try {
    const { teamId } = req.params;
    const body = req.body || {};
    if (!body.type || !['practice', 'game'].includes(body.type)) {
      return res.status(400).json({ error: 'validation', message: 'type must be practice or game' });
    }
    const dateResult = validateScheduleDates(body.startsAt, body.endsAt);
    if (dateResult.error) return res.status(400).json(dateResult);
    const locResult = validateLocation(body.location);
    if (locResult.error) return res.status(400).json(locResult);
    const oppResult = validateOpponent(body.opponent);
    if (oppResult.error) return res.status(400).json(oppResult);
    const notesResult = validateScheduleNotes(body.notes);
    if (notesResult.error) return res.status(400).json(notesResult);
    const now = new Date();
    const event = await ScheduleEvent.create({
      uuid: typeof body.uuid === 'string' ? body.uuid : uuidv4(),
      teamId,
      type: body.type,
      startsAt: dateResult.value.startsAt,
      endsAt: dateResult.value.endsAt,
      location: locResult.value,
      opponent: oppResult.value,
      notes: notesResult.value,
      updatedAt: now,
      updatedBy: req.userId,
      schemaVersion: typeof body.schemaVersion === 'number' ? body.schemaVersion : 1,
    });
    res.status(201).json(toEventJson(event));
  } catch (e) {
    next(e);
  }
});

router.put('/:teamId/schedule/:eventId', requireCoachOrOwner, async (req, res, next) => {
  try {
    const { teamId, eventId } = req.params;
    const body = req.body || {};
    const event = await ScheduleEvent.findOne({
      uuid: eventId,
      teamId,
      deletedAt: null,
    });
    if (!event) {
      return res.status(404).json({ error: 'not_found', message: 'Event not found' });
    }
    const now = new Date();
    if (body.type != null) event.type = ['practice', 'game'].includes(body.type) ? body.type : event.type;
    if (body.startsAt != null || body.endsAt != null) {
      const dateResult = validateScheduleDates(body.startsAt ?? event.startsAt, body.endsAt ?? event.endsAt);
      if (dateResult.error) return res.status(400).json(dateResult);
      event.startsAt = dateResult.value.startsAt;
      event.endsAt = dateResult.value.endsAt;
    }
    if (body.location !== undefined) { const r = validateLocation(body.location); if (!r.error) event.location = r.value; }
    if (body.opponent !== undefined) { const r = validateOpponent(body.opponent); if (!r.error) event.opponent = r.value; }
    if (body.notes !== undefined) { const r = validateScheduleNotes(body.notes); if (!r.error) event.notes = r.value; }
    if (body.schemaVersion != null && typeof body.schemaVersion === 'number') event.schemaVersion = body.schemaVersion;
    event.updatedAt = now;
    event.updatedBy = req.userId;
    await event.save();
    res.json(toEventJson(event));
  } catch (e) {
    next(e);
  }
});

router.delete('/:teamId/schedule/:eventId', requireCoachOrOwner, async (req, res, next) => {
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
