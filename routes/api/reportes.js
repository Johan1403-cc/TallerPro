const express = require('express');
const { query } = require('../bd');
const router = express.Router();

function dateFilter(req) {
  const desde = req.query.desde || null;
  const hasta = req.query.hasta || null;
  return { desde, hasta };
}
async function q(sql, params={}) {
  const r = await query(sql, params);
  return r.recordset;
}

router.get('/', async (req,res,next) => {
  try {
    const { desde, hasta } = dateFilter(req);
    const params = { desde, hasta };
    const dateWhereFacturas = `(@desde IS NULL OR fecha_hora>=@desde) AND (@hasta IS NULL OR fecha_hora<DATEADD(DAY,1,@hasta))`;

    const [
      ventasPeriodo, serviciosTop, ordenesEstado, trabajosPeriodo, trabajosMecanico,
      horasEmpleado, vehiculosMarcaModelo, clientesVisitas, clientesFacturacion,
      ventasVendedor, ventasCategoria, productosVendidos, bajoStock, sinMovimiento,
      comprasProveedor, ingresosServicios, ingresosProductos, facturasPendientes,
      utilidadProductos, utilidadOrdenes, ordenesSituacion
    ] = await Promise.all([
      q(`SELECT CONVERT(char(7),fecha_hora,120) periodo,COUNT(*) facturas,SUM(total) total
         FROM FACTURAS WHERE estado='PAGADA' AND ${dateWhereFacturas}
         GROUP BY CONVERT(char(7),fecha_hora,120) ORDER BY periodo DESC`, params),

      q(`SELECT TOP 10 s.nombre,SUM(d.cantidad) cantidad,SUM(d.subtotal) ingreso
         FROM DETALLE_ORDEN_SERVICIOS d
         INNER JOIN SERVICIOS s ON s.id_servicio=d.id_servicio
         GROUP BY s.nombre ORDER BY cantidad DESC`),

      q(`SELECT estado,COUNT(*) cantidad FROM ORDENES_TRABAJO GROUP BY estado ORDER BY cantidad DESC`),

      q(`SELECT CONVERT(char(7),fecha_ingreso,120) periodo,COUNT(*) trabajos
         FROM ORDENES_TRABAJO
         WHERE (@desde IS NULL OR fecha_ingreso>=@desde)
           AND (@hasta IS NULL OR fecha_ingreso<DATEADD(DAY,1,@hasta))
         GROUP BY CONVERT(char(7),fecha_ingreso,120) ORDER BY periodo DESC`, params),

      q(`SELECT e.nombre mecanico,COUNT(DISTINCT oe.id_orden) trabajos,
                COALESCE(SUM(oe.horas_trabajadas),0) horas
         FROM ORDEN_EMPLEADOS oe
         INNER JOIN EMPLEADOS e ON e.id_empleado=oe.id_empleado
         GROUP BY e.nombre ORDER BY trabajos DESC`),

      q(`SELECT e.nombre empleado,COALESCE(SUM(oe.horas_trabajadas),0) horas,
                COALESCE(SUM(oe.horas_trabajadas*oe.costo_hora),0) costo_mano_obra
         FROM ORDEN_EMPLEADOS oe
         INNER JOIN EMPLEADOS e ON e.id_empleado=oe.id_empleado
         GROUP BY e.nombre ORDER BY horas DESC`),

      q(`SELECT COALESCE(m.nombre,'Sin marca') marca,COALESCE(md.nombre,'Sin modelo') modelo,COUNT(*) cantidad
         FROM VEHICULOS v
         LEFT JOIN MARCAS_VEHICULO m ON m.id_marca=v.id_marca
         LEFT JOIN MODELOS_VEHICULO md ON md.id_modelo=v.id_modelo
         GROUP BY m.nombre,md.nombre ORDER BY cantidad DESC`),

      q(`SELECT TOP 10 c.nombre,COUNT(DISTINCT o.id_orden) visitas
         FROM CLIENTES c
         INNER JOIN VEHICULOS v ON v.id_cliente=c.id_cliente
         INNER JOIN ORDENES_TRABAJO o ON o.id_vehiculo=v.id_vehiculo
         GROUP BY c.nombre ORDER BY visitas DESC`),

      q(`SELECT TOP 10 c.nombre,COALESCE(SUM(f.total),0) facturacion
         FROM CLIENTES c
         LEFT JOIN FACTURAS f ON f.id_cliente=c.id_cliente AND f.estado<>'ANULADA'
         GROUP BY c.nombre ORDER BY facturacion DESC`),

      q(`SELECT e.nombre vendedor,COUNT(v.id_venta) ventas,COALESCE(SUM(f.total),0) facturacion
         FROM EMPLEADOS e
         LEFT JOIN VENTAS v ON v.id_empleado=e.id_empleado
         LEFT JOIN FACTURAS f ON f.id_venta=v.id_venta AND f.estado<>'ANULADA'
         GROUP BY e.nombre ORDER BY facturacion DESC`),

      q(`SELECT COALESCE(cr.nombre,'Sin categoría') categoria,SUM(dv.cantidad) cantidad,
                SUM(dv.subtotal) total
         FROM DETALLE_VENTA dv
         INNER JOIN REPUESTOS r ON r.id_repuesto=dv.id_repuesto
         LEFT JOIN CATEGORIAS_REPUESTOS cr ON cr.id_categoria=r.id_categoria
         GROUP BY cr.nombre ORDER BY total DESC`),

      q(`SELECT TOP 15 r.nombre,SUM(dv.cantidad) cantidad,SUM(dv.subtotal) total
         FROM DETALLE_VENTA dv
         INNER JOIN REPUESTOS r ON r.id_repuesto=dv.id_repuesto
         GROUP BY r.nombre ORDER BY cantidad DESC`),

      q(`SELECT TOP 30 nombre,stock_actual,existencia_minima,existencia_maxima
         FROM REPUESTOS WHERE stock_actual<=existencia_minima ORDER BY stock_actual ASC`),

      q(`SELECT TOP 30 r.nombre,r.stock_actual,MAX(mi.fecha_hora) ultimo_movimiento
         FROM REPUESTOS r
         LEFT JOIN MOVIMIENTOS_INVENTARIO mi ON mi.id_repuesto=r.id_repuesto
         GROUP BY r.id_repuesto,r.nombre,r.stock_actual
         HAVING MAX(mi.fecha_hora) IS NULL OR MAX(mi.fecha_hora)<DATEADD(DAY,-30,GETDATE())
         ORDER BY ultimo_movimiento`),

      q(`SELECT p.nombre_empresa proveedor,COUNT(c.id_compra) compras,COALESCE(SUM(c.total),0) total
         FROM PROVEEDORES p
         LEFT JOIN COMPRAS c ON c.id_proveedor=p.id_proveedor AND c.estado<>'ANULADA'
         GROUP BY p.nombre_empresa ORDER BY total DESC`),

      q(`SELECT TOP 15 s.nombre,SUM(d.cantidad) cantidad,SUM(d.subtotal) ingreso
         FROM DETALLE_ORDEN_SERVICIOS d
         INNER JOIN SERVICIOS s ON s.id_servicio=d.id_servicio
         GROUP BY s.nombre ORDER BY ingreso DESC`),

      q(`SELECT TOP 15 r.nombre,SUM(d.cantidad) cantidad,SUM(d.subtotal) ingreso
         FROM DETALLE_ORDEN_REPUESTOS d
         INNER JOIN REPUESTOS r ON r.id_repuesto=d.id_repuesto
         GROUP BY r.nombre ORDER BY ingreso DESC`),

      q(`SELECT f.id_factura,f.numero_consecutivo,c.nombre cliente,f.fecha_hora,f.total,f.estado,
                dbo.FN_SALDO_FACTURA(f.id_factura) saldo
         FROM FACTURAS f
         LEFT JOIN CLIENTES c ON c.id_cliente=f.id_cliente
         WHERE f.estado IN ('PENDIENTE','PARCIAL')
         ORDER BY f.fecha_hora`),

      q(`SELECT TOP 15 r.nombre,SUM(d.cantidad) unidades,
                COALESCE(SUM(d.subtotal),0) venta,
                COALESCE(SUM(d.cantidad*r.precio_compra),0) costo,
                COALESCE(SUM(d.subtotal-d.cantidad*r.precio_compra),0) utilidad
         FROM DETALLE_VENTA d
         INNER JOIN REPUESTOS r ON r.id_repuesto=d.id_repuesto
         GROUP BY r.nombre ORDER BY utilidad DESC`),

      q(`SELECT TOP 20 o.id_orden,
                COALESCE((SELECT SUM(ds.subtotal) FROM DETALLE_ORDEN_SERVICIOS ds WHERE ds.id_orden=o.id_orden),0)
                +COALESCE((SELECT SUM(dr.subtotal) FROM DETALLE_ORDEN_REPUESTOS dr WHERE dr.id_orden=o.id_orden),0) total_orden
         FROM ORDENES_TRABAJO o ORDER BY o.id_orden DESC`),

      q(`SELECT
           SUM(CASE WHEN estado IN ('REGISTRADA','EN_DIAGNOSTICO','ESPERANDO_APROBACION','APROBADA','EN_REPARACION') THEN 1 ELSE 0 END) pendientes,
           SUM(CASE WHEN fecha_estimada_entrega<GETDATE() AND estado NOT IN ('FINALIZADA','FACTURADA','ENTREGADA','CANCELADA') THEN 1 ELSE 0 END) atrasadas,
           SUM(CASE WHEN estado IN ('FINALIZADA','FACTURADA','ENTREGADA') THEN 1 ELSE 0 END) finalizadas
         FROM ORDENES_TRABAJO`)
    ]);

    res.json({
      ventasPeriodo, serviciosTop, ordenesEstado, trabajosPeriodo, trabajosMecanico,
      horasEmpleado, vehiculosMarcaModelo, clientesVisitas, clientesFacturacion,
      ventasVendedor, ventasCategoria, productosVendidos, bajoStock, sinMovimiento,
      comprasProveedor, ingresosServicios, ingresosProductos, facturasPendientes,
      utilidadProductos, utilidadOrdenes, ordenesSituacion: ordenesSituacion[0] || {}
    });
  } catch(e) { next(e); }
});

router.get('/vehiculo/:id', async (req,res,next) => {
  try {
    const r = await query(`
      SELECT * FROM VW_HISTORIAL_VEHICULO
      WHERE id_vehiculo=@id
      ORDER BY fecha_evento DESC
    `, { id:Number(req.params.id) });
    res.json(r.recordset);
  } catch(e) { next(e); }
});

module.exports = router;
