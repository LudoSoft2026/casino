import { Request, Response } from "express";
import {
    crearApuesta,
    listarApuestas,
    obtenerApuesta,
    obtenerApuestasCerradas,
    obtenerMisApuestas,
    obtenerApuestasConParticipantes,
    declararGanadorAdmin,
    previewApuesta,
} from "./apuestas.service";

export const crear = async (req: Request, res: Response) => {
    const creadorId = req.usuario!.id;
    const result = await crearApuesta(creadorId, req.body);
    if (!result.p_apuesta_id) {
        res.status(400).json({ mensaje: result.p_mensaje });
        return;
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

export const preview = async (req: Request, res: Response) => {
    const { opcionId, monto } = req.query;
    if (!opcionId || !monto) {
        res.status(400).json({ mensaje: 'Faltan parámetros opcionId o monto' });
        return;
    }
    const result = await previewApuesta(String(opcionId), Number(monto));
    if (!result) {
        res.status(404).json({ mensaje: 'Opción no encontrada o monto inválido' });
        return;
    }
    res.json({ preview: result });
};

export const apuestasCerradas = async (_req: Request, res: Response) => {
    const apuestas = await obtenerApuestasCerradas();
    res.json({ apuestas });
};

export const misApuestas = async (req: Request, res: Response) => {
    const creadorId = req.usuario!.id;
    const apuestas  = await obtenerMisApuestas(creadorId);
    res.json({ apuestas });
};

export const todasConParticipantes = async (_req: Request, res: Response) => {
    const apuestas = await obtenerApuestasConParticipantes();
    res.json({ apuestas });
};

export const declararGanador = async (req: Request, res: Response) => {
    const adminId                        = req.usuario!.id;
    const { apuesta_id, opcion_ganadora_id } = req.body;
    const result = await declararGanadorAdmin(adminId, apuesta_id, opcion_ganadora_id);
    if (!result.ok) {
        res.status(400).json({ mensaje: result.mensaje });
        return;
    }
    res.json({ mensaje: result.mensaje });
};