const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const playerSchema = new mongoose.Schema(
  {
    uuid: { type: String, required: true, unique: true, default: () => uuidv4() },
    teamId: { type: String, required: true },
    name: { type: String, required: true },
    skill: { type: String, required: true, enum: ['strong', 'developing'], default: 'developing' },
    createdAt: { type: Date, default: () => new Date() },
    updatedAt: { type: Date, default: () => new Date() },
    updatedBy: { type: String, default: null },
    deletedAt: { type: Date, default: null },
    schemaVersion: { type: Number, default: 1 },
  },
  { timestamps: false }
);

playerSchema.index({ teamId: 1, updatedAt: 1 });

const Player = mongoose.model('Player', playerSchema);
module.exports = { Player };
