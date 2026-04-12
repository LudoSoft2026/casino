import { z } from 'zod';

export const retirarSchema = z.object({
    monto_solicitado: z.number().positive({ message: 'El monto debe ser mayor a 0' }),
    metodo_retiro: z.string().min(1, { message: 'el metodo es requerido'}),
});

export type RetirarDTO = z.infer<typeof retirarSchema>;