const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { User } = require('../models/User');
const { registerLimiter } = require('../middleware/rateLimit');
const { validateDisplayName } = require('../utils/validation');

const router = express.Router();

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const JWT_EXPIRY = '180d';

router.post('/register', registerLimiter, async (req, res, next) => {
  try {
    const installId = req.body?.installId;
    if (!installId || typeof installId !== 'string' || !UUID_REGEX.test(installId.trim())) {
      return res.status(400).json({ error: 'validation', message: 'installId must be a valid UUID string' });
    }
    const nameResult = validateDisplayName(req.body);
    if (nameResult.error) return res.status(400).json(nameResult);
    const name = nameResult.value;
    const now = new Date();
    let user = await User.findOne({ installId: installId.trim() });
    if (user) {
      user.displayName = name;
      user.updatedAt = now;
      user.lastSeenAt = now;
      await user.save();
    } else {
      user = await User.create({
        uuid: uuidv4(),
        installId: installId.trim(),
        displayName: name,
        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
      });
    }
    const token = jwt.sign(
      { sub: user.uuid, displayName: user.displayName },
      process.env.JWT_SECRET,
      { expiresIn: JWT_EXPIRY }
    );
    res.status(200).json({
      token,
      userId: user.uuid,
      displayName: user.displayName,
    });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
