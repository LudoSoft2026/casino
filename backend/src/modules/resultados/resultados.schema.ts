import { z } from 'zod';

export const proponerResultadoSchema = z.object({
    apuesta_id: z.string().uuid({ message: 'ID de apuesta invalido' }),
    opcion_ganadora_id: z.string().uuid({ message: 'ID de opciion invalido' }),
});

export const confirmarResultadoSchema = z.object({
    resultado_id: z.string().uuid({ message: 'ID de resultado invalido' }),
    aprobar: z.boolean(),
    motivo_rechazo: z.string().optional(),
});

export type ProponerResultadoDTO = z.infer<typeof proponerResultadoSchema>;
export type ConfirmarResultadoDTO = z.infer<typeof confirmarResultadoSchema>;
