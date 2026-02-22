'use strict';

function isString(v) {
  return typeof v === 'string';
}

function sanitizeString(str, maxLen) {
  if (str == null) return '';
  const s = String(str).replace(/[\x00-\x1F\x7F]/g, '').replace(/\s+/g, ' ').trim();
  return maxLen != null ? s.slice(0, maxLen) : s;
}

const LIMITS = {
  teamName: 60,
  displayName: { min: 2, max: 40 },
  coachName: { min: 2, max: 40 },
  note: 80,
  location: 120,
  opponent: 120,
  scheduleNotes: 300,
  playerName: 500,
};

function validateTeamName(body) {
  const name = body?.name;
  if (name != null && !isString(name)) return { error: 'validation', message: 'name must be a string' };
  const s = sanitizeString(name, LIMITS.teamName);
  if (!s) return { error: 'validation', message: 'name is required' };
  return { value: s };
}

function validateDisplayName(body) {
  const name = body?.displayName;
  if (name != null && !isString(name)) return { error: 'validation', message: 'displayName must be a string' };
  const s = sanitizeString(name);
  const { min, max } = LIMITS.displayName;
  if (s.length < min || s.length > max) return { error: 'validation', message: `displayName must be ${min}–${max} characters` };
  return { value: s };
}

function validateCoachName(raw) {
  if (raw != null && !isString(raw)) return { error: 'validation', message: 'coachName must be a string' };
  const s = sanitizeString(raw, LIMITS.coachName.max);
  if (s.length < LIMITS.coachName.min) return { error: 'validation', message: `coachName must be ${LIMITS.coachName.min}–${LIMITS.coachName.max} characters` };
  return { value: s };
}

function validateNote(raw) {
  if (raw != null && raw !== '' && !isString(raw)) return { error: 'validation', message: 'note must be a string' };
  return { value: raw == null || raw === '' ? null : sanitizeString(raw, LIMITS.note) };
}

function validateLocation(raw) {
  if (raw != null && !isString(raw)) return { error: 'validation', message: 'location must be a string' };
  return { value: raw == null ? null : sanitizeString(raw, LIMITS.location) };
}

function validateOpponent(raw) {
  if (raw != null && !isString(raw)) return { error: 'validation', message: 'opponent must be a string' };
  return { value: raw == null ? null : sanitizeString(raw, LIMITS.opponent) };
}

function validateScheduleNotes(raw) {
  if (raw != null && !isString(raw)) return { error: 'validation', message: 'notes must be a string' };
  return { value: raw == null ? null : sanitizeString(raw, LIMITS.scheduleNotes) };
}

function parseDate(v) {
  if (v == null) return null;
  if (v instanceof Date) return Number.isNaN(v.getTime()) ? null : v;
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? null : d;
}

function validateScheduleDates(startsAtVal, endsAtVal) {
  if (!startsAtVal) return { error: 'validation', message: 'startsAt is required' };
  const startsAt = parseDate(startsAtVal);
  if (!startsAt) return { error: 'validation', message: 'startsAt must be a valid date' };
  const endsAt = endsAtVal != null ? parseDate(endsAtVal) : null;
  if (endsAt != null && endsAt <= startsAt) return { error: 'validation', message: 'endsAt must be after startsAt' };
  return { value: { startsAt, endsAt } };
}

module.exports = {
  sanitizeString,
  LIMITS,
  validateTeamName,
  validateDisplayName,
  validateCoachName,
  validateNote,
  validateLocation,
  validateOpponent,
  validateScheduleNotes,
  parseDate,
  validateScheduleDates,
  isString,
};
