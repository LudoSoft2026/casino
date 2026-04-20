import { pool } from '../../config/db';
import { ParticiparDTO } from './participaciones.schema';
import { emitirNuevaParticipacion } from '../../config/eventos';

 export const participar = async (usuarioId: string, data: ParticiparDTO) => {
    const { rows } = await pool.query(
        'CALL sp_participar_apuesta($1, $2, $3, $4, NULL, NULL, NULL, NULL)',
        [usuarioId, data.apuesta_id, data.opcion_id, data.monto]
    );
    const result = rows[0] as {
      p_part_id:      string | null;
      p_ganancia_si_gana: number;
      p_cuota_aplicada: number;
      p_mensaje: string;
    };
    

    //Emitir actualizacion en tiempo real si la apuesta fue exitosa
    if (result.p_part_id){
      const { rows: apuesta } = await pool.query(
        `SELECT total_participantes, total_apostado FROM apuestas WHERE id = $1`,
        [data.apuesta_id]
      );
      emitirNuevaParticipacion(data.apuesta_id, {
        totalParticipantes: apuesta[0].total_participantes,
        totalApostado: apuesta[0].total_apostado, 
      });
    }

    return result;
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
