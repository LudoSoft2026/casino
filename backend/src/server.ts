import app from './app';
import { ENV } from './config/env';
import { pool } from './config/db';

const start = async () => {
  try {
    await pool.query('SELECT 1'); // Verifica conexión a BD
    app.listen(ENV.PORT, () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${ENV.PORT}`);
    });
  } catch (error) {
    console.error('❌ No se pudo conectar a la BD:', error);
    process.exit(1);
  }
};

start();