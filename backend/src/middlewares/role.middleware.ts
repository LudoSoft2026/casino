import { Request, Response, NextFunction } from 'express';

export const soloAdmin = (req: Request, res: Response, next: NextFunction) => {
    if (req.usuario?.rol !== 'administrador') {
        res.status(403).json({ message: 'Acceso denegado. Solo los administradores pueden realizar esta acción.' });
        return;
    }
    next();
};

export const soloVerificado = (req: Request, res: Response, next: NextFunction) => {
    if (!req.usuario) {
        res.status(401).json({ message: 'No autenticado.' });
        return;
    }
    next();
};