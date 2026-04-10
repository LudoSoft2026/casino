import express from 'express';
import cors from 'cors';

const app = express();

app.use(cors());
app.use(express.json());

// Ruta de prueba
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', message: 'Servidor funcionando' });
});

export default app;