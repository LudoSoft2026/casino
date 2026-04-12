import { Router } from 'express';
import { consultar, recarga } from './saldos.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { validate } from '../../middlewares/validate.middleware';
import { recargarSchema } from './saldos.schema';

const router = Router();

router.get('/', authenticateToken, consultar);
router.post('/recargar', authenticateToken, validate(recargarSchema), recarga);

export default router;