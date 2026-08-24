const express = require('express');
const crypto = require('crypto');
const { query } = require('../bd');
const {
  createSession,
  setSessionCookie,
  clearSessionCookie,
  getSessionUser
} = require('../auth');

const router = express.Router();

function verifyPassword(password, storedHash, storedSalt) {
  if (!storedHash || !storedSalt) return false;

  const salt = Buffer.isBuffer(storedSalt)
    ? storedSalt
    : Buffer.from(storedSalt);

  const hash = Buffer.isBuffer(storedHash)
    ? storedHash
    : Buffer.from(storedHash);

  const calculated = crypto.scryptSync(String(password), salt, hash.length || 64);

  return calculated.length === hash.length &&
    crypto.timingSafeEqual(calculated, hash);
}

router.post('/login', async (req, res, next) => {
  try {
    const nombre_usuario = String(req.body.nombre_usuario || '').trim();
    const password = String(req.body.password || '');

    if (!nombre_usuario || !password) {
      return res.status(400).json({
        error: 'Ingresa el usuario y la contraseña.'
      });
    }

    const result = await query(`
      SELECT TOP 1
        u.id_usuario,
        u.nombre_usuario,
        u.email,
        u.password_hash,
        u.password_salt,
        u.activo,
        u.bloqueado_hasta
      FROM USUARIOS u
      WHERE LOWER(u.nombre_usuario) = LOWER(@nombre_usuario)
    `, { nombre_usuario });

    if (!result.recordset.length) {
      return res.status(401).json({ error: 'Usuario o contraseña incorrectos.' });
    }

    const user = result.recordset[0];

    if (!user.activo) {
      return res.status(403).json({ error: 'El usuario está inactivo.' });
    }

    if (user.bloqueado_hasta && new Date(user.bloqueado_hasta) > new Date()) {
      return res.status(403).json({ error: 'El usuario está temporalmente bloqueado.' });
    }

    if (!verifyPassword(password, user.password_hash, user.password_salt)) {
      return res.status(401).json({ error: 'Usuario o contraseña incorrectos.' });
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
      SET ultimo_acceso = GETDATE()
      WHERE id_usuario = @id_usuario
    `, { id_usuario: user.id_usuario });

    const { token, payload } = createSession({
      id_usuario: user.id_usuario,
      nombre_usuario: user.nombre_usuario,
      email: user.email,
      roles
    });

    setSessionCookie(res, token);

    res.json({
      ok: true,
      user: payload
    });
  } catch (e) {
    next(e);
  }
});

router.get('/me', (req, res) => {
  const user = getSessionUser(req);
  if (!user) return res.status(401).json({ error: 'No hay una sesión activa.' });
  res.json({ ok: true, user });
});

router.post('/logout', (req, res) => {
  clearSessionCookie(res);
  res.json({ ok: true });
});

module.exports = router;
