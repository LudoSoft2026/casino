import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { ENV } from '../config/env';
import { pool } from '../config/db';

export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ message: 'Token no proporcionado' });
        return;
    }

    const token = authHeader.split(' ')[1];

    try {
        const payload = jwt.verify(token, ENV.JWT_SECRET) as { id: string; rol: 'usuario' | 'administrador'; iat: number };

        // Verificar si el token fue invalidado
        const { rows } = await pool.query(
            `SELECT estado, token_invalidado_en FROM usuarios WHERE id = $1`,
            [payload.id]
        )

        if (rows.length === 0) {
            res.status(401).json({ message: 'Usuario no encontrado.' })
            return
        }

        const usuario = rows[0]

        // Verificar si la cuenta está suspendida o bloqueada
        if (usuario.estado === 'suspendida') {
            res.status(403).json({ message: 'Su cuenta se encuentra suspendida por infringir las normas de la plataforma.' })
            return
        }

        if (usuario.estado === 'bloqueada') {
            res.status(403).json({ message: 'Su cuenta se encuentra bloqueada. Contacte al administrador.' })
            return
        }

        // Verificar si el token fue emitido antes de la invalidación
        if (usuario.token_invalidado_en) {
            const tokenIat = new Date(payload.iat * 1000)
            const invalidadoEn = new Date(usuario.token_invalidado_en)
            if (tokenIat < invalidadoEn) {
                res.status(401).json({ message: 'Su sesión ha sido invalidada. Inicie sesión nuevamente.' })
                return
            }
        }

        req.usuario = { id: payload.id, rol: payload.rol }
        next()
    } catch {
        res.status(401).json({ message: 'Token inválido o expirado' })
    }
}

export const authMiddleware = authenticateToken