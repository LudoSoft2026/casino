import { Request, Response } from "express";
import { 
    proponerResultado,
    confirmarResultado,
    listarResultadosPendientes,
} from './resultados.service';

export const proponer = async (req: Request, res: Response) => {
    const creadorId = req.usuario!.id;
    const result = await proponerResultado(creadorId, req.body);

    if (result.p_resultado_id) {
        res.status(400).json({ mensaje: result.p_mensaje });
        return;
    }

    res.status(201).json({ 
        mensaje: result.p_mensaje,
        resultadoId: result.p_resultado_id,
    });
};

 export const confirmar = async (req: Request, res: Response) => {
    const adminId = req.usuario!.id;
    const result = await confirmarResultado(adminId, req.body);

    res.json({ mensaje: result.p_mensaje });
};

export const pendientes = async (_req: Request, res: Response) => {
    const resultados = await listarResultadosPendientes();
    res.json(resultados);
};  