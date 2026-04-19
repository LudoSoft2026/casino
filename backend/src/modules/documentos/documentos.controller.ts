import  { Request, Response } from 'express';
import { 
    subirDocumento,
    revisarDocuemento,
    listarPendientes , 
    obtenerDocumento
} from './documentos.service';
import { revisarDocumentoSchema, subirDocumentoSchema } from './documentos.schema';

export const subir = async (req: Request, res: Response) => {
    if (!req.file) {
        res.status(400).json({ mensaje: 'No se recibio ningun archivo' });
        return;
    }

    const parsed = subirDocumentoSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ errores: parsed.error.flatten().fieldErrors });
        return;
    }

    const result = await subirDocumento(
        req.usuario!.id,
        parsed.data.numero_documento,
        parsed.data.tipo_documento,
        req.file.path,
        req.file.mimetype,
        req.file.size
    );

    if (!result.ok) {
        res.status(400).json({ mensaje: result.mensaje });
        return;
    }

    res.status(200).json({ mensaje: result.mensaje });
};

export const revisar =async (req: Request, res: Response) => {
    const parsed = revisarDocumentoSchema.safeParse(req.body);
    if (!parsed.success) {
        res.status(400).json({ errores: parsed.error.flatten().fieldErrors });
        return;
    }

    const result = await revisarDocuemento(
        req.usuario!.id,
        parsed.data.documento_id,
        parsed.data.aprobar,
        parsed.data.motivo_rechazo
    );

    res.json({ mensaje: result.p_mensaje });
};

export const pendientes = async (_req: Request, res: Response) => {
    const documentos = await listarPendientes ();    
    res.json(documentos);
};

export const miDocumento = async (req: Request, res: Response) => {
    const doc = await obtenerDocumento(req.usuario!.id);
    if (!doc) {
        res.status(404).json({ mensaje: 'No tienes documentos subidos' });
        return;
    }
    res.json( { documento: doc });
};