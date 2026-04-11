import express from 'express';
import cors from 'cors';
import authRoutes from './modules/auth/auth.routes';
import apuestasRoutes from './modules/apuestas/apuestas.routes';
import participacionesRoutes from './modules/participaciones/participaciones.routes';
import { errorMiddleware } from './middlewares/error.middleware';

const app = express();

app.use(cors());
app.use(express.json());

// Rutas
app.use('/api/participaciones', participacionesRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/apuestas', apuestasRoutes);

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', message: 'Servidor funcionando' });
});

/*
app.get('/api/protegida', authenticateToken, (_req, res) => {
  res.json({ message: 'Esta es una ruta protegida' });
});
*/

// Middleware de manejo de errores
app.use(errorMiddleware);


export default app;