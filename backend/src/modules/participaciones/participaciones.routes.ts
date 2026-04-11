import { Router } from "express";
import { realizarApuesta, historial, porApuesta } from "./participaciones.controller";
import { authenticateToken } from "../../middlewares/auth.middleware";
import { validate } from "../../middlewares/validate.middleware";
import { participacionSchema } from "./participaciones.schema";

const router = Router();

// Protegidas
router.post('/', authenticateToken, validate(participacionSchema), realizarApuesta);
router.get("/historial",            authenticateToken, historial);
router.get("/apuesta/:apuestaId",   authenticateToken, porApuesta);

export default router;