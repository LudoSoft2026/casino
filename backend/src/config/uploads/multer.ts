import { error } from "console";
import multer from "multer";
import path from "path";

// 🔥 CAMBIO CLAVE: Cambiamos diskStorage por memoryStorage para generar el buffer que Cloudinary necesita
const storage = multer.memoryStorage();

const fileFilter = (_req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    const allowed = ['image/jpeg', 'image/png', 'image/pdf'];
    if (allowed.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Solo se permiten archivos JPEG, PNG y PDF'));
    }
};

export const upload = multer({ 
    storage, 
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB    
});