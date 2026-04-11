import  { Router } from 'express';
import { proponer, confirmar, pendientes } from './resultados.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { soloAdmin } from '../../middlewares/role.middleware';
import { validate } from '../../middlewares/validate.middleware';
import { ProponerResultadoDTO, ConfirmarResultadoDTO, proponerResultadoSchema, confirmarResultadoSchema } from './resultados.schema';

const router = Router();

//Creador de apuesta propone resultado
router.post('/proponer', authenticateToken, validate(proponerResultadoSchema), proponer);
//Admin confirma o rechaza resultado
router.post('/confirmar', authenticateToken, soloAdmin, validate(confirmarResultadoSchema), confirmar);
//Admin lista resultados pendientes
router.get('/pendientes', authenticateToken, soloAdmin, pendientes);

export default router;