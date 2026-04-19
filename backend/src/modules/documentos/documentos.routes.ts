import { Router } from "express";
import { subir, revisar, pendientes, miDocumento } from "./documentos.controller";
import { authenticateToken } from "../../middlewares/auth.middleware";
import { soloAdmin } from "../../middlewares/role.middleware";
import { upload } from '../../config/uploads/multer';

const router = Router();

//Usuario sube documento
router.post('/', authenticateToken, upload.single('documento'), subir);

//Usuario consulta su documento
router.get('/mi-documento', authenticateToken, miDocumento);

//admin lista pendientes
router.get('/pendientes', authenticateToken, soloAdmin, pendientes);

//admin aprueba o rechaza documento
router.post('/revisar', authenticateToken, soloAdmin, revisar);

export default router;