const express = require('express');
const { executeProcedure } = require('../bd');
const { createCrudRouter } = require('./crud');

const router = express.Router();

router.post('/:id/confirmar', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_CONFIRMAR_VENTA', {
      id_venta: Number(req.params.id),
      id_usuario: Number(req.body.id_usuario),
      forzar_negativo: req.body.forzar_negativo ? 1 : 0
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.use(createCrudRouter({
  table: 'VENTAS', id: 'id_venta',
  columns: ['id_cliente','id_empleado'],
  select: `SELECT v.id_venta AS id, v.id_cliente, c.nombre AS cliente,
                  v.id_empleado, e.nombre AS empleado, v.fecha,
                  COALESCE((SELECT SUM(d.subtotal) FROM DETALLE_VENTA d WHERE d.id_venta=v.id_venta),0) AS total
           FROM VENTAS v LEFT JOIN CLIENTES c ON c.id_cliente=v.id_cliente
           INNER JOIN EMPLEADOS e ON e.id_empleado=v.id_empleado
           ORDER BY v.fecha DESC`
}));

module.exports = router;
