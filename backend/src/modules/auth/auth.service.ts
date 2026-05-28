import { pool } from "../../config/db";
import { ENV } from "../../config/env";
import * as bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { RegistroDTO, LoginDTO } from "./auth.schema";

export const registrarUsuario = async (data: RegistroDTO) => {
  const password_hash = await bcrypt.hash(data.password, 10);

  const { rows } = await pool.query(
    `CALL sp_registrar_usuario($1, $2, $3, $4, $5, $6, $7, $8, NULL, NULL)`,
    [
      data.nombre,
      data.apellido_paterno,
      data.apellido_materno ?? null,
      data.fecha_nacimiento,
      data.telefono,
      data.alias,
      data.correo,
      password_hash,
    ]
  );
  return rows[0] as { p_usuario_id: string | null; p_mensaje: string };
};

export const loginUsuario = async (data: LoginDTO, ip: string, userAgent: string) => {
  const { rows } = await pool.query(
    `SELECT id, password_hash, estado, rol, bloqueado_hasta, alias, correo
     FROM usuarios WHERE correo = LOWER(TRIM($1))`,
    [data.correo]
  );

  const usuario = rows[0];

  if (!usuario) {
    return { token: null, mensaje: 'Credenciales incorrectas.' };
  }

  if (usuario.bloqueado_hasta && new Date(usuario.bloqueado_hasta) > new Date()) {
    return { token: null, mensaje: 'Cuenta bloqueada temporalmente. Intenta más tarde.' };
  }

  if (usuario.estado === 'suspendida') {
    return { token: null, mensaje: 'Su cuenta se encuentra suspendida por infringir las normas de la plataforma.' };
  }

  if (usuario.estado === 'bloqueada' && !usuario.bloqueado_hasta) {
    return { token: null, mensaje: 'Su cuenta se encuentra bloqueada. Contacte al administrador.' };
  }

  if (!usuario.password_hash) {
    return { token: null, mensaje: 'Credenciales incorrectas.' };
  }

  const passwordOk = await bcrypt.compare(data.password, usuario.password_hash as string);

  await pool.query(
    `CALL sp_gestionar_login($1, $2, $3, $4, NULL, NULL)`,
    [usuario.id, passwordOk, ip, userAgent]
  );

  if (!passwordOk) {
    return { token: null, mensaje: 'Credenciales incorrectas.' };
  }

  const token = jwt.sign(
    { id: usuario.id, rol: usuario.rol },
    ENV.JWT_SECRET,
    { expiresIn: ENV.JWT_EXPIRES_IN as any }
  );

  return {
    token,
    mensaje: 'Inicio de sesión exitoso.',
    usuario: {
      id:     usuario.id,
      rol:    usuario.rol,
      estado: usuario.estado,
      alias:  usuario.alias,
      correo: usuario.correo,
    },
  };
}