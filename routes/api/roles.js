const express = require('express');
const { query } = require('../bd');
const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT r.id_rol AS id, r.nombre, r.descripcion, r.activo,
             COUNT(ur.id_usuario) AS usuarios
      FROM ROLES r LEFT JOIN USUARIO_ROL ur ON ur.id_rol=r.id_rol
      GROUP BY r.id_rol,r.nombre,r.descripcion,r.activo ORDER BY r.nombre
    `);
    res.json(r.recordset);
  } catch (e) { next(e); }
});

module.exports = router;
