import { Router }        from 'express'
import { crear, listar, toggle, eliminar } from './categorias.controller'
import { authMiddleware } from '../../middlewares/auth.middleware'
import { soloAdmin }      from '../../middlewares/role.middleware'
import { validate }            from '../../middlewares/validate.middleware'
import { crearCategoriaSchema } from './categorias.schema'

const router = Router()

router.get('/',          listar)
router.post('/',         authMiddleware, soloAdmin, crear)
router.put('/:id',       authMiddleware, soloAdmin, toggle)
router.delete('/:id',    authMiddleware, soloAdmin, eliminar)
router.post('/', authMiddleware, soloAdmin, validate(crearCategoriaSchema), crear)

export default router