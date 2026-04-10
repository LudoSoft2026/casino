import { JwtPayload } from 'jsonwebtoken';

declare global {
  namespace Express {
    export interface Request {
      usuario?: {
        id: string;
        rol: 'usuario' | 'administrador';
      }
    }
  }
}