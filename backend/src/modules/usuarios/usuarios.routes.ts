import { Router }        from 'express'
import { listar, cambiarEstado } from './usuarios.controller'
import { authenticateToken } from '../../middlewares/auth.middleware'
import { soloAdmin }      from '../../middlewares/role.middleware'

const router = Router()

router.get('/',        authenticateToken, soloAdmin, listar)
router.put('/:id/estado', authenticateToken, soloAdmin, cambiarEstado)

export default router