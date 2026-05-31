import { pool } from '../../config/db';

export const crearCategoria = async (adminId: string, nombre: string, descripcion: string, icono: string) => {
  const { rows } = await pool.query(
    'CALL sp_crear_categoria($1, $2, $3, $4, NULL, NULL)',
    [adminId, nombre, descripcion, icono]
  )
  return rows[0] as { p_mensaje: string; p_categoria_id: string | null }
}

export const listarCategorias = async () => {
  const { rows } = await pool.query(
    `SELECT id, nombre, descripcion, icono, activa FROM categorias ORDER BY nombre`
  )
  return rows
}

export const toggleCategoria = async (adminId: string, categoriaId: string) => {
  const { rows: admin } = await pool.query(
    `SELECT rol FROM usuarios WHERE id = $1`, [adminId]
  )
  if (admin[0]?.rol !== 'administrador') {
    return { mensaje: 'No tiene los permisos suficientes.' }
  }

  const { rows } = await pool.query(
    `UPDATE categorias SET activa = NOT activa WHERE id = $1 RETURNING activa, nombre`,
    [categoriaId]
  )
  const estado = rows[0].activa ? 'activada' : 'desactivada'
  return { mensaje: `Categoría ${estado} correctamente.` }
}

export const eliminarCategoria = async (adminId: string, categoriaId: string) => {
  const { rows: admin } = await pool.query(
    `SELECT rol FROM usuarios WHERE id = $1`, [adminId]
  )
  if (admin[0]?.rol !== 'administrador') {
    return { ok: false, mensaje: 'No tiene los permisos suficientes.' }
  }

  const { rows: apuestas } = await pool.query(
    `SELECT COUNT(*) FROM apuestas WHERE categoria_id = $1 AND estado = 'activa'`,
    [categoriaId]
  )
  if (parseInt(apuestas[0].count) > 0) {
    return { ok: false, mensaje: 'No se puede eliminar la categoría porque tiene apuestas asociadas.' }
  }

  await pool.query(`DELETE FROM categorias WHERE id = $1`, [categoriaId])
  return { ok: true, mensaje: 'Categoría eliminada correctamente.' }
}