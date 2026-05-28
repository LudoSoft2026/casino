import { pool } from '../../config/db';
import { ParticiparDTO } from './participaciones.schema';
import { emitirNuevaParticipacion, emitirSaldoActualizado } from '../../config/eventos';

export const participar = async (usuarioId: string, data: ParticiparDTO) => {
  const { rows: yaParticipo } = await pool.query(
    `SELECT id FROM participaciones 
     WHERE usuario_id = $1 AND apuesta_id = $2`,
    [usuarioId, data.apuesta_id]
  )

  if (yaParticipo.length > 0) {
    return {
      p_part_id:          null,
      p_ganancia_si_gana: 0,
      p_cuota_aplicada:   0,
      p_mensaje:          'Ya tienes una apuesta registrada en esta apuesta.',
    }
  }

  const { rows } = await pool.query(
    'CALL sp_participar_apuesta($1, $2, $3, $4, NULL, NULL, NULL, NULL)',
    [usuarioId, data.apuesta_id, data.opcion_id, data.monto]
  )

  const result = rows[0] as {
    p_part_id:          string | null;
    p_ganancia_si_gana: number;
    p_cuota_aplicada:   number;
    p_mensaje:          string;
  }

  if (result.p_part_id) {
    const { rows: apuesta } = await pool.query(
      `SELECT total_participantes, total_apostado FROM apuestas WHERE id = $1`,
      [data.apuesta_id]
    )
    emitirNuevaParticipacion(data.apuesta_id, {
      totalParticipantes: apuesta[0].total_participantes,
      totalApostado:      apuesta[0].total_apostado,
    })

    // Emitir saldo actualizado al usuario
    const { rows: saldoRows } = await pool.query(
      'SELECT saldo_disponible FROM saldos WHERE usuario_id = $1',
      [usuarioId]
    )
    console.log('💰 Emitiendo saldo a usuario:', usuarioId, saldoRows[0]?.saldo_disponible)
    emitirSaldoActualizado(usuarioId, saldoRows[0].saldo_disponible)
  }

  return result
}

export const obtenerHistorial = async (usuarioId: string) => {
  const { rows } = await pool.query(
    `SELECT * FROM v_historial_participaciones WHERE usuario_id = $1 ORDER BY fecha_participacion DESC`,
    [usuarioId]
  )
  return rows
}

export const obtenerParticipacionPorApuesta = async (apuestaId: string) => {
  const { rows } = await pool.query(
    `SELECT * FROM v_historial_participaciones WHERE apuesta_id = $1`,
    [apuestaId]
  )
  return rows
}

export const obtenerTodasParticipaciones = async () => {
  const { rows } = await pool.query(
    `SELECT 
      u.alias,
      u.id AS usuario_id,
      p.id,
      a.titulo AS apuesta_titulo,
      o.descripcion AS opcion_elegida,
      p.monto,
      p.ganancia_proyectada,
      p.ganancia,
      p.estado,
      p.fecha_participacion
     FROM participaciones p
     JOIN usuarios u ON u.id = p.usuario_id
     JOIN apuestas a ON a.id = p.apuesta_id
     JOIN opciones_apuesta o ON o.id = p.opcion_id
     ORDER BY u.alias, p.fecha_participacion DESC`
  )
  return rows
}