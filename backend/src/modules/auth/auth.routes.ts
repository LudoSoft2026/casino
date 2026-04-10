import { Router } from 'express';
import { registro, login } from './auth.controller';
import { validate } from '../../middlewares/validate.middleware';
import { registroSchema, loginSchema } from './auth.schema';

const router = Router();

router.post('/registro', validate(registroSchema), registro);
router.post('/login', validate(loginSchema), login);

export default router;