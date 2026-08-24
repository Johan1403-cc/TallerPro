const express = require('express');
const { query, executeProcedure } = require('../bd');
const { createCrudRouter } = require('./crud');

const router = express.Router();

router.get('/:id/detalle', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const [orden, servicios, repuestos, historial] = await Promise.all([
      query(`SELECT o.id_orden AS id,o.estado,o.fecha_ingreso,v.placa,c.nombre AS cliente,e.nombre AS empleado
             FROM ORDENES_TRABAJO o INNER JOIN VEHICULOS v ON v.id_vehiculo=o.id_vehiculo
             INNER JOIN CLIENTES c ON c.id_cliente=v.id_cliente LEFT JOIN EMPLEADOS e ON e.id_empleado=o.id_empleado
             WHERE o.id_orden=@id`, { id }),
      query(`SELECT d.id_detalle AS id,s.nombre,d.cantidad,d.subtotal
             FROM DETALLE_ORDEN_SERVICIOS d INNER JOIN SERVICIOS s ON s.id_servicio=d.id_servicio
             WHERE d.id_orden=@id`, { id }),
      query(`SELECT d.id_detalle AS id,r.nombre,d.cantidad,d.subtotal
             FROM DETALLE_ORDEN_REPUESTOS d INNER JOIN REPUESTOS r ON r.id_repuesto=d.id_repuesto
             WHERE d.id_orden=@id`, { id }),
      query(`SELECT h.estado_anterior,h.estado_nuevo,h.fecha_hora,h.observacion
             FROM HISTORIAL_ESTADO_ORDEN h WHERE h.id_orden=@id ORDER BY h.fecha_hora`, { id })
    ]);
    res.json({ orden: orden.recordset[0] || null, servicios: servicios.recordset, repuestos: repuestos.recordset, historial: historial.recordset });
  } catch (e) { next(e); }
});

router.post('/:id/estado', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_CAMBIAR_ESTADO_ORDEN', {
      id_orden: Number(req.params.id),
      nuevo_estado: req.body.estado,
      id_usuario: Number(req.body.id_usuario),
      observacion: req.body.observacion || null
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.post('/:id/repuesto', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_USAR_REPUESTO_EN_ORDEN', {
      id_orden: Number(req.params.id),
      id_repuesto: Number(req.body.id_repuesto),
      cantidad: Number(req.body.cantidad),
      id_usuario: Number(req.body.id_usuario)
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.use(createCrudRouter({
  table: 'ORDENES_TRABAJO',
  id: 'id_orden',
  columns: ['id_vehiculo','id_empleado','estado'],
  select: `SELECT o.id_orden AS id, o.id_vehiculo, v.placa, c.nombre AS cliente,
                  o.id_empleado, e.nombre AS empleado, o.estado, o.fecha_ingreso,
                  COALESCE((SELECT SUM(dos.subtotal) FROM DETALLE_ORDEN_SERVICIOS dos WHERE dos.id_orden=o.id_orden),0)
                  + COALESCE((SELECT SUM(dor.subtotal) FROM DETALLE_ORDEN_REPUESTOS dor WHERE dor.id_orden=o.id_orden),0) AS total
           FROM ORDENES_TRABAJO o
           INNER JOIN VEHICULOS v ON v.id_vehiculo=o.id_vehiculo
           INNER JOIN CLIENTES c ON c.id_cliente=v.id_cliente
           LEFT JOIN EMPLEADOS e ON e.id_empleado=o.id_empleado
           ORDER BY o.fecha_ingreso DESC`
}));

module.exports = router;
