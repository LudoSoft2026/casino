import { Router }        from 'express'
import { rankingSemanal } from './ranking.controller'

const router = Router()

router.get('/', rankingSemanal)

export default router