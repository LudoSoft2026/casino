import { Router }        from 'express'
import { crear, listar, toggle, eliminar } from './categorias.controller'
import { authenticateToken } from '../../middlewares/auth.middleware'
import { soloAdmin }      from '../../middlewares/role.middleware'
import { validate }            from '../../middlewares/validate.middleware'
import { crearCategoriaSchema } from './categorias.schema'

const router = Router()

router.get('/',          listar)
router.post('/',         authenticateToken, soloAdmin, validate(crearCategoriaSchema), crear)
router.put('/:id',       authenticateToken, soloAdmin, toggle)
router.delete('/:id',    authenticateToken, soloAdmin, eliminar)
router.post('/', authenticateToken, soloAdmin, validate(crearCategoriaSchema), crear)

export default router