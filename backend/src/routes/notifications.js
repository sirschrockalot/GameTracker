const express = require('express');
const { Team } = require('../models/Team');
const { TeamMember } = require('../models/TeamMember');

const router = express.Router();

router.get('/me/notifications/summary', async (req, res, next) => {
  try {
    const userId = req.userId;
    const teams = await Team.find({ ownerUserId: userId, deletedAt: null }, { uuid: 1 }).lean();
    if (!teams || teams.length === 0) {
      return res.json({ pendingRequestsByTeam: [], totalPending: 0 });
    }
    const teamIds = teams.map((t) => t.uuid);
    const agg = await TeamMember.aggregate([
      { $match: { teamId: { $in: teamIds }, status: 'pending', deletedAt: null } },
      { $group: { _id: '$teamId', count: { $sum: 1 } } },
    ]);
    const pendingRequestsByTeam = agg.map((r) => ({ teamId: r._id, count: r.count }));
    const totalPending = pendingRequestsByTeam.reduce((sum, r) => sum + r.count, 0);
    res.json({ pendingRequestsByTeam, totalPending });
  } catch (e) {
    next(e);
  }
});

module.exports = router;

