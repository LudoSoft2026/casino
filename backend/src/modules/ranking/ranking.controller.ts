import { Request, Response } from 'express'
import { obtenerRankingSemanal } from './ranking.service'

export const rankingSemanal = async (_req: Request, res: Response) => {
  const ranking = await obtenerRankingSemanal()
  res.json({ ranking })
}