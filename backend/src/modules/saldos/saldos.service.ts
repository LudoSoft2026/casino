import { pool } from '../../config/db';

export const obtenerSaldo = async (usuarioId: string) => {
    const { rows }= await pool.query(
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