import { pool } from '../../config/db';
import { ProponerResultadoDTO, ConfirmarResultadoDTO } from './resultados.schema';

export const proponerResultado = async (creadorId: string, data: ProponerResultadoDTO) => {
    const { rows } = await pool.query(
        `CALL sp_proponer_resultado($1, $2, $3, NULL, NULL)`,
        [creadorId, data.apuesta_id, data.opcion_ganadora_id]
    );
    return rows[0] as { p_resultado_id: string | null; p_mensaje: string };
};

export const confirmarResultado = async (adminId: string, data: ConfirmarResultadoDTO) => {
    const { rows } = await pool.query(
        `CALL sp_confirmar_resultado($1, $2, $3, NULL, $4)`,
        [adminId, data.resultado_id, data.aprobar, data.motivo_rechazo ?? null]
    );
    return rows[0] as { p_mensaje: string };
};
 export const listarResultadosPendientes = async () => {
    const { rows } = await pool.query(
        `SELECT r.*, a.titulo AS apuesta_titulo, o.descripcion AS opcion_ganadora FROM resultados_apuestas r  JOIN apuestas a ON a.id = r.apuesta_id JOIN opciones_apuestas o ON o.id = r.opcion_ganadora_id WHERE r.estado = 'propuesto' ORDER BY r.fecha_propuesta ASC`
    );
    return rows;
};
