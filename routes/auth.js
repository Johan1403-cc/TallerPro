const crypto = require('crypto');

const COOKIE_NAME = 'tallerpro_session';
const MAX_AGE_MS = 8 * 60 * 60 * 1000;

// MODO PRUEBAS: permite entrar al sistema sin login cuando TEST_MODE=true.
// Para una demostración real de roles, TEST_MODE debe estar en false.
const TEST_MODE = String(process.env.TEST_MODE || '').toLowerCase() === 'true';
const TEST_USER = {
  id_usuario: 0,
  nombre_usuario: 'Usuario de Pruebas',
  email: 'pruebas@tallerpro.local',
  roles: [{ id_rol: 0, nombre: 'Administrador', descripcion: 'Acceso de pruebas' }]
};

function normalizeRole(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toLowerCase();
}

function userRoleNames(user) {
  return Array.isArray(user?.roles)
    ? user.roles.map(r => normalizeRole(r?.nombre || r)).filter(Boolean)
    : [];
}

function hasRole(user, ...allowedRoles) {
  const roles = userRoleNames(user);
  if (roles.includes('administrador')) return true;
  const allowed = allowedRoles.flat().map(normalizeRole);
  return allowed.some(role => roles.includes(role));
}

function getSecret() {
  const raw = process.env.APP_SESSION_SECRET || `${process.env.DB_PASSWORD || 'tallerpro'}:tallerpro-session`;
  return crypto.createHash('sha256').update(raw).digest();
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

    if (!payload || !payload.id_usuario || !payload.nombre_usuario || !payload.exp) return null;
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

  return {
    token: encrypt(payload),
    payload
  };
}

function getSessionUser(req) {
  if (TEST_MODE) return TEST_USER;

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
  res.clearCookie(COOKIE_NAME, { httpOnly: true, sameSite: 'lax', path: '/' });
}

function requireAuth(req, res, next) {
  const user = getSessionUser(req);
  if (!user) {
    if (req.originalUrl.startsWith('/api/')) {
      return res.status(401).json({ error: 'Sesión no válida o expirada' });
    }
    return res.redirect('/login');
  }

  req.user = user;
  res.locals.currentUser = user;
  next();
}

function requireRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Sesión no válida o expirada' });
    }
    if (!hasRole(req.user, allowedRoles)) {
      return res.status(403).json({
        error: 'No tienes permisos para acceder a este módulo.'
      });
    }
    next();
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
  requireRoles,
  hasRole,
  userRoleNames,
  normalizeRole
};
