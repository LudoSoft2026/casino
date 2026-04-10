import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { ENV } from '../config/env';

export const authenticateToken = (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ message: 'Token no proporcionado' });
        return;
    }

    const token = authHeader.split(' ')[1];

    try {
        const payload = jwt.verify(token, ENV.JWT_SECRET) as { id: string; rol: 'usuario' | 'administrador' };
        req.usuario = { id: payload.id, rol: payload.rol };
        next();
    } catch {
        res.status(401).json({ message: 'Token inválido o expirado' });
    }
};