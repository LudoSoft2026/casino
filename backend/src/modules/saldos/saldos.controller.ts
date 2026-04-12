import { Request, Response } from "express";
import { obtenerSaldo, recargarSaldo } from "./saldos.service";

export const consultar = async (req: Request, res: Response) => {
    const usuarioId = req.usuario!.id;
    const saldo = await obtenerSaldo(usuarioId);

    if (!saldo) {
        res.status(404).jsonp({ mensaje: 'Saldo no encontrado' });
        return;
    }

    res.jsonp(saldo);
};

export const recarga = async (req: Request, res: Response) => {
    const usuarioId = req.usuario!.id;
    const { monto, metodo } = req.body;
    const resultado = await recargarSaldo(usuarioId, monto, metodo);
    res.json({ mensaje: resultado.p_mensaje });
};