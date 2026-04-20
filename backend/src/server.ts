import http from 'http';
import app from './app';
import { ENV } from './config/env';
import { pool } from './config/db';
import { initSocket } from './config/socket';

process.env.TZ = 'America/Mazatlan';

const httpServer = http.createServer(app);
initSocket(httpServer);

const start = async () => {
  try {
    await pool.query('SELECT 1'); // Verifica conexión a BD
    httpServer.listen(ENV.PORT, () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${ENV.PORT}`);
      console.log(`🔌 WebSockets activos`);
    });
  } catch (error) {
    console.error('❌ No se pudo conectar a la BD:', error);
    process.exit(1);
  }
};

start();