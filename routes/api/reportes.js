const express = require('express');
const { query } = require('../bd');
const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const [ventas,servicios,estados] = await Promise.all([
      query(`SELECT CONVERT(char(7),fecha_hora,120) periodo, SUM(total) total
             FROM FACTURAS WHERE estado='PAGADA' GROUP BY CONVERT(char(7),fecha_hora,120)
             ORDER BY periodo DESC`),
      query(`SELECT TOP 10 s.nombre, SUM(d.cantidad) cantidad
             FROM DETALLE_ORDEN_SERVICIOS d INNER JOIN SERVICIOS s ON s.id_servicio=d.id_servicio
             GROUP BY s.nombre ORDER BY SUM(d.cantidad) DESC`),
      query(`SELECT estado, COUNT(*) cantidad FROM ORDENES_TRABAJO GROUP BY estado`)
    ]);
    res.json({ ventas: ventas.recordset, servicios: servicios.recordset, estados: estados.recordset });
  } catch (e) { next(e); }
});

module.exports = router;
