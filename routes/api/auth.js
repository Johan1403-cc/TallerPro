const express = require('express');
const crypto = require('crypto');
const { query } = require('../bd');
const {
  createSession,
  setSessionCookie,
  clearSessionCookie,
  getSessionUser,
  getUserPermissions
} = require('../auth');

const router = express.Router();
const MAX_FAILED_ATTEMPTS = Math.max(3, Number(process.env.LOGIN_MAX_ATTEMPTS || 5));
const LOCK_MINUTES = Math.max(1, Number(process.env.LOGIN_LOCK_MINUTES || 15));

function verifyPassword(password, storedHash, storedSalt) {
  if (!storedHash || !storedSalt) return false;
  const salt = Buffer.isBuffer(storedSalt) ? storedSalt : Buffer.from(storedSalt);
  const hash = Buffer.isBuffer(storedHash) ? storedHash : Buffer.from(storedHash);
  const calculated = crypto.scryptSync(String(password), salt, hash.length || 64);
  return calculated.length === hash.length && crypto.timingSafeEqual(calculated, hash);
}

async function audit({ id_usuario = null, ip = null, accion, descripcion }) {
  try {
    await query(`
      INSERT INTO BITACORA_AUDITORIA
        (id_usuario, direccion_ip, modulo, accion, tipo_operacion, descripcion)
      VALUES
        (@id_usuario, @ip, 'AUTENTICACION', @accion, 'CONSULTA', @descripcion)
    `, { id_usuario, ip, accion, descripcion });
  } catch (e) {
    console.error('No se pudo registrar auditoría de autenticación:', e.message);
  }
}

router.post('/login', async (req, res, next) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');

    if (!email || !password) {
      return res.status(400).json({ error: 'Ingresa el correo electrónico y la contraseña.' });
    }

    const result = await query(`
      SELECT TOP 1
        id_usuario, nombre_usuario, email, password_hash, password_salt,
        activo, intentos_fallidos, bloqueado_hasta
      FROM USUARIOS
      WHERE LOWER(email) = @email
    `, { email });

    if (!result.recordset.length) {
      await audit({
        ip: req.ip || null,
        accion: 'LOGIN_FALLIDO',
        descripcion: 'Intento de acceso con credenciales inválidas.'
      });
      return res.status(401).json({ error: 'Correo o contraseña incorrectos.' });
    }

    const user = result.recordset[0];
    const now = new Date();

    if (!user.activo) {
      await audit({
        id_usuario: user.id_usuario,
        ip: req.ip || null,
        accion: 'LOGIN_BLOQUEADO',
        descripcion: 'Intento de acceso de usuario inactivo.'
      });
      return res.status(403).json({ error: 'El usuario está inactivo.' });
    }

    if (user.bloqueado_hasta && new Date(user.bloqueado_hasta) > now) {
      const minutes = Math.max(1, Math.ceil((new Date(user.bloqueado_hasta) - now) / 60000));
      return res.status(423).json({
        error: `Cuenta bloqueada temporalmente. Intenta nuevamente en ${minutes} minuto(s).`
      });
    }

    if (user.bloqueado_hasta && new Date(user.bloqueado_hasta) <= now) {
      await query(`
        UPDATE USUARIOS
        SET intentos_fallidos = 0, bloqueado_hasta = NULL
        WHERE id_usuario = @id_usuario
      `, { id_usuario: user.id_usuario });
      user.intentos_fallidos = 0;
    }

    if (!verifyPassword(password, user.password_hash, user.password_salt)) {
      const failed = await query(`
        UPDATE USUARIOS
        SET
          intentos_fallidos = CASE
            WHEN intentos_fallidos + 1 >= @maxAttempts THEN 0
            ELSE intentos_fallidos + 1
          END,
          bloqueado_hasta = CASE
            WHEN intentos_fallidos + 1 >= @maxAttempts
              THEN DATEADD(MINUTE, @lockMinutes, GETDATE())
            ELSE NULL
          END
        OUTPUT INSERTED.intentos_fallidos, INSERTED.bloqueado_hasta
        WHERE id_usuario = @id_usuario
      `, {
        id_usuario: user.id_usuario,
        maxAttempts: MAX_FAILED_ATTEMPTS,
        lockMinutes: LOCK_MINUTES
      });

      const state = failed.recordset[0] || {};
      const locked = state.bloqueado_hasta && new Date(state.bloqueado_hasta) > new Date();

      await audit({
        id_usuario: user.id_usuario,
        ip: req.ip || null,
        accion: 'LOGIN_FALLIDO',
        descripcion: locked
          ? `Cuenta bloqueada temporalmente por ${MAX_FAILED_ATTEMPTS} intentos fallidos.`
          : 'Contraseña incorrecta.'
      });

      if (locked) {
        return res.status(423).json({
          error: `Demasiados intentos fallidos. La cuenta queda bloqueada durante ${LOCK_MINUTES} minutos.`
        });
      }

      const attempts = Number(state.intentos_fallidos || 0);
      return res.status(401).json({
        error: 'Correo o contraseña incorrectos.',
        remainingAttempts: Math.max(0, MAX_FAILED_ATTEMPTS - attempts)
      });
    }

    const rolesResult = await query(`
      SELECT r.id_rol, r.nombre, r.descripcion
      FROM USUARIO_ROL ur
      INNER JOIN ROLES r ON r.id_rol = ur.id_rol
      WHERE ur.id_usuario = @id_usuario
        AND ISNULL(r.activo, 1) = 1
      ORDER BY r.nombre
    `, { id_usuario: user.id_usuario });

    const roles = rolesResult.recordset;

    await query(`
      UPDATE USUARIOS
      SET ultimo_acceso = GETDATE(),
          intentos_fallidos = 0,
          bloqueado_hasta = NULL
      WHERE id_usuario = @id_usuario
    `, { id_usuario: user.id_usuario });

    const permissions = await getUserPermissions(user.id_usuario);
    const { token, payload } = createSession({
      id_usuario: user.id_usuario,
      nombre_usuario: user.nombre_usuario,
      email: user.email,
      roles
    });

    setSessionCookie(res, token);

    await audit({
      id_usuario: user.id_usuario,
      ip: req.ip || null,
      accion: 'LOGIN',
      descripcion: 'Inicio de sesión correcto.'
    });

    res.json({ ok: true, user: payload, permissions });
  } catch (e) {
    next(e);
  }
});

router.get('/me', async (req, res, next) => {
  try {
    const user = getSessionUser(req);
    if (!user) return res.status(401).json({ error: 'No hay una sesión activa.' });
    const permissions = await getUserPermissions(user.id_usuario);
    res.json({ ok: true, user, permissions });
  } catch (e) {
    next(e);
  }
});

router.get('/permissions', async (req, res, next) => {
  try {
    const user = getSessionUser(req);
    if (!user) return res.status(401).json({ error: 'No hay una sesión activa.' });
    res.json({ permissions: await getUserPermissions(user.id_usuario) });
  } catch (e) {
    next(e);
  }
});

router.post('/logout', async (req, res) => {
  const user = getSessionUser(req);
  if (user) {
    await audit({
      id_usuario: user.id_usuario,
      ip: req.ip || null,
      accion: 'LOGOUT',
      descripcion: 'Cierre de sesión.'
    });
  }
  clearSessionCookie(res);
  res.json({ ok: true });
});

module.exports = router;
