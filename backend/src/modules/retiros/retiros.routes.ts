import { Router } from 'express';
import { solicitar, historial } from './retiros.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { validate } from '../../middlewares/validate.middleware';
import { retirarSchema } from './retiros.schema';

const router = Router();

router.post('/', authenticateToken, validate(retirarSchema), solicitar);
router.get('/historial' , authenticateToken, historial);

export default router;