import { z } from 'zod';

export const registroSchema = z.object({
    nombre:                 z.string().min(2).max(100),
    apellido_paterno:       z.string().min(2).max(100),
    apellido_materno:       z.string().max(100).optional(),
    fecha_nacimiento:       z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Formato: YYYY-MM-DD"),
    telefono:               z.string().min(10).max(20),
    alias:                  z.string().min(3).max(50),
    correo:                 z.string().email(),
    password:               z.string().min(8).max(100)
});

export const loginSchema =  z.object({
    correo:                 z.string().email(),
    password:               z.string().min(1),
});

export type RegistroDTO =   z.infer<typeof registroSchema>;
export type LoginDTO =      z.infer<typeof loginSchema>;