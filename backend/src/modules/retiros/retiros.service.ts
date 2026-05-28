import { pool } from '../../config/db';
import { RetirarDTO } from './retiros.schema';
import { emitirSaldoActualizado } from '../../config/eventos';

export const solicitarRetiro = async (usuarioId: string, data: RetirarDTO) => {
  const { rows } = await pool.query(
    `CALL sp_solicitar_retiro($1, $2, $3, NULL, NULL)`,
    [usuarioId, data.monto_solicitado, data.metodo_retiro]
  )

  const result = rows[0] as { p_retiro_id: string; p_mensaje: string }

  if (result.p_retiro_id) {
    const { rows: saldoRows } = await pool.query(
      'SELECT saldo_disponible FROM saldos WHERE usuario_id = $1',
      [usuarioId]
    )
    emitirSaldoActualizado(usuarioId, saldoRows[0].saldo_disponible)
  }

  return result
}

export const obtenerRetiros = async (usuarioId: string) => {
  const { rows } = await pool.query(
    `SELECT * FROM retiros WHERE usuario_id = $1 ORDER BY fecha_solicitud DESC`,
    [usuarioId]
  )
  return rows
}