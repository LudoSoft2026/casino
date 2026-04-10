import { Pool } from 'pg';
import { ENV } from './env';

export const pool = new Pool({
  host:     ENV.DB_HOST,
  port:     ENV.DB_PORT,
  database: ENV.DB_NAME,
  user:     ENV.DB_USER,
  password: ENV.DB_PASSWORD,
});

pool.on('connect', () => {
  console.log('✅ Conectado a PostgreSQL');
});

pool.on('error', (err) => {
  console.error('❌ Error en PostgreSQL:', err.message);
});