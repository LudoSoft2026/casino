import { Request, Response } from 'express'
import { cambiarEstadoUsuario, listarUsuarios } from './usuarios.service'

export const listar = async (_req: Request, res: Response) => {
  const usuarios = await listarUsuarios()
  res.json({ usuarios })
}

export const cambiarEstado = async (req: Request, res: Response) => {
  const adminId   = req.usuario!.id
  const usuarioId = req.params.id
  const { accion, motivo } = req.body

  if (!accion || !motivo) {
    res.status(400).json({ mensaje: 'Se requieren acción y motivo.' })
    return
  }

  const result = await cambiarEstadoUsuario(adminId, usuarioId, accion, motivo)
  res.json({ mensaje: result.p_mensaje })
}