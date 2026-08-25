const express = require('express');
const { executeProcedure } = require('../bd');
const { createCrudRouter } = require('./crud');

const router = express.Router();

router.use((req,res,next)=>{
  if(req.method==='POST' && req.path==='/') req.body.id_usuario=req.user.id_usuario;
  next();
});

router.post('/:id/confirmar', async (req, res, next) => {
  try {
    const result = await executeProcedure('SP_CONFIRMAR_COMPRA', {
      id_compra: Number(req.params.id),
      id_usuario: req.user.id_usuario
    });
    res.json({ ok: true, result: result.recordset });
  } catch (e) { next(e); }
});

router.use(createCrudRouter({
  table: 'COMPRAS', id: 'id_compra',
  columns: ['id_proveedor','numero_factura_proveedor','subtotal','impuestos','descuentos','total','forma_pago','estado','id_usuario'],
  select: `SELECT co.id_compra AS id, co.id_proveedor, p.nombre_empresa AS proveedor,
                  co.numero_factura_proveedor, co.fecha, co.subtotal, co.impuestos,
                  co.descuentos, co.total, co.forma_pago, co.estado, co.id_usuario, u.nombre_usuario AS usuario
           FROM COMPRAS co
           INNER JOIN PROVEEDORES p ON p.id_proveedor=co.id_proveedor
           LEFT JOIN USUARIOS u ON u.id_usuario=co.id_usuario
           ORDER BY co.fecha DESC`
}));

module.exports = router;
