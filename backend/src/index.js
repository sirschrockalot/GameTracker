require('dotenv').config();
const express = require('express');
const { connectDb } = require('./config/db');
const { authJwt } = require('./middleware/auth');
const { errorHandler } = require('./middleware/errorHandler');
const { globalLimiter } = require('./middleware/rateLimit');
const healthRouter = require('./routes/health');
const authRouter = require('./routes/auth');
const teamsRouter = require('./routes/teams');
const scheduleRouter = require('./routes/schedule');
const gamesRouter = require('./routes/games');
const syncRouter = require('./routes/sync');
const { User } = require('./models/User');
const { Team } = require('./models/Team');
const { TeamMember } = require('./models/TeamMember');
const { Player } = require('./models/Player');
const { ScheduleEvent } = require('./models/ScheduleEvent');
const { Game } = require('./models/Game');

const hasMongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
const hasJwt = !!process.env.JWT_SECRET;
if (!hasMongoUri || !hasJwt) {
  const missing = [];
  if (!hasMongoUri) missing.push('MONGODB_URI or MONGO_URI');
  if (!hasJwt) missing.push('JWT_SECRET');
  console.error('Missing required config:', missing.join(', '));
  process.exit(1);
}

const app = express();
app.set('trust proxy', 1);
app.use(express.json({ limit: '1mb' }));
app.use(globalLimiter);

app.use('/health', healthRouter);
app.use('/auth', authRouter);
app.use(authJwt);
app.use('/teams', teamsRouter);
app.use('/teams', scheduleRouter);
app.use('/teams', gamesRouter);
app.use('/sync', syncRouter);

app.use((req, res, next) => {
  res.status(404).json({ error: 'not_found', message: 'Not found' });
});
app.use(errorHandler);

const PORT = process.env.PORT || 3000;

async function start() {
  await connectDb();
  await Promise.all([
    User.syncIndexes(),
    Team.syncIndexes(),
    TeamMember.syncIndexes(),
    Player.syncIndexes(),
    ScheduleEvent.syncIndexes(),
    Game.syncIndexes(),
  ]);
  app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
  });
}

start().catch((err) => {
  console.error('Startup failed:', err);
  process.exit(1);
});
