import { Request, Response } from 'express';
import { registrarUsuario, loginUsuario } from './auth.service';

export const registro = async (req: Request, res: Response) => {
    const result = await registrarUsuario(req.body);
    if (!result.p_usuario_id) {
        res.status(400).json({ mensaje: result.p_mensaje });
        return;
    }

    res.status(201).json({ mensaje: result.p_mensaje, usuarioId: result.p_usuario_id });
};

export const login = async (req: Request, res: Response) => {
    const ip                = req.ip ?? `0.0.0.0`;
    const userAgent         = req.headers['user-agent'] ?? '';
    const result            = await loginUsuario(req.body, ip, userAgent);

    if (!result.token) {
        res.status(401).json({ mensaje: result.mensaje });
        return;
    }

    res.json(result);
}