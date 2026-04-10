import { Request, Response, NextFunction } from 'express';

export const errorMiddleware = (
    err: Error,
    _req: Request,
    res: Response,
    _next: NextFunction
) => {
    console.error('Error no manejado:', err.message);
    res.status(500).json({ message: 'Error interno del servidor' });
};