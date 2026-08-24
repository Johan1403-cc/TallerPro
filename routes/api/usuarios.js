const express = require('express');
const crypto = require('crypto');
const { getPool, query } = require('../bd');

const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT u.id_usuario AS id,
             u.nombre_usuario,
             u.email,
             u.id_cliente,
             cl.nombre AS cliente,
             u.activo,
             u.fecha_creacion,
             u.ultimo_acceso,
             u.bloqueado_hasta,
             COALESCE(STRING_AGG(r.nombre, ', '), 'Sin rol') AS roles
      FROM USUARIOS u
      LEFT JOIN CLIENTES cl ON cl.id_cliente = u.id_cliente
      LEFT JOIN USUARIO_ROL ur ON ur.id_usuario = u.id_usuario
      LEFT JOIN ROLES r ON r.id_rol = ur.id_rol
      GROUP BY u.id_usuario,u.nombre_usuario,u.email,u.id_cliente,cl.nombre,u.activo,
               u.fecha_creacion,u.ultimo_acceso,u.bloqueado_hasta
      ORDER BY u.nombre_usuario
    `);
    res.json(r.recordset);
  } catch (e) { next(e); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT u.id_usuario AS id,
             u.nombre_usuario,
             u.email,
             u.id_cliente,
             cl.nombre AS cliente,
             u.activo,
             u.fecha_creacion,
             u.ultimo_acceso,
             u.bloqueado_hasta,
             COALESCE(STRING_AGG(r.nombre, ', '), 'Sin rol') AS roles
      FROM USUARIOS u
      LEFT JOIN CLIENTES cl ON cl.id_cliente = u.id_cliente
      LEFT JOIN USUARIO_ROL ur ON ur.id_usuario = u.id_usuario
      LEFT JOIN ROLES r ON r.id_rol = ur.id_rol
      WHERE u.id_usuario=@id
      GROUP BY u.id_usuario,u.nombre_usuario,u.email,u.id_cliente,cl.nombre,u.activo,
               u.fecha_creacion,u.ultimo_acceso,u.bloqueado_hasta
    `, { id: Number(req.params.id) });
    if (!r.recordset.length) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json(r.recordset[0]);
  } catch (e) { next(e); }
});

router.post('/', async (req, res, next) => {
  try {
    const { nombre_usuario, email, password, id_cliente, activo = true } = req.body;
    if (!nombre_usuario || !email || !password) {
      return res.status(400).json({ error: 'Usuario, correo y contraseña son obligatorios' });
    }
    const salt = crypto.randomBytes(32);
    const hash = crypto.scryptSync(String(password), salt, 64);
    const pool = await getPool();
    const r = await pool.request()
      .input('nombre_usuario', nombre_usuario)
      .input('email', email)
      .input('password_hash', hash)
      .input('password_salt', salt)
      .input('id_cliente', id_cliente || null)
      .input('activo', activo ? 1 : 0)
      .query(`INSERT INTO USUARIOS(nombre_usuario,email,password_hash,password_salt,id_cliente,activo)
              OUTPUT INSERTED.id_usuario AS id
              VALUES(@nombre_usuario,@email,@password_hash,@password_salt,@id_cliente,@activo)`);
    res.status(201).json({ id: r.recordset[0].id });
  } catch (e) { next(e); }
});

router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const { nombre_usuario, email, password, id_cliente, activo } = req.body;
    const pool = await getPool();
    const request = pool.request().input('id', id);
    const sets = [];

    if (nombre_usuario !== undefined) { sets.push('nombre_usuario=@nombre_usuario'); request.input('nombre_usuario', nombre_usuario); }
    if (email !== undefined) { sets.push('email=@email'); request.input('email', email); }
    if (id_cliente !== undefined) { sets.push('id_cliente=@id_cliente'); request.input('id_cliente', id_cliente || null); }
    if (activo !== undefined) { sets.push('activo=@activo'); request.input('activo', activo ? 1 : 0); }
    if (password) {
      const salt = crypto.randomBytes(32);
      const hash = crypto.scryptSync(String(password), salt, 64);
      sets.push('password_hash=@password_hash', 'password_salt=@password_salt');
      request.input('password_hash', hash).input('password_salt', salt);
    }

    if (!sets.length) return res.status(400).json({ error: 'No hay cambios' });
    await request.query(`UPDATE USUARIOS SET ${sets.join(',')} WHERE id_usuario=@id`);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.delete('/:id', async (req, res, next) => {
  try {
    await query('DELETE FROM USUARIOS WHERE id_usuario=@id', { id: Number(req.params.id) });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.post('/:id/roles', async (req, res, next) => {
  try {
    await query(`IF NOT EXISTS(SELECT 1 FROM USUARIO_ROL WHERE id_usuario=@id_usuario AND id_rol=@id_rol)
                 INSERT INTO USUARIO_ROL(id_usuario,id_rol) VALUES(@id_usuario,@id_rol)`, {
      id_usuario: Number(req.params.id),
      id_rol: Number(req.body.id_rol)
    });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.delete('/:id/roles/:rol', async (req, res, next) => {
  try {
    await query('DELETE FROM USUARIO_ROL WHERE id_usuario=@id_usuario AND id_rol=@id_rol', {
      id_usuario: Number(req.params.id),
      id_rol: Number(req.params.rol)
    });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
