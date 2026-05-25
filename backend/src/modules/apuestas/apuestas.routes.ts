import { Router } from 'express';
import { apuestasCerradas, crear, listar, misApuestas, obtener, preview, todasConParticipantes, declararGanador, eliminar } from './apuestas.controller';
import { authenticateToken  } from '../../middlewares/auth.middleware';
import { validate } from '../../middlewares/validate.middleware';
import { crearApuestaSchema } from './apuestas.schema';
import { soloAdmin } from '../../middlewares/role.middleware';

const router = Router();

// Públicas
router.get('/',                          listar);
router.get('/preview',                   preview);
router.get('/mis-apuestas',              authenticateToken, misApuestas);
router.get('/admin/cerradas',            authenticateToken, soloAdmin, apuestasCerradas);
router.get('/admin/todas',               authenticateToken, soloAdmin, todasConParticipantes);
router.post('/admin/declarar-ganador',   authenticateToken, soloAdmin, declararGanador);
router.get('/:id',                       obtener);

// Protegidas
router.post('/',                         authenticateToken, validate(crearApuestaSchema), crear);
router.delete('/:id',                    authenticateToken, eliminar);

export default router;