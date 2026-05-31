import { pool } from '../../config/db';

export const obtenerRankingSemanal = async () => {
  const { rows } = await pool.query(
    `SELECT 
      ROW_NUMBER() OVER (ORDER BY apuestas_ganadas DESC, ganancias_acumuladas DESC) AS posicion,
      alias,
      apuestas_ganadas,
      ganancias_acumuladas,
      semana_inicio,
      ultima_actualizacion
     FROM v_ranking_semanal`
  )
  return rows
}