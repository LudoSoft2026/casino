import { Router } from "express";
import { realizarApuesta, historial, porApuesta, todasParticipaciones } from "./participaciones.controller";
import { authenticateToken } from "../../middlewares/auth.middleware";
import { validate } from "../../middlewares/validate.middleware";
import { participacionSchema } from "./participaciones.schema";
import { soloAdmin } from '../../middlewares/role.middleware';

const router = Router();

// Protegidas
router.post('/', authenticateToken, validate(participacionSchema), realizarApuesta);
router.get("/historial",            authenticateToken, historial);
router.get("/apuesta/:apuestaId",   authenticateToken, porApuesta);
router.get('/admin/todas', authenticateToken, soloAdmin, todasParticipaciones);

export default router;