import { Request, Response } from "express";
import { obtenerSaldo, recargarSaldo, obtenerHistorial, obtenerHistorialAdmin } from "./saldos.service";

export const consultar = async (req: Request, res: Response) => {
  const usuarioId = req.usuario!.id;
  const saldo     = await obtenerSaldo(usuarioId);
  if (!saldo) {
    res.status(404).json({ mensaje: 'Saldo no encontrado' });
    return;
  }
  res.json(saldo);
};

export const recarga = async (req: Request, res: Response) => {
  const usuarioId = req.usuario!.id;
  const { monto, metodo } = req.body;
  const resultado = await recargarSaldo(usuarioId, monto, metodo);
  res.json({ mensaje: resultado.p_mensaje });
};

export const historial = async (req: Request, res: Response) => {
  const usuarioId   = req.usuario!.id;
  const movimientos = await obtenerHistorial(usuarioId);
  res.json({ movimientos });
};

export const historialAdmin = async (_req: Request, res: Response) => {
  const movimientos = await obtenerHistorialAdmin();
  res.json({ movimientos });
};