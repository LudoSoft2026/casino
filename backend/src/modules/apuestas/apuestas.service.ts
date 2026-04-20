import { pool } from '../../config/db';
import { CrearApuestaDTO } from './apuestas.schema';

export const crearApuesta = async (creadorId: string, data: CrearApuestaDTO) => {
    const { rows } = await pool.query(
        `CALL SP_CREAR_APUESTA($1, $2, $3, $4, $5, $6, $7,NULL, NULL, $8)`,
        [
            creadorId,
            data.titulo,
            data.descripcion,
            data.opciones,
            data.probabilidades,
            data.monto_minimo,
            data.fecha_finalizacion,
            data.monto_maximo || null,
        ]
    );
    return rows[0] as { p_apuesta_id: string | null; p_mensaje: String};
};

export const listarApuestas = async () => {
      console.log('⏰ Hora del servidor:', new Date());
    const { rows } = await pool.query(`SELECT * FROM V_APUESTAS_ACTIVAS ORDER BY es_tendencia DESC, fecha_creacion DESC`);
    return rows;
};

export const obtenerApuesta = async (id: string) => {
    const { rows } = await pool.query(
        `SELECT * FROM v_apuestas_activas WHERE id = $1`,
        [id]
    );
    return rows[0] ?? null;
};

export const previewApuesta = async (opcionId: string, monto: number) =>   {
    const { rows } = await pool.query(
        `SELECT * FROM fn_preview_apuesta($1, $2)`,
        [monto, opcionId]
    );
    return rows[0] ?? null;
};

export const cerrarApuestasExpiradas = async () => {
    const { rows } = await pool.query(`CALL sp_cerrar_apuestas_expiradas(NULL)`);
    return rows[0] as { p_total_cerradas: number };
};
    