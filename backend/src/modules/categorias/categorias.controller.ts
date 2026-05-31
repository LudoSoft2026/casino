import { Request, Response } from 'express'
import { crearCategoria, listarCategorias, toggleCategoria, eliminarCategoria } from './categorias.service'

export const crear = async (req: Request, res: Response) => {
  const adminId = req.usuario!.id
  const { nombre, descripcion, icono } = req.body
  const result = await crearCategoria(adminId, nombre, descripcion, icono ?? 'mdi-tag')
  if (!result.p_categoria_id) {
    res.status(400).json({ mensaje: result.p_mensaje })
    return
  }
  res.status(201).json({ mensaje: result.p_mensaje, categoriaId: result.p_categoria_id })
}

export const listar = async (_req: Request, res: Response) => {
  const categorias = await listarCategorias()
  res.json({ categorias })
}

export const toggle = async (req: Request, res: Response) => {
  const adminId = req.usuario!.id
  const result  = await toggleCategoria(adminId, req.params.id)
  res.json({ mensaje: result.mensaje })
}

export const eliminar = async (req: Request, res: Response) => {
  const adminId = req.usuario!.id
  const result  = await eliminarCategoria(adminId, req.params.id)
  if (!result.ok) {
    res.status(400).json({ mensaje: result.mensaje })
    return
  }
  res.json({ mensaje: result.mensaje })
}