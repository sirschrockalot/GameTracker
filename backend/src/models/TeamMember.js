const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const teamMemberSchema = new mongoose.Schema(
  {
    uuid: { type: String, required: true, unique: true, default: () => uuidv4() },
    teamId: { type: String, required: true },
    userId: { type: String, required: true },
    coachName: { type: String, required: true },
    note: { type: String, default: null },
    role: { type: String, required: true, enum: ['owner', 'coach', 'parent'] },
    status: { type: String, required: true, enum: ['pending', 'active', 'rejected', 'revoked'], default: 'pending' },
    requestedAt: { type: Date, default: () => new Date() },
    approvedAt: { type: Date, default: null },
    approvedByUserId: { type: String, default: null },
    updatedAt: { type: Date, default: () => new Date() },
    updatedBy: { type: String, default: null },
    deletedAt: { type: Date, default: null },
  },
  { timestamps: false }
);

teamMemberSchema.index({ teamId: 1, status: 1 });
teamMemberSchema.index({ userId: 1, status: 1 });
teamMemberSchema.index({ teamId: 1, updatedAt: 1 });
teamMemberSchema.index(
  { teamId: 1, userId: 1 },
  { unique: true, partialFilterExpression: { status: 'pending', deletedAt: null } }
);

const TeamMember = mongoose.model('TeamMember', teamMemberSchema);
module.exports = { TeamMember };
