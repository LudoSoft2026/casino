import { pool } from '../../config/db';
import { ParticiparDTO } from './participaciones.schema';

 export const participar = async (usuarioId: string, data: ParticiparDTO) => {
    const { rows } = await pool.query(
        'CALL sp_participar_apuesta($1, $2, $3, $4, NULL, NULL, NULL, NULL)',
        [usuarioId, data.apuesta_id, data.opcion_id, data.monto]
    );
    return rows[0] as {
      p_part_id: string | null;
      p_ganancia_si_gana: number;
      p_cuota_aplicada: number;
      p_mensaje: string;
    };
};

export const obtenerHistorial = async (usuarioId: string) => {
    const { rows } = await pool.query(
      `SELECT * FROM v_historial_participaciones WHERE usuario_id = $1 ORDER BY fecha_participacion DESC`,
      [usuarioId]
    );
    return rows;
};

export const obtenerParticipacionPorApuesta = async (apuestaId: string) => {
    const { rows } = await pool.query(
      `SELECT * FROM v_historial_participaciones WHERE apuesta_id = $1`,
      [apuestaId]
    );
    return rows;
};
