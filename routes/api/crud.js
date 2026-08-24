const express = require('express');
const { getPool, query } = require('../bd');

function cleanBody(body, allowed) {
  const out = {};
  allowed.forEach(k => {
    if (Object.prototype.hasOwnProperty.call(body, k)) {
      out[k] = body[k] === '' ? null : body[k];
    }
  });
  return out;
}

function createCrudRouter({ table, id, columns, select }) {
  const router = express.Router();

  router.get('/', async (req, res, next) => {
    try {
      const result = await query(select);
      res.json(result.recordset);
    } catch (e) { next(e); }
  });

  router.get('/:id', async (req, res, next) => {
    try {
      const result = await query(
        `SELECT * FROM ${table} WHERE ${id}=@id`,
        { id: Number(req.params.id) }
      );
      if (!result.recordset.length) {
        return res.status(404).json({ error: 'Registro no encontrado' });
      }
      res.json(result.recordset[0]);
    } catch (e) { next(e); }
  });

  router.post('/', async (req, res, next) => {
    try {
      const data = cleanBody(req.body, columns);
      const keys = Object.keys(data);
      if (!keys.length) {
        return res.status(400).json({ error: 'No hay datos para insertar' });
      }

      const pool = await getPool();
      const request = pool.request();
      keys.forEach(k => request.input(k, data[k]));

      const result = await request.query(`
        INSERT INTO ${table} (${keys.join(',')})
        OUTPUT INSERTED.${id} AS id
        VALUES (${keys.map(k => '@' + k).join(',')})
      `);

      res.status(201).json({ id: result.recordset[0].id });
    } catch (e) { next(e); }
  });

  router.put('/:id', async (req, res, next) => {
    try {
      const data = cleanBody(req.body, columns);
      const keys = Object.keys(data);
      if (!keys.length) {
        return res.status(400).json({ error: 'No hay datos para actualizar' });
      }

      const pool = await getPool();
      const request = pool.request().input('id', Number(req.params.id));
      keys.forEach(k => request.input(k, data[k]));

      await request.query(`
        UPDATE ${table}
        SET ${keys.map(k => `${k}=@${k}`).join(',')}
        WHERE ${id}=@id
      `);

      res.json({ ok: true });
    } catch (e) { next(e); }
  });

  router.delete('/:id', async (req, res, next) => {
    try {
      await query(
        `DELETE FROM ${table} WHERE ${id}=@id`,
        { id: Number(req.params.id) }
      );
      res.json({ ok: true });
    } catch (e) { next(e); }
  });

  return router;
}

module.exports = { createCrudRouter };
