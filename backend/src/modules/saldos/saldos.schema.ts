import { z } from 'zod';

export const recargarSchema = z.object({
    monto: z.number().positive({ message: 'El monto debe ser mayor a 0' }),
    metodo: z.string().min(1, { message: 'El metodo es requerido'}),
});

export type RecargarSaldoDTO = z.infer<typeof recargarSchema>;