import { Request, Response } from "express";
import {
    crearApuesta,
    listarApuestas,
    obtenerApuesta,
    previewApuesta,
    cerrarApuestasExpiradas,
    obtenerMisApuestas
} from "./apuestas.service";


export const crear = async (req: Request, res: Response) => {
    const creadorId = req.usuario!.id;
    const result = await crearApuesta(creadorId, req.body);

    if (!result.p_apuesta_id) {
        res.status(400).json({ mensaje: result.p_mensaje });
        return
    }
    
    res.status(201).json({ mensaje: result.p_mensaje, apuestaId: result.p_apuesta_id });
};

export const listar = async (_req: Request, res: Response) => {
    const apuestas = await listarApuestas();
    res.json({ apuestas });
};

export const obtener = async (req: Request, res: Response) => {
    const apuesta = await obtenerApuesta(String(req.params.id));
    if (!apuesta) {
        res.status(404).json({ mensaje: 'Apuesta no encontrada' });
        return;
    }
    res.json({ apuesta });
};

export const misApuestas = async (req: Request, res: Response) => {
  const creadorId = req.usuario!.id;
  const apuestas  = await obtenerMisApuestas(creadorId);
  res.json({ apuestas });
};

export const preview = async (req: Request, res: Response) => {
    const { opcionId, monto } = req.query;

    if (!opcionId || !monto) {
        res.status(400).json({ mensaje: 'Faltan parámetros opcionId o monto' });
        return;
    }

    const result = await previewApuesta( String(opcionId), Number(monto));
    if (!result) {
        res.status(404).json({ mensaje: 'Opción no encontrada o monto inválido' });
        return;
    }
    res.json({ preview: result });
};