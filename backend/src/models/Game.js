const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const gameSchema = new mongoose.Schema(
  {
    uuid: { type: String, required: true, unique: true, default: () => uuidv4() },
    teamId: { type: String, required: true },
    startedAt: { type: Date, required: true },
    quarterLineupsJson: { type: String, default: '{}' },
    completedQuartersJson: { type: String, default: '[]' },
    awardsJson: { type: String, default: '{}' },
    notes: { type: String, default: null },
    schemaVersion: { type: Number, default: 1 },
    createdAt: { type: Date, default: () => new Date() },
    updatedAt: { type: Date, default: () => new Date() },
    updatedBy: { type: String, default: null },
    deletedAt: { type: Date, default: null },
  },
  { timestamps: false }
);

gameSchema.index({ uuid: 1 }, { unique: true });
gameSchema.index({ teamId: 1, updatedAt: 1 });
gameSchema.index({ teamId: 1, startedAt: -1 });

const Game = mongoose.model('Game', gameSchema);
module.exports = { Game };
