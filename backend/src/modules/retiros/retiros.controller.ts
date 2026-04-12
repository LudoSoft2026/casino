import { Request, Response } from "express";
import { solicitarRetiro, obtenerRetiros } from "./retiros.service";

export const solicitar = async (req: Request, res: Response) => {
    const usuarioId = req.usuario!.id;
    const result = await solicitarRetiro(usuarioId, req.body);

    if (!result.p_retiro_id){
        res.status(400).json({ mensaje: result.p_mensaje });
        return;
    };

    res.status(201).json({
        mensaje: result.p_mensaje,
        retiro_id: result.p_retiro_id
    });
};

export const historial = async (req: Request, res: Response) => {
    const usuarioId = req.usuario!.id;
    const retiros = await obtenerRetiros(usuarioId);
    res.json( {retiros }
     );
};