import { pool } from '../../config/db';

export const obtenerSaldo = async (usuarioId: string) => {
  const { rows } = await pool.query(
    'SELECT * FROM v_saldo_usuario WHERE usuario_id = $1',
    [usuarioId]
  );
  return rows[0];
};

export const recargarSaldo = async (usuarioId: string, monto: number, metodo: string) => {
  const { rows } = await pool.query(
    'CALL sp_recargar_saldo($1, $2, $3, NULL)',
    [usuarioId, monto, metodo]
  );
  return rows[0] as { p_mensaje: string };
};

export const obtenerHistorial = async (usuarioId: string) => {
  const { rows } = await pool.query(
    `SELECT tipo, monto, saldo_anterior, saldo_posterior, descripcion, fecha
     FROM transacciones
     WHERE usuario_id = $1
     ORDER BY fecha DESC`,
    [usuarioId]
  );
  return rows;
};

export const obtenerHistorialAdmin = async () => {
  const { rows } = await pool.query(
    `SELECT u.alias, t.tipo, t.monto, t.saldo_anterior, t.saldo_posterior, t.descripcion, t.fecha
     FROM transacciones t
     JOIN usuarios u ON u.id = t.usuario_id
     ORDER BY t.fecha DESC`
  );
  return rows;
};