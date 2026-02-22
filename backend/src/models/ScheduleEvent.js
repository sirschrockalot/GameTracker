const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const scheduleEventSchema = new mongoose.Schema(
  {
    uuid: { type: String, required: true, unique: true, default: () => uuidv4() },
    teamId: { type: String, required: true },
    type: { type: String, required: true, enum: ['practice', 'game'] },
    startsAt: { type: Date, required: true },
    endsAt: { type: Date, default: null },
    location: { type: String, default: null },
    opponent: { type: String, default: null },
    notes: { type: String, default: null },
    updatedAt: { type: Date, default: () => new Date() },
    updatedBy: { type: String, default: null },
    deletedAt: { type: Date, default: null },
    schemaVersion: { type: Number, default: 1 },
  },
  { timestamps: false }
);

scheduleEventSchema.index({ teamId: 1, updatedAt: 1 });
scheduleEventSchema.index({ teamId: 1, deletedAt: 1 });

const ScheduleEvent = mongoose.model('ScheduleEvent', scheduleEventSchema);
module.exports = { ScheduleEvent };
