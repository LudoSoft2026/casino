import { z } from 'zod';

export const subirDocumentoSchema = z.object({
    numero_documento: z.string().min(5).max(50),
    tipo_documento: z.enum(['INE', 'Pasaporte', 'Cedula', 'Otro']),
});

export const revisarDocumentoSchema = z.object({
    documento_id: z.string().uuid(),
    aprobar: z.boolean(),
    motivo_rechazo: z.string().optional(),
});

export type SubirDocumentoDTO = z.infer<typeof subirDocumentoSchema>;
export type RevisarDocumentoDTO = z.infer<typeof revisarDocumentoSchema>;