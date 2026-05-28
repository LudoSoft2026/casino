import { Server } from 'socket.io'
import { Server as HttpServer } from 'http';

let io: Server;

export const initSocket = (HttpServer: HttpServer) => {
    io = new Server(HttpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST'],
        },
    });

    io.on('connection', (socket) => {
  console.log(`Cliente conectado: ${socket.id}`)

  socket.on('join:apuesta', (apuestaId: string) => {
    socket.join(`apuesta:${apuestaId}`)
    console.log(`Socket ${socket.id} unido a apuesta:${apuestaId}`)
  })

  socket.on('join:usuario', (usuarioId: string) => {
    socket.join(`usuario:${usuarioId}`)
    console.log(`👤 Socket ${socket.id} unido a usuario:${usuarioId}`)
  })

  socket.on('leave:apuesta', (apuestaId: string) => {
    socket.leave(`apuesta:${apuestaId}`)
  })

  socket.on('disconnect', () => {
    console.log(`Cliente desconectado: ${socket.id}`)
  })
})
    return io;
};

export const getIO = () => {
    if (!io) throw new Error('socket.io no inicializado');
    return io;
};