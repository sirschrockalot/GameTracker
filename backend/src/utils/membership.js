const { Team } = require('../models/Team');
const { TeamMember } = require('../models/TeamMember');

async function getActiveTeamIds(userId) {
  const members = await TeamMember.find({
    userId,
    status: 'active',
    deletedAt: null,
  })
    .lean()
    .select('teamId');
  return [...new Set(members.map((m) => m.teamId))];
}

async function isOwner(teamId, userId) {
  const team = await Team.findOne({ uuid: teamId, deletedAt: null }).lean();
  return team && team.ownerUserId === userId;
}

async function canManageTeam(teamId, userId) {
  return isOwner(teamId, userId);
}

async function canWriteSchedule(teamId, userId) {
  const member = await TeamMember.findOne({
    teamId,
    userId,
    status: 'active',
    deletedAt: null,
  }).lean();
  if (!member) return false;
  return ['owner', 'coach'].includes(member.role);
}

module.exports = { getActiveTeamIds, isOwner, canManageTeam, canWriteSchedule };
