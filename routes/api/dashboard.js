const express = require('express');
const { query } = require('../bd');
const { getUserPermissions } = require('../auth');
const router = express.Router();

router.get('/', async (req,res,next) => {
  try {
    const permissions = await getUserPermissions(req.user.id_usuario);
    const has = code => permissions.some(p => String(p.codigo).toUpperCase() === code);

    const r = await query(`
      SELECT
        (SELECT COUNT(*) FROM VEHICULOS) AS vehiculos,
        (SELECT COUNT(*) FROM ORDENES_TRABAJO WHERE estado NOT IN ('FINALIZADA','FACTURADA','ENTREGADA','CANCELADA')) AS ordenes,
        (SELECT COUNT(*) FROM DIAGNOSTICOS WHERE estado IN ('PENDIENTE','EN_REVISION')) AS diagnosticos,
        (SELECT COUNT(*) FROM COTIZACIONES WHERE estado IN ('ENVIADA','MODIFICADA')) AS cotizaciones,
        (SELECT COUNT(*) FROM REPUESTOS WHERE stock_actual<=existencia_minima) AS inventario_bajo,
        (SELECT COALESCE(SUM(total),0) FROM FACTURAS WHERE estado='PAGADA' AND CAST(fecha_hora AS DATE)=CAST(GETDATE() AS DATE)) AS ventas_hoy,
        (SELECT COALESCE(SUM(dbo.FN_SALDO_FACTURA(id_factura)),0) FROM FACTURAS WHERE estado IN ('PENDIENTE','PARCIAL')) AS por_cobrar,
        (SELECT COALESCE(SUM(total),0) FROM FACTURAS WHERE estado='PAGADA' AND YEAR(fecha_hora)=YEAR(GETDATE()) AND MONTH(fecha_hora)=MONTH(GETDATE())) AS ingresos_mes,
        (SELECT COUNT(*) FROM CITAS WHERE CAST(fecha_hora AS DATE)=CAST(GETDATE() AS DATE) AND estado IN ('PROGRAMADA','CONFIRMADA')) AS citas_hoy
    `);

    const raw = r.recordset[0] || {};
    const stats = {};

    if (has('VEHICULOS_CONSULTAR')) stats.vehiculos = raw.vehiculos;
    if (has('ORDENES_CONSULTAR')) stats.ordenes = raw.ordenes;
    if (has('DIAGNOSTICOS_CONSULTAR')) stats.diagnosticos = raw.diagnosticos;
    if (has('COTIZACIONES_CONSULTAR')) stats.cotizaciones = raw.cotizaciones;
    if (has('INVENTARIO_CONSULTAR')) stats.inventario_bajo = raw.inventario_bajo;
    if (has('FACTURAS_CONSULTAR')) {
      stats.por_cobrar = raw.por_cobrar;
      stats.ingresos_mes = raw.ingresos_mes;
      stats.ventas_hoy = raw.ventas_hoy;
    }
    if (has('CITAS_CONSULTAR')) stats.citas_hoy = raw.citas_hoy;

    let recientes = [];
    if (has('ORDENES_CONSULTAR')) {
      const isMechanic = await query(`
        SELECT TOP 1 e.id_empleado
        FROM EMPLEADOS e
        WHERE e.id_usuario=@id_usuario
      `,{id_usuario:req.user.id_usuario});

      const employeeId = isMechanic.recordset[0]?.id_empleado || null;
      const recentResult = await query(`
        SELECT TOP 8 o.id_orden AS id,o.estado,o.fecha_ingreso,v.placa,c.nombre AS cliente
        FROM ORDENES_TRABAJO o
        INNER JOIN VEHICULOS v ON v.id_vehiculo=o.id_vehiculo
        INNER JOIN CLIENTES c ON c.id_cliente=v.id_cliente
        WHERE @id_empleado IS NULL
           OR o.id_empleado=@id_empleado
           OR EXISTS(SELECT 1 FROM ORDEN_EMPLEADOS oe WHERE oe.id_orden=o.id_orden AND oe.id_empleado=@id_empleado)
        ORDER BY o.fecha_ingreso DESC
      `,{id_empleado:employeeId});
      recientes=recentResult.recordset;
    }

    res.json({ stats, recientes });
  } catch(e){next(e);}
});

module.exports=router;
