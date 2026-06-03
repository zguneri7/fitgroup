import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import measurementRoutes from './routes/measurements.js';
import groupRoutes from './routes/groups.js';
import { healthCheckDb, ensureGroupTables, ensureMeasurementTables, ensureUserProfileColumns } from './db.js';
import { requireAuth } from './auth_middleware.js';

dotenv.config();

const app = express();
const port = Number(process.env.API_PORT ?? 3000);

app.use(cors());
app.use(express.json());

app.get('/health', async (_req, res) => {
  try {
    const dbOk = await healthCheckDb();
    return res.json({ status: 'ok', db: dbOk ? 'up' : 'down' });
  } catch (_error) {
    return res.status(500).json({ status: 'error', db: 'down' });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/measurements', requireAuth, measurementRoutes);
app.use('/api/groups', requireAuth, groupRoutes);

app.use((error, _req, res, _next) => {
  console.error(error);
  return res.status(500).json({ message: 'internal server error' });
});

async function startServer() {
  await ensureUserProfileColumns();
  await ensureMeasurementTables();
  await ensureGroupTables();

  app.listen(port, () => {
    console.log(`FitGroup backend listening on http://localhost:${port}`);
  });
}

startServer().catch((error) => {
  console.error(error);
  process.exit(1);
});
