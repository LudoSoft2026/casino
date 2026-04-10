import express from 'express';
import cors from 'cors';
import authRoutes from './modules/auth/auth.routes';
import { errorMiddleware } from './middlewares/error.middleware';
//Prueba
//import { authenticateToken as authMiddleware } from './middlewares/auth.middleware';

const app = express();

app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);

// Ruta de prueba
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', message: 'Servidor funcionando' });
});
/*
app.get('/api/protegida', authMiddleware, (_req, res) => {
  res.json({ message: 'Esta es una ruta protegida' });
});
*/
// Middleware de manejo de errores
app.use(errorMiddleware);


export default app;