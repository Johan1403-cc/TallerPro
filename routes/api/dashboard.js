const express = require('express');
const { query } = require('../bd');
const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT
        (SELECT COUNT(*) FROM VEHICULOS) AS vehiculos,
        (SELECT COUNT(*) FROM ORDENES_TRABAJO WHERE estado NOT IN ('FINALIZADA','CANCELADA')) AS ordenes,
        (SELECT COUNT(*) FROM DIAGNOSTICOS WHERE estado IN ('PENDIENTE','EN_REVISION')) AS diagnosticos,
        (SELECT COUNT(*) FROM COTIZACIONES WHERE estado IN ('ENVIADA','MODIFICADA')) AS cotizaciones,
        (SELECT COUNT(*) FROM REPUESTOS) AS inventario,
        (SELECT COALESCE(SUM(total),0) FROM FACTURAS WHERE estado='PAGADA' AND CAST(fecha_hora AS DATE)=CAST(GETDATE() AS DATE)) AS ventas_hoy,
        (SELECT COALESCE(SUM(total),0) FROM FACTURAS WHERE estado IN ('PENDIENTE','PARCIAL')) AS por_cobrar,
        (SELECT COALESCE(SUM(total),0) FROM FACTURAS WHERE estado='PAGADA' AND YEAR(fecha_hora)=YEAR(GETDATE()) AND MONTH(fecha_hora)=MONTH(GETDATE())) AS ingresos_mes
    `);
    const recientes = await query(`
      SELECT TOP 8 o.id_orden AS id, o.estado, o.fecha_ingreso, v.placa, c.nombre AS cliente
      FROM ORDENES_TRABAJO o
      INNER JOIN VEHICULOS v ON v.id_vehiculo=o.id_vehiculo
      INNER JOIN CLIENTES c ON c.id_cliente=v.id_cliente
      ORDER BY o.fecha_ingreso DESC
    `);
    res.json({ stats: r.recordset[0], recientes: recientes.recordset });
  } catch (e) { next(e); }
});

module.exports = router;
