const crypto = require('crypto');
const { query } = require('./bd');

const COOKIE_NAME = 'tallerpro_session';
const MAX_AGE_MS = 8 * 60 * 60 * 1000;

function getSecret() {
  const raw = process.env.APP_SESSION_SECRET || process.env.DB_PASSWORD;
  if (!raw) throw new Error('Configura APP_SESSION_SECRET en el entorno de producción.');
  return crypto.createHash('sha256').update(String(raw)).digest();
}

function encrypt(payload) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', getSecret(), iv);
  const body = Buffer.concat([
    cipher.update(JSON.stringify(payload), 'utf8'),
    cipher.final()
  ]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, body]).toString('base64url');
}

function decrypt(token) {
  try {
    const raw = Buffer.from(token, 'base64url');
    if (raw.length < 28) return null;
    const iv = raw.subarray(0, 12);
    const tag = raw.subarray(12, 28);
    const body = raw.subarray(28);
    const decipher = crypto.createDecipheriv('aes-256-gcm', getSecret(), iv);
    decipher.setAuthTag(tag);
    const payload = JSON.parse(Buffer.concat([
      decipher.update(body),
      decipher.final()
    ]).toString('utf8'));

    if (!payload || !payload.id_usuario || !payload.exp) return null;
    if (Date.now() > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

function createSession(user) {
  const payload = {
    id_usuario: Number(user.id_usuario),
    nombre_usuario: user.nombre_usuario,
    email: user.email,
    roles: user.roles || [],
    exp: Date.now() + MAX_AGE_MS
  };
  return { token: encrypt(payload), payload };
}

function getSessionUser(req) {
  const token = req.cookies && req.cookies[COOKIE_NAME];
  return token ? decrypt(token) : null;
}

function setSessionCookie(res, token) {
  res.cookie(COOKIE_NAME, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    maxAge: MAX_AGE_MS,
    path: '/'
  });
}

function clearSessionCookie(res) {
  res.clearCookie(COOKIE_NAME, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/'
  });
}

async function requireAuth(req, res, next) {
  try {
    const user = getSessionUser(req);
    if (!user) {
      if (req.originalUrl.startsWith('/api/')) {
        return res.status(401).json({ error: 'Sesión no válida o expirada.' });
      }
      return res.redirect('/login');
    }

    const dbUser = await query(`
      SELECT activo,bloqueado_hasta
      FROM USUARIOS
      WHERE id_usuario=@id_usuario
    `,{id_usuario:Number(user.id_usuario)});

    const state=dbUser.recordset[0];
    if(!state || !state.activo || (state.bloqueado_hasta && new Date(state.bloqueado_hasta)>new Date())){
      clearSessionCookie(res);
      if(req.originalUrl.startsWith('/api/')){
        return res.status(401).json({error:'La sesión ya no está autorizada.'});
      }
      return res.redirect('/login');
    }

    req.user = user;
    res.locals.currentUser = user;
    next();
  } catch(e) {
    next(e);
  }
}

async function getUserPermissions(id_usuario) {
  const result = await query(`
    SELECT DISTINCT p.id_permiso, p.codigo, p.nombre, p.modulo
    FROM USUARIO_ROL ur
    INNER JOIN ROLES r ON r.id_rol = ur.id_rol
    INNER JOIN ROL_PERMISO rp ON rp.id_rol = r.id_rol
    INNER JOIN PERMISOS p ON p.id_permiso = rp.id_permiso
    WHERE ur.id_usuario = @id_usuario
      AND ISNULL(r.activo, 1) = 1
    ORDER BY p.modulo, p.codigo
  `, { id_usuario: Number(id_usuario) });
  return result.recordset;
}

function requirePermission(...codes) {
  const required = codes.flat().map(c => String(c || '').trim().toUpperCase()).filter(Boolean);
  return async (req, res, next) => {
    try {
      if (!req.user) return res.status(401).json({ error: 'Sesión no válida o expirada.' });
      if (!required.length) return res.status(403).json({ error: 'Operación no autorizada.' });

      const params = { id_usuario: Number(req.user.id_usuario) };
      const placeholders = required.map((code, i) => {
        params[`perm${i}`] = code;
        return `@perm${i}`;
      });

      const result = await query(`
        SELECT TOP 1 p.codigo
        FROM USUARIO_ROL ur
        INNER JOIN ROLES r ON r.id_rol = ur.id_rol
        INNER JOIN ROL_PERMISO rp ON rp.id_rol = r.id_rol
        INNER JOIN PERMISOS p ON p.id_permiso = rp.id_permiso
        WHERE ur.id_usuario = @id_usuario
          AND ISNULL(r.activo, 1) = 1
          AND UPPER(p.codigo) IN (${placeholders.join(',')})
      `, params);

      if (!result.recordset.length) {
        return res.status(403).json({ error: 'No tienes permiso para realizar esta operación.' });
      }
      next();
    } catch (e) {
      next(e);
    }
  };
}

function modulePermission(moduleName) {
  const prefix = String(moduleName || '').trim().toUpperCase();
  return (req, res, next) => {
    let action = 'CONSULTAR';
    if (req.method === 'POST') action = 'REGISTRAR';
    else if (req.method === 'PUT' || req.method === 'PATCH') action = 'MODIFICAR';
    else if (req.method === 'DELETE') action = 'ELIMINAR';
    return requirePermission(`${prefix}_${action}`)(req, res, next);
  };
}

module.exports = {
  COOKIE_NAME,
  MAX_AGE_MS,
  createSession,
  getSessionUser,
  setSessionCookie,
  clearSessionCookie,
  requireAuth,
  requirePermission,
  modulePermission,
  getUserPermissions
};
