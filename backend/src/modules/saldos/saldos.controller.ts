import { Request, Response } from "express";
import { obtenerSaldo, recargarSaldo, obtenerHistorial, obtenerHistorialAdmin, abonarSaldoAdmin, deducirSaldoAdmin } from './saldos.service'

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

export const abonar = async (req: Request, res: Response) => {
  const adminId = req.usuario!.id
  const { usuario_id, monto, motivo } = req.body
  const result = await abonarSaldoAdmin(adminId, usuario_id, monto, motivo)
  res.json({ mensaje: result.p_mensaje })
}

export const deducir = async (req: Request, res: Response) => {
  const adminId = req.usuario!.id
  const { usuario_id, monto, motivo } = req.body
  const result = await deducirSaldoAdmin(adminId, usuario_id, monto, motivo)
  res.json({ mensaje: result.p_mensaje })
}