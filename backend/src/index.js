require('dotenv').config();
const express = require('express');
const { connectDb } = require('./config/db');
const { initFirebase } = require('./config/firebase');
const { authMiddleware } = require('./middleware/auth');
const { errorHandler } = require('./middleware/errorHandler');
const healthRouter = require('./routes/health');
const teamsRouter = require('./routes/teams');
const scheduleRouter = require('./routes/schedule');
const syncRouter = require('./routes/sync');

const app = express();
app.use(express.json({ limit: '1mb' }));

app.use('/health', healthRouter);
app.use(authMiddleware);
app.use('/teams', teamsRouter);
app.use('/teams', scheduleRouter);
app.use('/sync', syncRouter);

app.use((req, res, next) => {
  res.status(404).json({ error: 'not_found', message: 'Not found' });
});
app.use(errorHandler);

const PORT = process.env.PORT || 3000;

async function start() {
  await connectDb();
  await initFirebase();
  app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
  });
}

start().catch((err) => {
  console.error('Startup failed:', err);
  process.exit(1);
});
