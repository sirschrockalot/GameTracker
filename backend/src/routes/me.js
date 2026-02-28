const express = require('express');
const { TeamMember } = require('../models/TeamMember');
const { toMemberJson } = require('./teams');

const router = express.Router();

/** GET /me/memberships — all memberships for the caller (including revoked/rejected). Lets client detect revokes. */
router.get('/memberships', async (req, res, next) => {
  try {
    const userId = req.userId;
    const list = await TeamMember.find({ userId })
      .sort({ updatedAt: -1 })
      .lean();
    res.json(list.map(toMemberJson));
  } catch (e) {
    next(e);
  }
});

module.exports = router;
