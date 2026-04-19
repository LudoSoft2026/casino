import { pool } from '../../config/db';

export const subirDocumento = async (
    usuarioId: string,
    numeroDocumento: string,
    tipoDocumento: string,
    rutaArchivo: string,
    tipoMime: string,
    tamañoBytes: number
) => {
    const { rows: existing } = await pool.query(
        'SELECT id, estado FROM documentos_identidad WHERE usuario_id = $1',
        [usuarioId]
    );

    if (existing.length > 0) {
        if (existing[0].estado === 'aprobado') {
            return { ok: false, mensaje: 'Tu identidad ya fue verificada'};
        }
        // Actualizar documento existe
        await pool.query(
            `UPDATE documentos_identidad  SET numero_documento = $1, tipo_documento = $2, ruta_archivo = $3, tipo_mime = $4, tamano_bytes = $5, estado = 'pendiente', motivo_rechazo = NULL, fecha_subida = NOW()        WHERE usuario_id = $6`,
            [numeroDocumento, tipoDocumento, rutaArchivo, tipoMime, tamañoBytes, usuarioId]
        );
    }  else { 
        await pool.query(
            `INSERT INTO documentos_identidad (usuario_id, numero_documento, tipo_documento, ruta_archivo, tipo_mime, tamano_bytes, estado) VALUES ($1, $2, $3, $4, $5, $6)`,
            [usuarioId, numeroDocumento, tipoDocumento, rutaArchivo, tipoMime, tamañoBytes]
        );
    }

    //Cambiar estado a pendiente
    await pool.query(
        `UPDATE usuarios SET estado = 'pendiente' WHERE id = $1`,
        [usuarioId]
    );
    
    return { ok: true, mensaje: 'Documento subido exitosamente, Tu cuenta queda en estado pendiente de verificacion'};
};

export const revisarDocuemento = async (adminId: string, documentoId: string, aprobar: boolean, motivoRechazo?: string) => {
    const { rows } = await pool.query(
        'SELECT sp_revisar_documento($1, $2, $3, NULL, $4)',
        [adminId, documentoId, aprobar, motivoRechazo ?? null]
    );
    return rows[0] as { p_mensaje: string };
};

export const listarPendientes  = async () => {
    const { rows } = await pool.query(`SELECT * FROM v_documentos_identidad`);
    return rows;
};

export const obtenerDocumento = async (usuarioId: string) => {
    const { rows } = await pool.query(
        `SELECT id, tipo_documento, numero_documento, estado, motivo_rechazo, fecha_subida FROM documentos_identidad WHERE usuario_id = $1`,
        [usuarioId]
    );
    return rows[0] ?? null;
};