import { Router } from 'express';
import { crear, listar, obtener, preview } from './apuestas.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { validate } from '../../middlewares/validate.middleware';
import { crearApuestaSchema } from './apuestas.schema';

const router = Router();

//Publicas
router.get('/', listar);
router.get('/:id', obtener);
router.get('/preview', preview);

//Protegidas
router.post('/', authenticateToken, validate(crearApuestaSchema), crear);

export default router;