const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');
const { generateUniqueCode } = require('../utils/codes');

const teamSchema = new mongoose.Schema(
  {
    uuid: { type: String, required: true, unique: true, default: () => uuidv4() },
    name: { type: String, required: true },
    ownerUserId: { type: String, default: null },
    inviteCode: { type: String, required: true },
    inviteCodeRotatedAt: { type: Date, default: null },
    coachCode: { type: String, required: true },
    coachCodeRotatedAt: { type: Date, default: null },
    parentCode: { type: String, required: true },
    parentCodeRotatedAt: { type: Date, default: null },
    createdAt: { type: Date, default: () => new Date() },
    updatedAt: { type: Date, default: () => new Date() },
    updatedBy: { type: String, default: null },
    deletedAt: { type: Date, default: null },
  },
  { timestamps: false }
);

teamSchema.index({ updatedAt: 1 });
teamSchema.index({ deletedAt: 1 });
teamSchema.index({ inviteCode: 1 }, { unique: true });
teamSchema.index({ coachCode: 1 }, { unique: true });
teamSchema.index({ parentCode: 1 }, { unique: true });

teamSchema.statics.createWithCodes = async function (body, userId) {
  const existing = await this.find({}, { inviteCode: 1, coachCode: 1, parentCode: 1 }).lean();
  const codes = new Set(existing.flatMap((t) => [t.inviteCode, t.coachCode, t.parentCode]));
  const now = new Date();
  const normalize = (c) => (typeof c === 'string' && c.trim()) ? c.trim().toUpperCase() : null;
  const inviteCode = normalize(body.inviteCode);
  const coachCode = normalize(body.coachCode);
  const parentCode = normalize(body.parentCode);
  const doc = {
    uuid: body.uuid || uuidv4(),
    name: body.name,
    ownerUserId: userId,
    inviteCode: inviteCode && !codes.has(inviteCode) ? inviteCode : generateUniqueCode(codes),
    coachCode: coachCode && !codes.has(coachCode) ? coachCode : generateUniqueCode(codes),
    parentCode: parentCode && !codes.has(parentCode) ? parentCode : generateUniqueCode(codes),
    createdAt: now,
    updatedAt: now,
    updatedBy: userId,
  };
  const team = await this.create(doc);
  return team;
};

const Team = mongoose.model('Team', teamSchema);
module.exports = { Team };
