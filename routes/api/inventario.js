const express = require('express');
const { executeProcedure } = require('../bd');
const { createCrudRouter } = require('./crud');

const router = express.Router();

router.post('/:id/movimiento', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_REGISTRAR_MOVIMIENTO_INVENTARIO', {
      id_repuesto: Number(req.params.id),
      tipo_movimiento: req.body.tipo_movimiento,
      cantidad: Number(req.body.cantidad),
      id_usuario: Number(req.body.id_usuario),
      documento_referencia: req.body.documento_referencia || null,
      observaciones: req.body.observaciones || null,
      forzar_negativo: req.body.forzar_negativo ? 1 : 0
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.use(createCrudRouter({
  table: 'REPUESTOS', id: 'id_repuesto',
  columns: ['id_categoria','id_proveedor','nombre','stock_actual','precio_venta','codigo_interno','codigo_barras','marca','unidad_medida','precio_compra','porcentaje_impuesto','existencia_minima','existencia_maxima','ubicacion_bodega','estado','tipo_producto'],
  select: `SELECT r.id_repuesto AS id, r.id_categoria, cr.nombre AS categoria,
                  r.id_proveedor, p.nombre_empresa AS proveedor, r.nombre,
                  r.stock_actual, r.precio_venta, r.codigo_interno, r.codigo_barras, r.marca, r.unidad_medida,
                  r.precio_compra, r.porcentaje_impuesto, r.existencia_minima, r.existencia_maxima,
                  r.ubicacion_bodega, r.estado, r.tipo_producto
           FROM REPUESTOS r
           LEFT JOIN CATEGORIAS_REPUESTOS cr ON cr.id_categoria=r.id_categoria
           LEFT JOIN PROVEEDORES p ON p.id_proveedor=r.id_proveedor
           ORDER BY r.nombre`
}));

module.exports = router;
