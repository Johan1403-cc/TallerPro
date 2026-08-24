const express = require('express');
const { executeProcedure } = require('../bd');
const { createCrudRouter } = require('./crud');

const router = express.Router();

router.post('/:id/pagos', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_REGISTRAR_PAGO', {
      id_factura: Number(req.params.id),
      monto: Number(req.body.monto),
      forma_pago: req.body.forma_pago || 'EFECTIVO',
      numero_referencia: req.body.numero_referencia || null,
      id_usuario_recibe: Number(req.body.id_usuario_recibe),
      observaciones: req.body.observaciones || null
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.post('/:id/anular', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_ANULAR_FACTURA', {
      id_factura: Number(req.params.id),
      id_usuario: Number(req.body.id_usuario),
      motivo: req.body.motivo || 'Anulación solicitada desde TallerPro'
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.post('/desde-orden/:id', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_GENERAR_FACTURA_DESDE_ORDEN', {
      id_orden: Number(req.params.id),
      id_usuario_emite: Number(req.body.id_usuario_emite),
      porcentaje_impuesto: Number(req.body.porcentaje_impuesto ?? 13)
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.use(createCrudRouter({
  table: 'FACTURAS', id: 'id_factura',
  columns: ['numero_consecutivo','tipo_factura','id_orden','id_venta','id_cliente','subtotal','impuestos','descuentos','total','forma_pago','estado','id_usuario_emite'],
  select: `SELECT f.id_factura AS id, f.numero_consecutivo, f.tipo_factura,
                  f.id_orden, f.id_venta, f.id_cliente, c.nombre AS cliente,
                  f.fecha_hora, f.subtotal, f.impuestos, f.descuentos, f.total,
                  f.forma_pago, f.estado, f.id_usuario_emite, u.nombre_usuario AS usuario_emite
           FROM FACTURAS f
           LEFT JOIN CLIENTES c ON c.id_cliente=f.id_cliente
           LEFT JOIN USUARIOS u ON u.id_usuario=f.id_usuario_emite
           ORDER BY f.fecha_hora DESC`
}));

module.exports = router;
