import { z } from 'zod'

export const crearCategoriaSchema = z.object({
  nombre:      z.string().min(1, { message: 'El nombre de la categoría es obligatorio.' }),
  descripcion: z.string().optional(),
  icono:       z.string().optional(),
})

export type CrearCategoriaDTO = z.infer<typeof crearCategoriaSchema>