import { pool } from "../../config/db";
import {
  ProponerResultadoDTO,
  ConfirmarResultadoDTO,
} from "./resultados.schema";

export const proponerResultado = async (
  creadorId: string,
  data: ProponerResultadoDTO,
) => {
  // Verificar que es el creador
  const { rows: apuesta } = await pool.query(
    `SELECT id, creador_id, estado FROM apuestas WHERE id = $1`,
    [data.apuesta_id],
  );

  if (!apuesta[0])
    return { p_resultado_id: null, p_mensaje: "Apuesta no encontrada." };
  if (apuesta[0].creador_id !== creadorId)
    return {
      p_resultado_id: null,
      p_mensaje: "Solo el creador puede proponer el resultado.",
    };
  if (!["cerrada", "activa"].includes(apuesta[0].estado))
    return {
      p_resultado_id: null,
      p_mensaje: "La apuesta no está en estado válido.",
    };

  // Verificar resultado existente
  const { rows: existente } = await pool.query(
    `SELECT id FROM resultados_apuesta WHERE apuesta_id = $1 AND estado IN ('propuesto', 'confirmado')`,
    [data.apuesta_id],
  );
  if (existente.length > 0)
    return {
      p_resultado_id: null,
      p_mensaje: "Ya existe un resultado propuesto.",
    };

  // Cambiar estado y crear resultado
  await pool.query(`UPDATE apuestas SET estado = 'en_revision' WHERE id = $1`, [
    data.apuesta_id,
  ]);

  const { rows: resultado } = await pool.query(
    `INSERT INTO resultados_apuesta (apuesta_id, opcion_ganadora_id, propuesto_por, evidencia)
     VALUES ($1, $2, $3, $4) RETURNING id`,
    [data.apuesta_id, data.opcion_ganadora_id, creadorId, data.evidencia],
  );

  return {
    p_resultado_id: resultado[0].id,
    p_mensaje:
      "Resultado propuesto con éxito. En espera de aprobación administrativa.",
  };
};

export const obtenerApuestasCerradas = async () => {
  const { rows } = await pool.query(
    `SELECT a.id, a.titulo, a.estado,
      json_agg(
        json_build_object('id', o.id, 'descripcion', o.descripcion)
        ORDER BY o.orden
      ) AS opciones
     FROM apuestas a
     JOIN opciones_apuesta o ON o.apuesta_id = a.id
     WHERE a.estado IN ('cerrada', 'en_revision')
     GROUP BY a.id
     ORDER BY 
       CASE WHEN a.estado = 'en_revision' THEN 0 ELSE 1 END,
       a.fecha_finalizacion DESC`
  );
  return rows;
};

export const confirmarResultado = async (
  adminId: string,
  data: ConfirmarResultadoDTO,
) => {
  const { rows } = await pool.query(
    `CALL sp_confirmar_resultado($1, $2, $3, NULL, $4)`,
    [adminId, data.resultado_id, data.aprobar, data.motivo_rechazo ?? null],
  );
  return rows[0] as { p_mensaje: string };
};
export const listarResultadosPendientes = async () => {
  const { rows } = await pool.query(
    `SELECT r.*, a.titulo AS apuesta_titulo, o.descripcion AS opcion_ganadora FROM resultados_apuesta r  JOIN apuestas a ON a.id = r.apuesta_id JOIN opciones_apuesta o ON o.id = r.opcion_ganadora_id WHERE r.estado = 'propuesto' ORDER BY r.fecha_propuesta ASC`,
  );
  return rows;
};
