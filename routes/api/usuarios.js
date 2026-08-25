const express = require('express');
const crypto = require('crypto');
const { getPool, query, sql } = require('../bd');
const { requirePermission } = require('../auth');

const router = express.Router();

function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email || '').trim());
}

function validatePassword(password, email = '', username = '') {
  const value = String(password || '');
  if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
  if (!/[a-z]/.test(value)) return 'La contraseña debe incluir al menos una letra minúscula.';
  if (!/[A-Z]/.test(value)) return 'La contraseña debe incluir al menos una letra mayúscula.';
  if (!/\d/.test(value)) return 'La contraseña debe incluir al menos un número.';
  if (!/[^A-Za-z0-9]/.test(value)) return 'La contraseña debe incluir al menos un carácter especial.';
  const lower = value.toLowerCase();
  const emailLocal = email ? String(email).split('@')[0].toLowerCase() : '';
  const userLower = username ? String(username).toLowerCase() : '';
  if (emailLocal.length >= 4 && lower.includes(emailLocal)) return 'La contraseña no debe contener el correo del usuario.';
  if (userLower.length >= 4 && lower.includes(userLower)) return 'La contraseña no debe contener el nombre de usuario.';
  return null;
}

function normalizeRoleIds(value) {
  const raw = Array.isArray(value) ? value : value == null ? [] : [value];
  return [...new Set(raw.map(Number).filter(Number.isInteger).filter(x => x > 0))];
}


function requireRoleAssignmentPermission(req,res,next){
  if(req.body && req.body.role_ids !== undefined){
    return requirePermission('PERMISOS_MODIFICAR')(req,res,next);
  }
  next();
}

const SELECT_USERS = `
  SELECT u.id_usuario AS id,
         u.nombre_usuario,
         u.email,
         u.activo,
         u.fecha_creacion,
         u.ultimo_acceso,
         u.intentos_fallidos,
         u.bloqueado_hasta,
         COALESCE(STRING_AGG(r.nombre, ', '), 'Sin rol') AS roles,
         COALESCE(STRING_AGG(CONVERT(varchar(20), r.id_rol), ','), '') AS role_ids
  FROM USUARIOS u
  LEFT JOIN USUARIO_ROL ur ON ur.id_usuario = u.id_usuario
  LEFT JOIN ROLES r ON r.id_rol = ur.id_rol
`;

router.get('/', async (req, res, next) => {
  try {
    const r = await query(`${SELECT_USERS}
      GROUP BY u.id_usuario,u.nombre_usuario,u.email,u.activo,u.fecha_creacion,
               u.ultimo_acceso,u.intentos_fallidos,u.bloqueado_hasta
      ORDER BY u.nombre_usuario`);
    res.json(r.recordset);
  } catch (e) { next(e); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const r = await query(`${SELECT_USERS}
      WHERE u.id_usuario=@id
      GROUP BY u.id_usuario,u.nombre_usuario,u.email,u.activo,u.fecha_creacion,
               u.ultimo_acceso,u.intentos_fallidos,u.bloqueado_hasta`, { id: Number(req.params.id) });
    if (!r.recordset.length) return res.status(404).json({ error: 'Usuario no encontrado.' });
    res.json(r.recordset[0]);
  } catch (e) { next(e); }
});

router.post('/', requirePermission('PERMISOS_MODIFICAR'), async (req, res, next) => {
  const nombre_usuario = String(req.body.nombre_usuario || '').trim();
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const roleIds = normalizeRoleIds(req.body.role_ids);
  const activo = req.body.activo === undefined ? true : ['1',1,true,'true'].includes(req.body.activo);

  if (!nombre_usuario || !email || !password) {
    return res.status(400).json({ error: 'Usuario, correo y contraseña son obligatorios.' });
  }
  if (!validateEmail(email)) return res.status(400).json({ error: 'El correo electrónico no es válido.' });
  const passwordError = validatePassword(password, email, nombre_usuario);
  if (passwordError) return res.status(400).json({ error: passwordError });
  if (!roleIds.length) return res.status(400).json({ error: 'Selecciona al menos un rol para el usuario.' });

  let transaction;
  try {
    const pool = await getPool();
    transaction = new sql.Transaction(pool);
    await transaction.begin();

    const duplicate = await new sql.Request(transaction)
      .input('nombre_usuario', nombre_usuario)
      .input('email', email)
      .query(`SELECT TOP 1 id_usuario FROM USUARIOS
              WHERE LOWER(nombre_usuario)=LOWER(@nombre_usuario) OR LOWER(email)=LOWER(@email)`);
    if (duplicate.recordset.length) {
      await transaction.rollback();
      return res.status(409).json({ error: 'Ya existe un usuario con ese nombre o correo.' });
    }

    const validRoles = await new sql.Request(transaction)
      .input('ids', roleIds.join(','))
      .query(`SELECT id_rol FROM ROLES
              WHERE activo=1 AND id_rol IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(@ids, ','))`);
    if (validRoles.recordset.length !== roleIds.length) {
      await transaction.rollback();
      return res.status(400).json({ error: 'Uno o más roles seleccionados no existen o están inactivos.' });
    }

    const salt = crypto.randomBytes(32);
    const hash = crypto.scryptSync(password, salt, 64);
    const inserted = await new sql.Request(transaction)
      .input('nombre_usuario', nombre_usuario)
      .input('email', email)
      .input('password_hash', hash)
      .input('password_salt', salt)
      .input('activo', activo ? 1 : 0)
      .query(`INSERT INTO USUARIOS(nombre_usuario,email,password_hash,password_salt,activo)
              OUTPUT INSERTED.id_usuario AS id
              VALUES(@nombre_usuario,@email,@password_hash,@password_salt,@activo)`);

    const id_usuario = inserted.recordset[0].id;
    for (const id_rol of roleIds) {
      await new sql.Request(transaction)
        .input('id_usuario', id_usuario)
        .input('id_rol', id_rol)
        .query(`INSERT INTO USUARIO_ROL(id_usuario,id_rol) VALUES(@id_usuario,@id_rol)`);
    }

    await transaction.commit();
    res.status(201).json({ id: id_usuario });
  } catch (e) {
    if (transaction?._aborted !== true) {
      try { await transaction?.rollback(); } catch {}
    }
    next(e);
  }
});

router.put('/:id', requireRoleAssignmentPermission, async (req, res, next) => {
  const id = Number(req.params.id);
  const nombre_usuario = req.body.nombre_usuario !== undefined ? String(req.body.nombre_usuario).trim() : undefined;
  const email = req.body.email !== undefined ? String(req.body.email).trim().toLowerCase() : undefined;
  const password = req.body.password ? String(req.body.password) : '';
  const roleIds = req.body.role_ids !== undefined ? normalizeRoleIds(req.body.role_ids) : null;

  if (email !== undefined && !validateEmail(email)) return res.status(400).json({ error: 'El correo electrónico no es válido.' });
  if (password) {
    const passwordError = validatePassword(password, email || '', nombre_usuario || '');
    if (passwordError) return res.status(400).json({ error: passwordError });
  }
  if (roleIds !== null && !roleIds.length) return res.status(400).json({ error: 'El usuario debe conservar al menos un rol.' });

  let transaction;
  try {
    const pool = await getPool();
    transaction = new sql.Transaction(pool);
    await transaction.begin();

    const currentResult = await new sql.Request(transaction).input('id', id)
      .query(`SELECT id_usuario,nombre_usuario,email FROM USUARIOS WHERE id_usuario=@id`);
    if (!currentResult.recordset.length) {
      await transaction.rollback();
      return res.status(404).json({ error: 'Usuario no encontrado.' });
    }
    const current = currentResult.recordset[0];

    const effectiveName = nombre_usuario !== undefined ? nombre_usuario : current.nombre_usuario;
    const effectiveEmail = email !== undefined ? email : current.email;

    const duplicate = await new sql.Request(transaction)
      .input('id', id).input('nombre_usuario', effectiveName).input('email', effectiveEmail)
      .query(`SELECT TOP 1 id_usuario FROM USUARIOS
              WHERE id_usuario<>@id AND (LOWER(nombre_usuario)=LOWER(@nombre_usuario) OR LOWER(email)=LOWER(@email))`);
    if (duplicate.recordset.length) {
      await transaction.rollback();
      return res.status(409).json({ error: 'Ya existe otro usuario con ese nombre o correo.' });
    }

    if (roleIds !== null) {
      const validRoles = await new sql.Request(transaction)
        .input('ids', roleIds.join(','))
        .query(`SELECT id_rol FROM ROLES
                WHERE activo=1 AND id_rol IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(@ids, ','))`);
      if (validRoles.recordset.length !== roleIds.length) {
        await transaction.rollback();
        return res.status(400).json({ error: 'Uno o más roles seleccionados no existen o están inactivos.' });
      }
    }

    const request = new sql.Request(transaction).input('id', id);
    const sets = [];
    if (nombre_usuario !== undefined) { sets.push('nombre_usuario=@nombre_usuario'); request.input('nombre_usuario', nombre_usuario); }
    if (email !== undefined) { sets.push('email=@email'); request.input('email', email); }
    if (req.body.activo !== undefined) {
      sets.push('activo=@activo');
      request.input('activo', ['1',1,true,'true'].includes(req.body.activo) ? 1 : 0);
    }
    if (password) {
      const salt = crypto.randomBytes(32);
      const hash = crypto.scryptSync(password, salt, 64);
      sets.push('password_hash=@password_hash','password_salt=@password_salt','intentos_fallidos=0','bloqueado_hasta=NULL');
      request.input('password_hash', hash).input('password_salt', salt);
    }
    if (sets.length) await request.query(`UPDATE USUARIOS SET ${sets.join(',')} WHERE id_usuario=@id`);

    if (roleIds !== null) {
      await new sql.Request(transaction).input('id_usuario', id).query(`DELETE FROM USUARIO_ROL WHERE id_usuario=@id_usuario`);
      for (const id_rol of roleIds) {
        await new sql.Request(transaction).input('id_usuario', id).input('id_rol', id_rol)
          .query(`INSERT INTO USUARIO_ROL(id_usuario,id_rol) VALUES(@id_usuario,@id_rol)`);
      }
    }

    await transaction.commit();
    res.json({ ok: true });
  } catch (e) {
    if (transaction?._aborted !== true) {
      try { await transaction?.rollback(); } catch {}
    }
    next(e);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const result = await query(`UPDATE USUARIOS
                                SET activo=0,intentos_fallidos=0,bloqueado_hasta=NULL
                                WHERE id_usuario=@id`, { id: Number(req.params.id) });
    if (!result.rowsAffected[0]) return res.status(404).json({ error: 'Usuario no encontrado.' });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

// Endpoints conservados para compatibilidad y administración avanzada.
router.post('/:id/roles', requirePermission('PERMISOS_MODIFICAR'), async (req, res, next) => {
  try {
    await query(`IF NOT EXISTS(SELECT 1 FROM USUARIO_ROL WHERE id_usuario=@id_usuario AND id_rol=@id_rol)
                 INSERT INTO USUARIO_ROL(id_usuario,id_rol) VALUES(@id_usuario,@id_rol)`, {
      id_usuario: Number(req.params.id), id_rol: Number(req.body.id_rol)
    });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.delete('/:id/roles/:rol', requirePermission('PERMISOS_MODIFICAR'), async (req, res, next) => {
  try {
    await query(`DELETE FROM USUARIO_ROL WHERE id_usuario=@id_usuario AND id_rol=@id_rol`, {
      id_usuario: Number(req.params.id), id_rol: Number(req.params.rol)
    });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
