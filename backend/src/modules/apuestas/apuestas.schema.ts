import { z } from 'zod';

export const crearApuestaSchema = z.object({
    titulo:             z.string().min(5).max(200),
    descripcion:        z.string().min(10),
    opciones:           z.array(z.string().min(2).max(200)).min(2),
    probabilidades:     z.array(z.number().positive()).min(2),
    monto_minimo:       z.number().min(1),
    monto_maximo:       z.number().min(1).optional(),
    fecha_finalizacion: z.string().datetime({ message: 'Formato: ISO 8601' }),
    categoria_id:       z.string().uuid().optional().nullable(),
}).refine(data => data.opciones.length === data.probabilidades.length, {
    message: 'Cada opción debe tener una probabilidad correspondiente',
}).refine(data => {
    const suma = data.probabilidades.reduce((a, b) => a + b, 0);
    return Math.abs(suma - 100) <= 0.01;
},{
    message: 'Las probabilidades deben sumar 100%',     
}).refine(data => {
    return data.probabilidades.every(p => p > 0 && p < 100);
},{
    message: 'Las probabilidades deben ser mayores a 0 y menores a 100',
});

export type CrearApuestaDTO = z.infer<typeof crearApuestaSchema>;