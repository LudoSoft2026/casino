import { Request, Response } from "express";
import {
    participar,
    obtenerHistorial,
    obtenerParticipacionPorApuesta,
} from "./participaciones.service";

export const realizarApuesta = async (req: Request, res: Response) => {
    const usuarioId = req.usuario!.id; // Asumiendo que el ID del usuario está disponible en req.user
    const result =  await participar(usuarioId, req.body);

    if (!result.p_part_id) {
        res.status(400).json({ mensaje: result.p_mensaje });
        return;
    }

    res.status(200).json({
        mensaje: result.p_mensaje,
        participacionId: result.p_part_id,
        cuatoAplicada: result.p_cuota_aplicada,
        gananciaSiGana: result.p_ganancia_si_gana,
    });
};

export const historial = async (req: Request, res: Response) => {
    const usuarioId = req.usuario!.id; // Asumiendo que el ID del usuario está disponible en req.user
    const participaciones = await obtenerHistorial(usuarioId);
    res.json(participaciones);
};

export const porApuesta = async (req: Request, res: Response) => {
    const participaciones = await obtenerParticipacionPorApuesta(req.params.apuestaId);
    res.json(participaciones);
};