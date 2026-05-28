import { pool } from '../../config/db';

export const cambiarEstadoUsuario = async (
  adminId:    string,
  usuarioId:  string,
  accion:     string,
  motivo:     string
) => {
  const { rows } = await pool.query(
    'CALL sp_cambiar_estado_usuario($1, $2, $3, $4, NULL)',
    [adminId, usuarioId, accion, motivo]
  )
  return rows[0] as { p_mensaje: string }
}

export const listarUsuarios = async () => {
  const { rows } = await pool.query(
    `SELECT id, alias, correo, rol, estado, fecha_registro
     FROM usuarios
     WHERE rol != 'administrador'
     ORDER BY fecha_registro DESC`
  )
  return rows
}