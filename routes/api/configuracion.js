const express = require('express');
const { getPool, query } = require('../bd');
const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const r = await query('SELECT clave,valor,descripcion FROM CONFIGURACION_GENERAL ORDER BY clave');
    res.json(r.recordset);
  } catch (e) { next(e); }
});

router.put('/', async (req, res, next) => {
  try {
    const pool = await getPool();
    for (const [clave,valor] of Object.entries(req.body || {})) {
      await pool.request()
        .input('clave', clave)
        .input('valor', valor)
        .query(`IF EXISTS (SELECT 1 FROM CONFIGURACION_GENERAL WHERE clave=@clave)
                  UPDATE CONFIGURACION_GENERAL SET valor=@valor WHERE clave=@clave
                ELSE
                  INSERT INTO CONFIGURACION_GENERAL(clave,valor) VALUES(@clave,@valor)`);
    }
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
