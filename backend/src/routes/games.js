'use strict';

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { Game } = require('../models/Game');
const { requireActiveMember, requireCoachOrOwner } = require('../middleware/guards');

const router = express.Router();

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;

function toGameJson(doc) {
  const d = doc && doc.toObject ? doc.toObject() : doc;
  if (!d) return null;
  return {
    uuid: d.uuid,
    teamId: d.teamId,
    startedAt: d.startedAt?.toISOString?.() ?? d.startedAt,
    quarterLineupsJson: d.quarterLineupsJson ?? '{}',
    completedQuartersJson: d.completedQuartersJson ?? '[]',
    awardsJson: d.awardsJson ?? '{}',
    notes: d.notes ?? null,
    schemaVersion: d.schemaVersion ?? 1,
    createdAt: d.createdAt?.toISOString?.() ?? d.createdAt,
    updatedAt: d.updatedAt?.toISOString?.() ?? d.updatedAt,
    updatedBy: d.updatedBy ?? null,
    deletedAt: d.deletedAt?.toISOString?.() ?? d.deletedAt ?? null,
  };
}

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

router.get('/:teamId/games', requireActiveMember, async (req, res, next) => {
  try {
    const { teamId } = req.params;
    const limit = Math.min(
      Math.max(1, parseInt(req.query.limit, 10) || DEFAULT_LIMIT),
      MAX_LIMIT
    );
    const before = req.query.before ? new Date(req.query.before) : null;
    const includeDeleted = req.query.includeDeleted === 'true';

    const filter = { teamId };
    if (!includeDeleted) filter.deletedAt = null;
    if (before && !Number.isNaN(before.getTime())) filter.startedAt = { $lt: before };

    const list = await Game.find(filter)
      .sort({ startedAt: -1 })
      .limit(limit)
      .lean();
    res.json(list.map(toGameJson));
  } catch (e) {
    next(e);
  }
});

router.get('/:teamId/games/:gameId', requireActiveMember, async (req, res, next) => {
  try {
    const { teamId, gameId } = req.params;
    const game = await Game.findOne({ uuid: gameId, teamId }).lean();
    if (!game) {
      return res.status(404).json({ error: 'not_found', message: 'Game not found' });
    }
    res.json(toGameJson(game));
  } catch (e) {
    next(e);
  }
});

router.post('/:teamId/games', requireCoachOrOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId } = req.params;
    const body = req.body || {};
    const now = new Date();
    const uuid = typeof body.uuid === 'string' ? body.uuid : uuidv4();
    const startedAt = body.startedAt ? new Date(body.startedAt) : now;
    if (Number.isNaN(startedAt.getTime())) {
      return res.status(400).json({ error: 'validation', message: 'startedAt must be a valid date' });
    }

    const existing = await Game.findOne({ uuid, teamId });
    const quarterLineupsJson = typeof body.quarterLineupsJson === 'string' ? body.quarterLineupsJson : '{}';
    const completedQuartersJson = typeof body.completedQuartersJson === 'string' ? body.completedQuartersJson : '[]';
    const awardsJson = typeof body.awardsJson === 'string' ? body.awardsJson : '{}';
    const notes = body.notes != null ? String(body.notes).slice(0, 1000) : null;
    const schemaVersion = typeof body.schemaVersion === 'number' ? body.schemaVersion : 1;

    if (existing) {
      const existingCompleted = parseCompletedQuarters(existing.completedQuartersJson);
      let incomingLineups = {};
      try {
        incomingLineups = JSON.parse(quarterLineupsJson || '{}');
      } catch (_) {}
      if (completedQuarterProtectionViolation(existingCompleted, incomingLineups)) {
        return res.status(400).json({
          error: 'validation',
          message: 'Cannot change lineup for a completed quarter',
        });
      }
      existing.startedAt = startedAt;
      existing.quarterLineupsJson = quarterLineupsJson;
      existing.completedQuartersJson = completedQuartersJson;
      existing.awardsJson = awardsJson;
      existing.notes = notes;
      existing.schemaVersion = schemaVersion;
      existing.updatedAt = now;
      existing.updatedBy = userId;
      await existing.save();
      return res.json(toGameJson(existing));
    }

    const created = await Game.create({
      uuid,
      teamId,
      startedAt,
      quarterLineupsJson,
      completedQuartersJson,
      awardsJson,
      notes,
      schemaVersion,
      createdAt: now,
      updatedAt: now,
      updatedBy: userId,
      deletedAt: null,
    });
    res.status(201).json(toGameJson(created));
  } catch (e) {
    next(e);
  }
});

router.put('/:teamId/games/:gameId', requireCoachOrOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, gameId } = req.params;
    const body = req.body || {};
    const game = await Game.findOne({ uuid: gameId, teamId });
    if (!game) {
      return res.status(404).json({ error: 'not_found', message: 'Game not found' });
    }
    const existingCompleted = parseCompletedQuarters(game.completedQuartersJson);
    if (body.quarterLineupsJson !== undefined) {
      let incoming = {};
      try {
        incoming = JSON.parse(typeof body.quarterLineupsJson === 'string' ? body.quarterLineupsJson : '{}');
      } catch (_) {}
      if (completedQuarterProtectionViolation(existingCompleted, incoming)) {
        return res.status(400).json({
          error: 'validation',
          message: 'Cannot change lineup for a completed quarter',
        });
      }
      game.quarterLineupsJson = typeof body.quarterLineupsJson === 'string' ? body.quarterLineupsJson : game.quarterLineupsJson;
    }
    if (body.completedQuartersJson !== undefined) {
      game.completedQuartersJson = typeof body.completedQuartersJson === 'string' ? body.completedQuartersJson : game.completedQuartersJson;
    }
    if (body.startedAt != null) {
      const d = new Date(body.startedAt);
      if (!Number.isNaN(d.getTime())) game.startedAt = d;
    }
    if (body.awardsJson !== undefined) game.awardsJson = typeof body.awardsJson === 'string' ? body.awardsJson : game.awardsJson;
    if (body.notes !== undefined) game.notes = body.notes == null ? null : String(body.notes).slice(0, 1000);
    if (body.schemaVersion != null && typeof body.schemaVersion === 'number') game.schemaVersion = body.schemaVersion;
    const now = new Date();
    game.updatedAt = now;
    game.updatedBy = userId;
    await game.save();
    res.json(toGameJson(game));
  } catch (e) {
    next(e);
  }
});

router.delete('/:teamId/games/:gameId', requireCoachOrOwner, async (req, res, next) => {
  try {
    const userId = req.userId;
    const { teamId, gameId } = req.params;
    const game = await Game.findOne({ uuid: gameId, teamId });
    if (!game) {
      return res.status(404).json({ error: 'not_found', message: 'Game not found' });
    }
    const now = new Date();
    game.deletedAt = now;
    game.updatedAt = now;
    game.updatedBy = userId;
    await game.save();
    res.json(toGameJson(game));
  } catch (e) {
    next(e);
  }
});

module.exports = router;
module.exports.toGameJson = toGameJson;
