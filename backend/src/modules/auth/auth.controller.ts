import { Request, Response } from 'express';
import { registrarUsuario, loginUsuario } from './auth.service';
import { registroSchema, loginSchema } from './auth.schema';

export const registro = async (req: Request, res: Response) => {
    const parsed = registroSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ errores: parsed.error.flatten().fieldErrors });
        return;
    }

    // Llamar al servicio de registro
    const result = await registrarUsuario(parsed.data);
    if (!result.p_usuario_id) {
        res.status(400).json({ mensaje: result.p_mensaje });
        return;
    }

    res.status(201).json({ mensaje: result.p_mensaje, usuarioId: result.p_usuario_id });
};

export const login = async (req: Request, res: Response) => {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ errores: parsed.error.flatten().fieldErrors });
        return;
    }

    const ip = req.ip ?? `0.0.0.0`;
    const userAgent = req.headers['user-agent'] ?? '';
    const result = await loginUsuario(parsed.data, ip, userAgent);

    if (!result.token) {
        res.status(401).json({ mensaje: result.mensaje });
        return;
    }

    res.json({result});
}