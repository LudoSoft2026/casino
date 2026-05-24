import { pool } from '../../config/db';
import { CrearApuestaDTO } from './apuestas.schema';

export const crearApuesta = async (creadorId: string, data: CrearApuestaDTO) => {
    const { rows } = await pool.query(
        `CALL SP_CREAR_APUESTA($1, $2, $3, $4, $5, $6, $7,NULL, NULL, $8)`,
        [
            creadorId,
            data.titulo,
            data.descripcion,
            data.opciones,
            data.probabilidades,
            data.monto_minimo,
            data.fecha_finalizacion,
            data.monto_maximo || null,
        ]
    );
    return rows[0] as { p_apuesta_id: string | null; p_mensaje: String};
};

export const listarApuestas = async () => {
      console.log('⏰ Hora del servidor:', new Date());
    const { rows } = await pool.query(`SELECT * FROM V_APUESTAS_ACTIVAS ORDER BY es_tendencia DESC, fecha_creacion DESC`);
    return rows;
};

export const obtenerApuesta = async (id: string) => {
    const { rows } = await pool.query(
        `SELECT * FROM v_apuestas_activas WHERE id = $1`,
        [id]
    );
    return rows[0] ?? null;
};

export const previewApuesta = async (opcionId: string, monto: number) =>   {
    const { rows } = await pool.query(
        `SELECT * FROM fn_preview_apuesta($1, $2)`,
        [monto, opcionId]
    );
    return rows[0] ?? null;
};

export const cerrarApuestasExpiradas = async () => {
    const { rows } = await pool.query(`CALL sp_cerrar_apuestas_expiradas(NULL)`);
    return rows[0] as { p_total_cerradas: number };
};
    
export const obtenerMisApuestas = async (usuarioId: string) => {
  const { rows } = await pool.query(
    `SELECT id, titulo, estado FROM apuestas 
     WHERE creador_id = $1 
     AND estado IN ('activa', 'cerrada', 'en_revision')
     ORDER BY fecha_creacion DESC`,
    [usuarioId]
  );
  return rows;
};

export const obtenerApuestasConParticipantes = async () => {
  const { rows } = await pool.query(
    `SELECT 
      a.id,
      a.titulo,
      a.estado,
      a.total_participantes,
      a.total_apostado,
      a.fecha_finalizacion,
      json_agg(
        json_build_object(
          'alias',               u.alias,
          'opcion_elegida',      o.descripcion,
          'monto',               p.monto,
          'ganancia_proyectada', p.ganancia_proyectada,
          'ganancia',            p.ganancia,
          'estado',              p.estado
        ) ORDER BY p.fecha_participacion
      ) AS participantes
     FROM apuestas a
     LEFT JOIN participaciones p ON p.apuesta_id = a.id
     LEFT JOIN usuarios u ON u.id = p.usuario_id
     LEFT JOIN opciones_apuesta o ON o.id = p.opcion_id
     GROUP BY a.id
     ORDER BY a.fecha_creacion DESC`
  );
  return rows;
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
     WHERE a.estado = 'cerrada'
     GROUP BY a.id
     ORDER BY a.fecha_finalizacion DESC`
  );
  return rows;
};

export const declararGanadorAdmin = async (adminId: string, apuestaId: string, opcionGanadoraId: string) => {
  // Obtener el creador de la apuesta
  const { rows: rowsApuesta } = await pool.query(
    `SELECT creador_id FROM apuestas WHERE id = $1`,
    [apuestaId]
  )

  if (rowsApuesta.length === 0) {
    return { ok: false, mensaje: 'Apuesta no encontrada.' }
  }

  const creadorId = rowsApuesta[0].creador_id

  // Proponer como el creador
  const { rows: rowsProponer } = await pool.query(
    `CALL sp_proponer_resultado($1, $2, $3, NULL, NULL)`,
    [creadorId, apuestaId, opcionGanadoraId]
  )
  const propuesta = rowsProponer[0] as { p_resultado_id: string | null; p_mensaje: string }

  if (!propuesta.p_resultado_id) {
    return { ok: false, mensaje: propuesta.p_mensaje }
  }

  // Confirmar como admin
  const { rows: rowsConfirmar } = await pool.query(
    `CALL sp_confirmar_resultado($1, $2, $3, NULL, $4)`,
    [adminId, propuesta.p_resultado_id, true, null]
  )
  const confirmacion = rowsConfirmar[0] as { p_mensaje: string }

  return { ok: true, mensaje: confirmacion.p_mensaje }
}