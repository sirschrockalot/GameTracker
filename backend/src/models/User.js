const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const userSchema = new mongoose.Schema(
  {
    uuid: { type: String, required: true, unique: true, default: () => uuidv4() },
    installId: { type: String, required: true, unique: true },
    displayName: { type: String, required: true },
    createdAt: { type: Date, default: () => new Date() },
    updatedAt: { type: Date, default: () => new Date() },
    lastSeenAt: { type: Date, default: () => new Date() },
  },
  { timestamps: false }
);

const User = mongoose.model('User', userSchema);
module.exports = { User };
