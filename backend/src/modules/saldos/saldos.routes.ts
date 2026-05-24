import { Router }        from 'express';
import { consultar, recarga, historial, historialAdmin } from './saldos.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { validate }       from '../../middlewares/validate.middleware';
import { recargarSchema } from './saldos.schema';
import { soloAdmin }      from '../../middlewares/role.middleware';

const router = Router();

router.get('/',              authenticateToken, consultar);
router.post('/recargar',     authenticateToken, validate(recargarSchema), recarga);
router.get('/historial',     authenticateToken, historial);
router.get('/historial/admin', authenticateToken, soloAdmin, historialAdmin);

export default router;