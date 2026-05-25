import { getIO } from './socket';


//Notificar nueva participacion en una apuesta
export const emitirNuevaParticipacion = (apuestaId: string, data: {
    totalParticipantes: number;
    totalApostado: number;
}) => {
    getIO().to(`apuesta:${apuestaId}`).emit('apuesta:actualizada', data);
};

//Notificar resultado confirmado
export const emitirResultadoConfirmado = (apuestaId: string, data: {
    opcionGanadora: string;
    mensaje: string;
}) => {
    getIO().to(`apuesta:${apuestaId}`).emit('resultado:confirmado', data);
}

//Notificar actualizacion de saldo a un usuario especifico
export const emitirSaldoActualizado = (usuarioId: string, saldo: number) => {
    getIO().to(`usuario:${usuarioId}`).emit('saldo:actualizado', { saldo });
};

//Notificar apuesta proxima a cerrar
export const emitirApuestaPorCerrar = (apuestaId: string) => {
    getIO().to(`apuesta:${apuestaId}`).emit('apuesta:por_cerrar', {
        mensaje: 'La apuesta cerrara en menos de 30 segundos',
    });
};