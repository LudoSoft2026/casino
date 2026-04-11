import { z } from 'zod';

export const participacionSchema = z.object({
    apuesta_id: z.string().uuid({ message: 'ID de apuesta invalido' }),
    opcion_id: z.string().uuid({ message: 'ID de opción invalido' }),
    monto: z.number().positive({ message: 'El monto debe ser un número mayor a 0' }),
});

export type ParticiparDTO = z.infer<typeof participacionSchema>;