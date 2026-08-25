const express=require('express');const {getPool,sql}=require('../../config/db');const router=express.Router();const can=(req,code)=>req.user&&(req.user.permissions.includes(code)||req.user.permissions.includes('ADMIN_TOTAL'));
const allowed={compras:`SELECT TOP 200 c.CompraId,c.NumeroCompra,p.NombreRazonSocial Proveedor,c.NumeroFacturaProveedor,c.Fecha,c.Subtotal,c.Impuestos,c.Descuentos,c.Total,c.FormaPago,c.Estado,u.NombreUsuario Usuario FROM Compras c JOIN Proveedores p ON p.ProveedorId=c.ProveedorId LEFT JOIN Usuarios u ON u.UsuarioId=c.UsuarioId ORDER BY c.CompraId DESC`,ventas:`SELECT TOP 200 v.VentaId,v.NumeroVenta,c.NombreRazonSocial Cliente,ve.NombreCompleto Vendedor,ca.NombreCompleto Cajero,v.FechaHora,v.Subtotal,v.Impuestos,v.Descuentos,v.Total,v.FormaPago,v.Estado FROM Ventas v LEFT JOIN Clientes c ON c.ClienteId=v.ClienteId LEFT JOIN Empleados ve ON ve.EmpleadoId=v.VendedorId LEFT JOIN Empleados ca ON ca.EmpleadoId=v.CajeroId ORDER BY v.VentaId DESC`,pagos:`SELECT TOP 300 p.PagoId,f.NumeroFactura,p.Monto,fp.Nombre FormaPago,p.NumeroReferencia,p.FechaHora,u.NombreUsuario Usuario,p.Observaciones FROM Pagos p JOIN Facturas f ON f.FacturaId=p.FacturaId JOIN FormasPago fp ON fp.FormaPagoId=p.FormaPagoId LEFT JOIN Usuarios u ON u.UsuarioId=p.UsuarioId ORDER BY p.PagoId DESC`,notificaciones:`SELECT TOP 200 NotificacionId,Tipo,Titulo,Mensaje,FechaHora,Leida,Prioridad,ModuloReferencia,RegistroReferenciaId FROM Notificaciones WHERE UsuarioId IS NULL OR UsuarioId IS NOT NULL ORDER BY Leida,FechaHora DESC`,inventario:`SELECT p.ProductoId,p.CodigoInterno,p.Nombre,p.ExistenciaActual,p.ExistenciaMinima,p.ExistenciaMaxima,p.Ubicacion,CASE WHEN p.ExistenciaActual<=p.ExistenciaMinima THEN 1 ELSE 0 END Alerta FROM Productos p WHERE p.Activo=1 ORDER BY Alerta DESC,p.Nombre`,facturas:`SELECT TOP 200 f.FacturaId,f.NumeroFactura,c.NombreRazonSocial Cliente,f.FechaHora,f.Subtotal,f.Impuestos,f.Descuentos,f.Total,f.SaldoPendiente,f.Estado FROM Facturas f LEFT JOIN Clientes c ON c.ClienteId=f.ClienteId ORDER BY f.FacturaId DESC`,auditoria:`SELECT TOP 500 a.AuditoriaId,u.NombreUsuario,a.FechaHora,a.DireccionIP,a.Modulo,a.Accion,a.TipoOperacion,a.RegistroId,a.Descripcion FROM Auditoria a LEFT JOIN Usuarios u ON u.UsuarioId=a.UsuarioId ORDER BY a.AuditoriaId DESC`,movimientos:`SELECT TOP 300 m.MovimientoInventarioId,p.Nombre Producto,m.Cantidad,m.TipoMovimiento,m.FechaHora,u.NombreUsuario,m.DocumentoReferencia,m.ExistenciaAnterior,m.ExistenciaPosterior,m.Observaciones FROM MovimientosInventario m JOIN Productos p ON p.ProductoId=m.ProductoId LEFT JOIN Usuarios u ON u.UsuarioId=m.UsuarioId ORDER BY m.MovimientoInventarioId DESC`};

router.get('/compras-form',async(req,res,next)=>{try{
 if(!can(req,'COMPRAS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const r=await p.request().query(`SELECT ProveedorId,NombreRazonSocial FROM Proveedores WHERE Activo=1 ORDER BY NombreRazonSocial`);
 res.json({ok:true,proveedores:r.recordset});
}catch(e){next(e)}});
router.get('/compras-productos/:proveedorId',async(req,res,next)=>{try{
 if(!can(req,'COMPRAS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const r=await p.request().input('pid',sql.Int,req.params.proveedorId).query(`
   SELECT pr.ProductoId,pr.CodigoInterno,pr.Nombre,
          CAST(COALESCE(pp.CostoReferencia,pr.PrecioCompra) AS DECIMAL(18,2)) PrecioCompra,
          CAST(pr.PorcentajeImpuesto AS DECIMAL(9,4)) PorcentajeImpuesto
   FROM Productos pr
   JOIN ProductoProveedores pp ON pp.ProductoId=pr.ProductoId AND pp.ProveedorId=@pid AND pp.Activo=1
   WHERE pr.Activo=1
   ORDER BY pr.Nombre`);
 res.json({ok:true,productos:r.recordset});
}catch(e){next(e)}});

router.get('/ventas-form',async(req,res,next)=>{try{
 if(!can(req,'VENTAS_CONSULTAR')&&!can(req,'VENTAS_REGISTRAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const clientes=(await p.request().query(`
   SELECT ClienteId,NombreRazonSocial,Identificacion
   FROM Clientes
   WHERE Activo=1
   ORDER BY NombreRazonSocial`)).recordset;
 const vendedores=(await p.request().query(`
   SELECT DISTINCT e.EmpleadoId,e.NombreCompleto
   FROM Empleados e
   JOIN Usuarios u ON u.UsuarioId=e.UsuarioId AND u.Activo=1
   JOIN UsuarioRoles ur ON ur.UsuarioId=u.UsuarioId AND ur.Activo=1
   JOIN Roles r ON r.RolId=ur.RolId AND r.Activo=1
   JOIN RolPermisos rp ON rp.RolId=r.RolId
   JOIN Permisos pe ON pe.PermisoId=rp.PermisoId AND pe.Activo=1
   WHERE e.EstadoLaboral=N'ACTIVO'
     AND pe.Codigo IN(N'VENTAS_REGISTRAR',N'ADMIN_TOTAL')
   ORDER BY e.NombreCompleto`)).recordset;
 const cajeros=(await p.request().query(`
   SELECT DISTINCT e.EmpleadoId,e.NombreCompleto
   FROM Empleados e
   JOIN Usuarios u ON u.UsuarioId=e.UsuarioId AND u.Activo=1
   JOIN UsuarioRoles ur ON ur.UsuarioId=u.UsuarioId AND ur.Activo=1
   JOIN Roles r ON r.RolId=ur.RolId AND r.Activo=1
   JOIN RolPermisos rp ON rp.RolId=r.RolId
   JOIN Permisos pe ON pe.PermisoId=rp.PermisoId AND pe.Activo=1
   WHERE e.EstadoLaboral=N'ACTIVO'
     AND pe.Codigo IN(N'PAGOS_REGISTRAR',N'FACTURAS_REGISTRAR',N'ADMIN_TOTAL')
   ORDER BY e.NombreCompleto`)).recordset;
 const productos=(await p.request().query(`
   SELECT ProductoId,CodigoInterno,Nombre,TipoProducto,
          CAST(PrecioVenta AS DECIMAL(18,2)) PrecioVenta,
          CAST(PorcentajeImpuesto AS DECIMAL(9,4)) PorcentajeImpuesto,
          CAST(ExistenciaActual AS DECIMAL(18,2)) ExistenciaActual
   FROM Productos
   WHERE Activo=1
   ORDER BY Nombre`)).recordset;
 res.json({ok:true,clientes,vendedores,cajeros,productos});
}catch(e){next(e)}});


router.get('/pagos-form',async(req,res,next)=>{try{
 if(!can(req,'PAGOS_CONSULTAR')&&!can(req,'PAGOS_REGISTRAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const facturas=(await p.request().query(`
   SELECT f.FacturaId,f.NumeroFactura,COALESCE(c.NombreRazonSocial,N'Consumidor final') Cliente,
          CAST(f.Total AS DECIMAL(18,2)) Total,CAST(f.SaldoPendiente AS DECIMAL(18,2)) SaldoPendiente,f.Estado,
          f.NumeroFactura+N' — '+COALESCE(c.NombreRazonSocial,N'Consumidor final')+N' — Saldo ₡'+CONVERT(NVARCHAR(40),CAST(f.SaldoPendiente AS MONEY),1) Etiqueta
   FROM Facturas f
   LEFT JOIN Clientes c ON c.ClienteId=f.ClienteId
   WHERE f.Estado IN(N'PENDIENTE',N'PARCIALMENTE PAGADA') AND f.SaldoPendiente>0
   ORDER BY f.FacturaId DESC`)).recordset;
 const formas=(await p.request().query(`
   SELECT FormaPagoId,Nombre,RequiereReferencia
   FROM FormasPago
   WHERE Activa=1
   ORDER BY CASE Nombre WHEN N'EFECTIVO' THEN 1 WHEN N'TARJETA' THEN 2 WHEN N'TRANSFERENCIA' THEN 3 WHEN N'SINPE MOVIL' THEN 4 WHEN N'CREDITO' THEN 5 ELSE 99 END,Nombre`)).recordset;
 res.json({ok:true,facturas,formas});
}catch(e){next(e)}});

router.get('/facturacion-form',async(req,res,next)=>{try{
 if(!can(req,'FACTURAS_CONSULTAR')&&!can(req,'FACTURAS_REGISTRAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const ordenes=(await p.request().query(`
   SELECT o.OrdenTrabajoId,o.NumeroOrden,c.NombreRazonSocial Cliente,v.Placa,
          ma.Nombre+N' '+mo.Nombre Vehiculo,
          o.FechaFinalizacion,
          o.NumeroOrden+N' — '+v.Placa+N' — '+c.NombreRazonSocial Etiqueta
   FROM OrdenesTrabajo o
   JOIN Clientes c ON c.ClienteId=o.ClienteId
   JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
   JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId
   JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId
   WHERE o.Estado=N'FINALIZADA'
     AND NOT EXISTS(SELECT 1 FROM Facturas f WHERE f.OrdenTrabajoId=o.OrdenTrabajoId)
   ORDER BY o.OrdenTrabajoId DESC`)).recordset;
 const ventas=(await p.request().query(`
   SELECT v.VentaId,v.NumeroVenta,COALESCE(c.NombreRazonSocial,N'Consumidor final') Cliente,
          v.FechaHora,v.Total,
          v.NumeroVenta+N' — '+COALESCE(c.NombreRazonSocial,N'Consumidor final')+N' — ₡'+CONVERT(NVARCHAR(40),CAST(v.Total AS MONEY),1) Etiqueta
   FROM Ventas v
   LEFT JOIN Clientes c ON c.ClienteId=v.ClienteId
   WHERE v.Estado=N'CONFIRMADA'
     AND NOT EXISTS(SELECT 1 FROM Facturas f WHERE f.VentaId=v.VentaId)
   ORDER BY v.VentaId DESC`)).recordset;
 res.json({ok:true,ordenes,ventas});
}catch(e){next(e)}});

router.get('/facturacion-detalle/:tipo/:id',async(req,res,next)=>{try{
 if(!can(req,'FACTURAS_CONSULTAR')&&!can(req,'FACTURAS_REGISTRAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const tipo=String(req.params.tipo||'').toLowerCase();
 if(tipo==='orden'){
   const rs=await p.request().input('id',sql.Int,req.params.id).query(`
     SELECT o.OrdenTrabajoId,o.NumeroOrden,o.Estado,c.NombreRazonSocial Cliente,c.Identificacion,
            v.Placa,ma.Nombre+N' '+mo.Nombre Vehiculo,o.FechaFinalizacion,o.FechaEstimadaEntrega
     FROM OrdenesTrabajo o
     JOIN Clientes c ON c.ClienteId=o.ClienteId
     JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
     JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId
     JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId
     WHERE o.OrdenTrabajoId=@id;
     SELECT N'SERVICIO' Tipo,s.Nombre Descripcion,os.Cantidad,os.PrecioAplicado PrecioUnitario,
            os.DescuentoAplicado Descuento,
            (os.Cantidad*os.PrecioAplicado-os.DescuentoAplicado)*os.ImpuestoPorcentaje/100.0 Impuesto,
            (os.Cantidad*os.PrecioAplicado-os.DescuentoAplicado)*(1+os.ImpuestoPorcentaje/100.0) TotalLinea
     FROM OrdenServicios os JOIN Servicios s ON s.ServicioId=os.ServicioId WHERE os.OrdenTrabajoId=@id;
     SELECT N'PRODUCTO' Tipo,p.Nombre Descripcion,op.CantidadUtilizada Cantidad,op.PrecioAplicado PrecioUnitario,
            op.DescuentoAplicado Descuento,
            (op.CantidadUtilizada*op.PrecioAplicado-op.DescuentoAplicado)*op.ImpuestoPorcentaje/100.0 Impuesto,
            (op.CantidadUtilizada*op.PrecioAplicado-op.DescuentoAplicado)*(1+op.ImpuestoPorcentaje/100.0) TotalLinea
     FROM OrdenProductos op JOIN Productos p ON p.ProductoId=op.ProductoId WHERE op.OrdenTrabajoId=@id AND op.CantidadUtilizada>0;
     SELECT N'MANO DE OBRA' Tipo,N'Mano de obra - '+e.NombreCompleto Descripcion,oe.HorasTrabajadas Cantidad,
            oe.CostoHora PrecioUnitario,CAST(0 AS DECIMAL(18,2)) Descuento,CAST(0 AS DECIMAL(18,2)) Impuesto,
            oe.HorasTrabajadas*oe.CostoHora TotalLinea
     FROM OrdenEmpleados oe JOIN Empleados e ON e.EmpleadoId=oe.EmpleadoId WHERE oe.OrdenTrabajoId=@id AND oe.HorasTrabajadas>0;`);
   const h=rs.recordsets[0][0];if(!h)return res.status(404).json({ok:false,message:'Orden no encontrada.'});
   if(h.Estado!=='FINALIZADA')return res.status(409).json({ok:false,message:'Solo se pueden facturar órdenes finalizadas.'});
   const detalles=[...rs.recordsets[1],...rs.recordsets[2],...rs.recordsets[3]];
   return res.json({ok:true,tipo:'ORDEN',cabecera:h,detalles});
 }
 if(tipo==='venta'){
   const rs=await p.request().input('id',sql.Int,req.params.id).query(`
     SELECT v.VentaId,v.NumeroVenta,v.Estado,COALESCE(c.NombreRazonSocial,N'Consumidor final') Cliente,
            c.Identificacion,v.FechaHora,v.FormaPago,v.Subtotal,v.Impuestos,v.Descuentos,v.Total
     FROM Ventas v LEFT JOIN Clientes c ON c.ClienteId=v.ClienteId WHERE v.VentaId=@id;
     SELECT N'PRODUCTO' Tipo,p.Nombre Descripcion,vd.Cantidad,vd.PrecioUnitario,vd.Descuento,
            (vd.Cantidad*vd.PrecioUnitario-vd.Descuento)*vd.ImpuestoPorcentaje/100.0 Impuesto,vd.TotalLinea
     FROM VentaDetalles vd JOIN Productos p ON p.ProductoId=vd.ProductoId WHERE vd.VentaId=@id;`);
   const h=rs.recordsets[0][0];if(!h)return res.status(404).json({ok:false,message:'Venta no encontrada.'});
   if(h.Estado!=='CONFIRMADA')return res.status(409).json({ok:false,message:'Solo se pueden facturar ventas confirmadas.'});
   return res.json({ok:true,tipo:'VENTA',cabecera:h,detalles:rs.recordsets[1]});
 }
 res.status(400).json({ok:false,message:'Tipo de origen inválido.'});
}catch(e){next(e)}});

router.get('/reportes-form',async(req,res,next)=>{try{
 if(!can(req,'REPORTES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const rs=await p.request().query(`
   SELECT ClienteId,NombreRazonSocial Nombre FROM Clientes WHERE Activo=1 ORDER BY NombreRazonSocial;
   SELECT EmpleadoId,NombreCompleto Nombre FROM Empleados WHERE EstadoLaboral=N'ACTIVO' ORDER BY NombreCompleto;
   SELECT ProductoId,CodigoInterno,Nombre,TipoProducto FROM Productos WHERE Activo=1 ORDER BY Nombre;
   SELECT ServicioId,Codigo,Nombre FROM Servicios WHERE Activo=1 ORDER BY Nombre;
   SELECT v.VehiculoId,v.Placa,ma.Nombre Marca,mo.Nombre Modelo,c.NombreRazonSocial Cliente
     FROM Vehiculos v JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId
     JOIN Clientes c ON c.ClienteId=v.ClienteId WHERE v.Activo=1 ORDER BY v.Placa;
   SELECT ProveedorId,NombreRazonSocial Nombre FROM Proveedores WHERE Activo=1 ORDER BY NombreRazonSocial;
 `);
 res.json({ok:true,clientes:rs.recordsets[0],empleados:rs.recordsets[1],productos:rs.recordsets[2],servicios:rs.recordsets[3],vehiculos:rs.recordsets[4],proveedores:rs.recordsets[5]});
}catch(e){next(e)}});

router.get('/reportes/:tipo',async(req,res,next)=>{try{
 if(!can(req,'REPORTES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const reports={
  trabajos:`SELECT o.NumeroOrden,o.FechaApertura,o.Estado,c.NombreRazonSocial Cliente,v.Placa
    FROM OrdenesTrabajo o JOIN Clientes c ON c.ClienteId=o.ClienteId JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
    WHERE CAST(o.FechaApertura AS date) BETWEEN @d AND @h AND (@estado='' OR o.Estado=@estado)
      AND (@cliente=0 OR o.ClienteId=@cliente) AND (@vehiculo=0 OR o.VehiculoId=@vehiculo)
    ORDER BY o.FechaApertura DESC`,
  trabajos_mecanico:`SELECT e.NombreCompleto Mecanico,COUNT(DISTINCT oe.OrdenTrabajoId) Trabajos,SUM(ISNULL(oe.HorasTrabajadas,0)) Horas
    FROM OrdenEmpleados oe JOIN Empleados e ON e.EmpleadoId=oe.EmpleadoId JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=oe.OrdenTrabajoId
    WHERE CAST(o.FechaApertura AS date) BETWEEN @d AND @h AND (@empleado=0 OR e.EmpleadoId=@empleado)
      AND (@estado='' OR o.Estado=@estado) AND (@cliente=0 OR o.ClienteId=@cliente)
    GROUP BY e.NombreCompleto ORDER BY Trabajos DESC`,
  horas_empleado:`SELECT e.NombreCompleto Empleado,SUM(ISNULL(oe.HorasTrabajadas,0)) Horas,SUM(ISNULL(oe.HorasTrabajadas,0)*ISNULL(oe.CostoHora,0)) CostoManoObra
    FROM OrdenEmpleados oe JOIN Empleados e ON e.EmpleadoId=oe.EmpleadoId JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=oe.OrdenTrabajoId
    WHERE CAST(oe.FechaInicio AS date) BETWEEN @d AND @h AND (@empleado=0 OR e.EmpleadoId=@empleado)
    GROUP BY e.NombreCompleto ORDER BY Horas DESC`,
  servicios:`SELECT s.Nombre Servicio,COUNT(DISTINCT os.OrdenTrabajoId) Ordenes,SUM(os.Cantidad) Cantidad,SUM(os.PrecioAplicado*os.Cantidad-os.DescuentoAplicado) Ingreso
    FROM OrdenServicios os JOIN Servicios s ON s.ServicioId=os.ServicioId JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=os.OrdenTrabajoId
    WHERE CAST(o.FechaApertura AS date) BETWEEN @d AND @h AND (@servicio=0 OR s.ServicioId=@servicio)
      AND (@estado='' OR o.Estado=@estado)
    GROUP BY s.Nombre ORDER BY Cantidad DESC`,
  vehiculos:`SELECT ma.Nombre Marca,mo.Nombre Modelo,COUNT(DISTINCT o.OrdenTrabajoId) Atenciones
    FROM OrdenesTrabajo o JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId
    WHERE CAST(o.FechaApertura AS date) BETWEEN @d AND @h AND (@vehiculo=0 OR v.VehiculoId=@vehiculo)
      AND (@estado='' OR o.Estado=@estado)
    GROUP BY ma.Nombre,mo.Nombre ORDER BY Atenciones DESC`,
  clientes_visitas:`SELECT c.NombreRazonSocial Cliente,COUNT(DISTINCT r.RecepcionId) Visitas
    FROM Clientes c JOIN Recepciones r ON r.ClienteId=c.ClienteId
    WHERE CAST(r.FechaHoraIngreso AS date) BETWEEN @d AND @h AND (@cliente=0 OR c.ClienteId=@cliente)
    GROUP BY c.NombreRazonSocial ORDER BY Visitas DESC`,
  clientes_facturacion:`SELECT c.NombreRazonSocial Cliente,COUNT(DISTINCT f.FacturaId) Facturas,SUM(f.Total) Facturacion,SUM(f.SaldoPendiente) SaldoPendiente
    FROM Clientes c JOIN Facturas f ON f.ClienteId=c.ClienteId
    WHERE f.Estado<>N'ANULADA' AND CAST(f.FechaHora AS date) BETWEEN @d AND @h AND (@cliente=0 OR c.ClienteId=@cliente)
      AND (@estado='' OR f.Estado=@estado)
    GROUP BY c.NombreRazonSocial ORDER BY Facturacion DESC`,
  ventas:`SELECT CAST(v.FechaHora AS date) Fecha,COUNT(*) Ventas,SUM(v.Total) Total
    FROM Ventas v WHERE CAST(v.FechaHora AS date) BETWEEN @d AND @h AND (@estado='' OR v.Estado=@estado)
      AND (@cliente=0 OR v.ClienteId=@cliente)
    GROUP BY CAST(v.FechaHora AS date) ORDER BY Fecha`,
  ventas_vendedor:`SELECT COALESCE(e.NombreCompleto,N'Sin vendedor') Vendedor,COUNT(v.VentaId) Ventas,SUM(v.Total) Total
    FROM Ventas v LEFT JOIN Empleados e ON e.EmpleadoId=v.VendedorId
    WHERE CAST(v.FechaHora AS date) BETWEEN @d AND @h AND (@empleado=0 OR v.VendedorId=@empleado) AND (@estado='' OR v.Estado=@estado)
    GROUP BY e.NombreCompleto ORDER BY Total DESC`,
  ventas_categoria:`SELECT p.Categoria,SUM(vd.Cantidad) Unidades,SUM(vd.TotalLinea) Total
    FROM VentaDetalles vd JOIN Ventas v ON v.VentaId=vd.VentaId JOIN Productos p ON p.ProductoId=vd.ProductoId
    WHERE CAST(v.FechaHora AS date) BETWEEN @d AND @h AND v.Estado<>N'ANULADA' AND (@producto=0 OR p.ProductoId=@producto)
    GROUP BY p.Categoria ORDER BY Total DESC`,
  productos_vendidos:`SELECT p.CodigoInterno,p.Nombre Producto,SUM(vd.Cantidad) Cantidad,SUM(vd.TotalLinea) Total
    FROM VentaDetalles vd JOIN Ventas v ON v.VentaId=vd.VentaId JOIN Productos p ON p.ProductoId=vd.ProductoId
    WHERE v.Estado<>N'ANULADA' AND CAST(v.FechaHora AS date) BETWEEN @d AND @h AND (@producto=0 OR p.ProductoId=@producto)
    GROUP BY p.CodigoInterno,p.Nombre ORDER BY Cantidad DESC`,
  stock:`SELECT CodigoInterno,Nombre,TipoProducto,ExistenciaActual,ExistenciaMinima,(ExistenciaMinima-ExistenciaActual) Faltante,Ubicacion
    FROM Productos WHERE Activo=1 AND ExistenciaActual<=ExistenciaMinima AND (@producto=0 OR ProductoId=@producto)
    ORDER BY ExistenciaActual`,
  sin_movimiento:`SELECT p.CodigoInterno,p.Nombre,p.TipoProducto,p.ExistenciaActual,MAX(m.FechaHora) UltimoMovimiento
    FROM Productos p LEFT JOIN MovimientosInventario m ON m.ProductoId=p.ProductoId
    WHERE p.Activo=1 AND (@producto=0 OR p.ProductoId=@producto)
    GROUP BY p.ProductoId,p.CodigoInterno,p.Nombre,p.TipoProducto,p.ExistenciaActual
    HAVING MAX(m.FechaHora) IS NULL OR MAX(m.FechaHora)<@d ORDER BY UltimoMovimiento`,
  compras:`SELECT p.NombreRazonSocial Proveedor,COUNT(*) Compras,SUM(c.Subtotal) Subtotal,SUM(c.Impuestos) Impuestos,SUM(c.Total) Total
    FROM Compras c JOIN Proveedores p ON p.ProveedorId=c.ProveedorId
    WHERE c.Estado<>N'ANULADA' AND CAST(c.Fecha AS date) BETWEEN @d AND @h AND (@proveedor=0 OR c.ProveedorId=@proveedor)
      AND (@estado='' OR c.Estado=@estado)
    GROUP BY p.NombreRazonSocial ORDER BY Total DESC`,
  ingresos_servicios:`SELECT s.Nombre Servicio,SUM(fd.Cantidad) Cantidad,SUM(fd.TotalLinea) Ingreso
    FROM FacturaDetalles fd JOIN Facturas f ON f.FacturaId=fd.FacturaId LEFT JOIN Servicios s ON s.ServicioId=fd.ServicioId
    WHERE fd.TipoDetalle=N'SERVICIO' AND f.Estado<>N'ANULADA' AND CAST(f.FechaHora AS date) BETWEEN @d AND @h
      AND (@servicio=0 OR fd.ServicioId=@servicio) AND (@cliente=0 OR f.ClienteId=@cliente)
    GROUP BY s.Nombre ORDER BY Ingreso DESC`,
  ingresos_productos:`SELECT p.Nombre Producto,SUM(fd.Cantidad) Cantidad,SUM(fd.TotalLinea) Ingreso
    FROM FacturaDetalles fd JOIN Facturas f ON f.FacturaId=fd.FacturaId LEFT JOIN Productos p ON p.ProductoId=fd.ProductoId
    WHERE fd.TipoDetalle=N'PRODUCTO' AND f.Estado<>N'ANULADA' AND CAST(f.FechaHora AS date) BETWEEN @d AND @h
      AND (@producto=0 OR fd.ProductoId=@producto) AND (@cliente=0 OR f.ClienteId=@cliente)
    GROUP BY p.Nombre ORDER BY Ingreso DESC`,
  pendientes:`SELECT f.NumeroFactura,COALESCE(c.NombreRazonSocial,N'Consumidor final') Cliente,f.FechaHora,f.Total,f.SaldoPendiente,f.Estado,
      DATEDIFF(DAY,CAST(f.FechaHora AS date),CAST(SYSDATETIME() AS date)) DiasPendiente
    FROM Facturas f LEFT JOIN Clientes c ON c.ClienteId=f.ClienteId
    WHERE f.SaldoPendiente>0 AND f.Estado NOT IN(N'ANULADA',N'REEMBOLSADA') AND CAST(f.FechaHora AS date) BETWEEN @d AND @h
      AND (@cliente=0 OR f.ClienteId=@cliente) AND (@estado='' OR f.Estado=@estado)
    ORDER BY f.FechaHora`,
  utilidad_producto:`SELECT p.CodigoInterno,p.Nombre Producto,SUM(vd.Cantidad) Unidades,SUM(vd.TotalLinea) Ingreso,
      SUM(vd.Cantidad*vd.CostoUnitarioHistorico) Costo,
      SUM(vd.TotalLinea-vd.Cantidad*vd.CostoUnitarioHistorico) UtilidadEstimada
    FROM VentaDetalles vd JOIN Ventas v ON v.VentaId=vd.VentaId JOIN Productos p ON p.ProductoId=vd.ProductoId
    WHERE v.Estado<>N'ANULADA' AND CAST(v.FechaHora AS date) BETWEEN @d AND @h AND (@producto=0 OR p.ProductoId=@producto)
    GROUP BY p.CodigoInterno,p.Nombre ORDER BY UtilidadEstimada DESC`,
  utilidad_orden:`SELECT o.NumeroOrden,c.NombreRazonSocial Cliente,v.Placa,
      ISNULL((SELECT SUM(os.PrecioAplicado*os.Cantidad-os.DescuentoAplicado) FROM OrdenServicios os WHERE os.OrdenTrabajoId=o.OrdenTrabajoId),0)
      +ISNULL((SELECT SUM(op.PrecioAplicado*op.CantidadUtilizada-op.DescuentoAplicado) FROM OrdenProductos op WHERE op.OrdenTrabajoId=o.OrdenTrabajoId),0)
      +ISNULL((SELECT SUM(oe.HorasTrabajadas*oe.CostoHora) FROM OrdenEmpleados oe WHERE oe.OrdenTrabajoId=o.OrdenTrabajoId),0) IngresoEstimado,
      ISNULL((SELECT SUM(op.CostoAplicado*op.CantidadUtilizada) FROM OrdenProductos op WHERE op.OrdenTrabajoId=o.OrdenTrabajoId),0)
      +ISNULL((SELECT SUM(oe.HorasTrabajadas*oe.CostoHora) FROM OrdenEmpleados oe WHERE oe.OrdenTrabajoId=o.OrdenTrabajoId),0) CostoEstimado,
      (ISNULL((SELECT SUM(os.PrecioAplicado*os.Cantidad-os.DescuentoAplicado) FROM OrdenServicios os WHERE os.OrdenTrabajoId=o.OrdenTrabajoId),0)
      +ISNULL((SELECT SUM(op.PrecioAplicado*op.CantidadUtilizada-op.DescuentoAplicado) FROM OrdenProductos op WHERE op.OrdenTrabajoId=o.OrdenTrabajoId),0))
      -ISNULL((SELECT SUM(op.CostoAplicado*op.CantidadUtilizada) FROM OrdenProductos op WHERE op.OrdenTrabajoId=o.OrdenTrabajoId),0) UtilidadEstimada
    FROM OrdenesTrabajo o JOIN Clientes c ON c.ClienteId=o.ClienteId JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
    WHERE CAST(o.FechaApertura AS date) BETWEEN @d AND @h AND (@cliente=0 OR o.ClienteId=@cliente) AND (@vehiculo=0 OR o.VehiculoId=@vehiculo)
      AND (@estado='' OR o.Estado=@estado) ORDER BY UtilidadEstimada DESC`,
  ordenes_estado:`SELECT o.NumeroOrden,o.FechaApertura,o.FechaEstimadaEntrega,o.Estado,c.NombreRazonSocial Cliente,v.Placa,
      CASE WHEN o.FechaEstimadaEntrega<SYSDATETIME() AND o.Estado NOT IN(N'FINALIZADA',N'FACTURADA',N'ENTREGADA',N'CANCELADA') THEN N'ATRASADA'
           WHEN o.Estado IN(N'FINALIZADA',N'FACTURADA',N'ENTREGADA') THEN N'FINALIZADA' ELSE N'PENDIENTE' END Situacion
    FROM OrdenesTrabajo o JOIN Clientes c ON c.ClienteId=o.ClienteId JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
    WHERE CAST(o.FechaApertura AS date) BETWEEN @d AND @h AND (@estado='' OR o.Estado=@estado)
      AND (@cliente=0 OR o.ClienteId=@cliente) AND (@vehiculo=0 OR o.VehiculoId=@vehiculo)
    ORDER BY o.FechaApertura DESC`,
  historial_vehiculo:`
    SELECT Fecha,Tipo,Documento,Estado,Detalle,Kilometraje FROM (
      SELECT r.FechaHoraIngreso Fecha,N'RECEPCION' Tipo,r.NumeroRecepcion Documento,r.Estado,
             CONCAT(r.MotivoVisita,CASE WHEN r.ProblemaCliente IS NULL THEN N'' ELSE N' - '+r.ProblemaCliente END) Detalle,r.KilometrajeIngreso Kilometraje
      FROM Recepciones r WHERE (@vehiculo=0 OR r.VehiculoId=@vehiculo)
      UNION ALL
      SELECT d.FechaHoraDiagnostico,N'DIAGNOSTICO',d.NumeroDiagnostico,d.Estado,ISNULL(d.ProblemasEncontrados,N'Sin detalle'),NULL
      FROM Diagnosticos d JOIN Recepciones r ON r.RecepcionId=d.RecepcionId WHERE (@vehiculo=0 OR r.VehiculoId=@vehiculo)
      UNION ALL
      SELECT o.FechaApertura,N'ORDEN',o.NumeroOrden,o.Estado,ISNULL(o.Observaciones,N'Orden de trabajo'),NULL
      FROM OrdenesTrabajo o WHERE (@vehiculo=0 OR o.VehiculoId=@vehiculo)
      UNION ALL
      SELECT o.FechaApertura,N'SERVICIO',o.NumeroOrden,o.Estado,s.Nombre,NULL
      FROM OrdenServicios os JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=os.OrdenTrabajoId JOIN Servicios s ON s.ServicioId=os.ServicioId
      WHERE (@vehiculo=0 OR o.VehiculoId=@vehiculo) AND (@servicio=0 OR s.ServicioId=@servicio)
      UNION ALL
      SELECT o.FechaApertura,N'REPUESTO',o.NumeroOrden,o.Estado,CONCAT(p.Nombre,N' x ',op.CantidadUtilizada),NULL
      FROM OrdenProductos op JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=op.OrdenTrabajoId JOIN Productos p ON p.ProductoId=op.ProductoId
      WHERE (@vehiculo=0 OR o.VehiculoId=@vehiculo) AND (@producto=0 OR p.ProductoId=@producto)
      UNION ALL
      SELECT f.FechaHora,N'FACTURA',f.NumeroFactura,f.Estado,CONCAT(N'Total: ',CONVERT(NVARCHAR(30),f.Total),N' | Saldo: ',CONVERT(NVARCHAR(30),f.SaldoPendiente)),NULL
      FROM Facturas f JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=f.OrdenTrabajoId WHERE (@vehiculo=0 OR o.VehiculoId=@vehiculo)
      UNION ALL
      SELECT e.FechaHoraEntrega,N'ENTREGA',o.NumeroOrden,N'ENTREGADA',ISNULL(e.ObservacionesFinales,N'Vehículo entregado'),e.KilometrajeSalida
      FROM EntregasVehiculo e JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=e.OrdenTrabajoId WHERE (@vehiculo=0 OR o.VehiculoId=@vehiculo)
    ) hst WHERE CAST(Fecha AS date) BETWEEN @d AND @h ORDER BY Fecha DESC`
 };
 const q=reports[req.params.tipo];
 if(!q)return res.status(404).json({ok:false,message:'Reporte no existe'});
 const p=await getPool();
 const r=await p.request()
  .input('d',sql.Date,req.query.desde||'2000-01-01').input('h',sql.Date,req.query.hasta||'2099-12-31')
  .input('estado',sql.NVarChar(40),req.query.estado||'').input('cliente',sql.Int,Number(req.query.clienteId||0))
  .input('empleado',sql.Int,Number(req.query.empleadoId||0)).input('producto',sql.Int,Number(req.query.productoId||0))
  .input('servicio',sql.Int,Number(req.query.servicioId||0)).input('vehiculo',sql.Int,Number(req.query.vehiculoId||0))
  .input('proveedor',sql.Int,Number(req.query.proveedorId||0)).query(q);
 res.json({ok:true,rows:r.recordset,generadoEn:new Date().toISOString()});
}catch(e){next(e)}});

router.get('/vehiculos-form',async(req,res,next)=>{try{if(!can(req,'VEHICULOS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const rs=await p.request().query(`
SELECT ClienteId,NombreRazonSocial Nombre FROM Clientes WHERE Activo=1 ORDER BY NombreRazonSocial;
SELECT mo.ModeloId,ma.Nombre+N' '+mo.Nombre NombreCompleto FROM ModelosVehiculo mo JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId WHERE mo.Activo=1 AND ma.Activo=1 ORDER BY ma.Nombre,mo.Nombre;
SELECT TipoVehiculoId,Nombre FROM TiposVehiculo WHERE Activo=1 ORDER BY Nombre;
SELECT TipoCombustibleId,Nombre FROM TiposCombustible WHERE Activo=1 ORDER BY Nombre;
SELECT CategoriaVehiculoId,Nombre FROM CategoriasVehiculo WHERE Activo=1 ORDER BY Nombre;`);res.json({ok:true,clientes:rs.recordsets[0],modelos:rs.recordsets[1],tipos:rs.recordsets[2],combustibles:rs.recordsets[3],categorias:rs.recordsets[4]});}catch(e){next(e)}});
router.get('/vehiculos-list',async(req,res,next)=>{try{if(!can(req,'VEHICULOS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().input('q',sql.NVarChar(200),'%'+(req.query.q||'')+'%').query(`SELECT TOP 300 v.VehiculoId,c.NombreRazonSocial Cliente,v.Placa,v.VIN,ma.Nombre+N' '+mo.Nombre MarcaModelo,tv.Nombre TipoVehiculo,tc.Nombre Combustible,cv.Nombre Categoria,v.Anio,v.KilometrajeActual,v.Activo FROM Vehiculos v JOIN Clientes c ON c.ClienteId=v.ClienteId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId JOIN TiposVehiculo tv ON tv.TipoVehiculoId=v.TipoVehiculoId JOIN TiposCombustible tc ON tc.TipoCombustibleId=v.TipoCombustibleId LEFT JOIN CategoriasVehiculo cv ON cv.CategoriaVehiculoId=v.CategoriaVehiculoId WHERE v.Placa LIKE @q OR v.VIN LIKE @q OR c.NombreRazonSocial LIKE @q OR ma.Nombre LIKE @q OR mo.Nombre LIKE @q ORDER BY v.VehiculoId DESC`);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});
router.get('/vehiculos-cliente/:clienteId',async(req,res,next)=>{try{if(!can(req,'VEHICULOS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().input('id',sql.Int,req.params.clienteId).query(`SELECT v.VehiculoId,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre Etiqueta FROM Vehiculos v JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId WHERE v.ClienteId=@id AND v.Activo=1 ORDER BY v.Placa`);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});
router.get('/recepciones-form',async(req,res,next)=>{try{if(!can(req,'RECEPCIONES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const rs=await p.request().query(`
SELECT ClienteId,NombreRazonSocial Nombre FROM Clientes WHERE Activo=1 ORDER BY NombreRazonSocial;
SELECT DISTINCT e.EmpleadoId,e.NombreCompleto,
       e.NombreCompleto + CASE WHEN NULLIF(e.Especialidad,N'') IS NOT NULL THEN N' — '+e.Especialidad ELSE N'' END Etiqueta
FROM Empleados e
JOIN Usuarios u ON u.UsuarioId=e.UsuarioId AND u.Activo=1
WHERE e.EstadoLaboral=N'ACTIVO' AND EXISTS(
  SELECT 1 FROM UsuarioRoles ur
  JOIN Roles r ON r.RolId=ur.RolId AND r.Activo=1
  JOIN RolPermisos rp ON rp.RolId=r.RolId
  JOIN Permisos pe ON pe.PermisoId=rp.PermisoId AND pe.Activo=1
  WHERE ur.UsuarioId=u.UsuarioId AND ur.Activo=1 AND pe.Codigo IN('RECEPCIONES_REGISTRAR','ADMIN_TOTAL')
)
ORDER BY e.NombreCompleto;`);res.json({ok:true,clientes:rs.recordsets[0],empleados:rs.recordsets[1]});}catch(e){next(e)}});
router.get('/recepciones-list',async(req,res,next)=>{try{if(!can(req,'RECEPCIONES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().input('q',sql.NVarChar(200),'%'+(req.query.q||'')+'%').query(`SELECT TOP 300 r.RecepcionId,r.NumeroRecepcion,c.NombreRazonSocial Cliente,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre Vehiculo,r.FechaHoraIngreso,r.KilometrajeIngreso,r.NivelCombustible,r.MotivoVisita,r.ProblemaCliente,r.AccesoriosObjetos,r.DanosVisibles,e.NombreCompleto EmpleadoRecibe,r.Observaciones FROM Recepciones r JOIN Clientes c ON c.ClienteId=r.ClienteId JOIN Vehiculos v ON v.VehiculoId=r.VehiculoId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId JOIN Empleados e ON e.EmpleadoId=r.EmpleadoRecibeId WHERE r.NumeroRecepcion LIKE @q OR c.NombreRazonSocial LIKE @q OR v.Placa LIKE @q OR r.MotivoVisita LIKE @q OR e.NombreCompleto LIKE @q OR ISNULL(r.ProblemaCliente,N'') LIKE @q ORDER BY r.RecepcionId DESC`);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});
router.get('/citas-form',async(req,res,next)=>{try{if(!can(req,'CITAS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const rs=await p.request().query(`SELECT ClienteId,NombreRazonSocial Nombre FROM Clientes WHERE Activo=1 ORDER BY NombreRazonSocial;SELECT ServicioId,Nombre,TiempoEstimadoMinutos,PrecioBase FROM Servicios WHERE Activo=1 ORDER BY Nombre;SELECT DISTINCT e.EmpleadoId,e.NombreCompleto,e.Especialidad FROM Empleados e JOIN Usuarios u ON u.UsuarioId=e.UsuarioId JOIN UsuarioRoles ur ON ur.UsuarioId=u.UsuarioId AND ur.Activo=1 JOIN Roles r ON r.RolId=ur.RolId AND r.Activo=1 WHERE e.EstadoLaboral=N'ACTIVO' AND u.Activo=1 AND r.Nombre=N'Mecánico' ORDER BY e.NombreCompleto;SELECT AreaTrabajoId,Nombre FROM AreasTrabajo WHERE Activa=1 ORDER BY Nombre;`);res.json({ok:true,clientes:rs.recordsets[0],servicios:rs.recordsets[1],mecanicos:rs.recordsets[2],areas:rs.recordsets[3]});}catch(e){next(e)}});
router.get('/citas-list',async(req,res,next)=>{try{if(!can(req,'CITAS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().input('q',sql.NVarChar(200),'%'+(req.query.q||'')+'%').query(`SELECT TOP 300 c.CitaId,cl.NombreRazonSocial Cliente,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre Vehiculo,a.Nombre AreaTrabajo,c.FechaHoraInicio,c.DuracionEstimadaMinutos,c.Observaciones,(SELECT STRING_AGG(s.Nombre,N', ') FROM CitaServicios cs JOIN Servicios s ON s.ServicioId=cs.ServicioId WHERE cs.CitaId=c.CitaId) Servicios,(SELECT STRING_AGG(e.NombreCompleto,N', ') FROM CitaMecanicos cm JOIN Empleados e ON e.EmpleadoId=cm.EmpleadoId WHERE cm.CitaId=c.CitaId) Mecanicos FROM Citas c JOIN Clientes cl ON cl.ClienteId=c.ClienteId JOIN Vehiculos v ON v.VehiculoId=c.VehiculoId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId LEFT JOIN AreasTrabajo a ON a.AreaTrabajoId=c.AreaTrabajoId WHERE cl.NombreRazonSocial LIKE @q OR v.Placa LIKE @q OR ISNULL(c.Observaciones,N'') LIKE @q OR EXISTS(SELECT 1 FROM CitaServicios cs JOIN Servicios s ON s.ServicioId=cs.ServicioId WHERE cs.CitaId=c.CitaId AND s.Nombre LIKE @q) OR EXISTS(SELECT 1 FROM CitaMecanicos cm JOIN Empleados e ON e.EmpleadoId=cm.EmpleadoId WHERE cm.CitaId=c.CitaId AND e.NombreCompleto LIKE @q) ORDER BY c.FechaHoraInicio DESC`);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});
router.get('/diagnosticos-form',async(req,res,next)=>{try{if(!can(req,'DIAGNOSTICOS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().query(`SELECT r.RecepcionId,r.NumeroRecepcion,v.Placa,c.NombreRazonSocial Cliente,ma.Nombre Marca,mo.Nombre Modelo,r.FechaHoraIngreso, v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre+N' — '+c.NombreRazonSocial Etiqueta FROM Recepciones r JOIN Vehiculos v ON v.VehiculoId=r.VehiculoId JOIN Clientes c ON c.ClienteId=r.ClienteId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId WHERE NOT EXISTS(SELECT 1 FROM Diagnosticos d WHERE d.RecepcionId=r.RecepcionId) ORDER BY r.FechaHoraIngreso DESC`);res.json({ok:true,recepciones:r.recordset});}catch(e){next(e)}});
router.get('/diagnosticos-mecanicos/:recepcionId',async(req,res,next)=>{try{if(!can(req,'DIAGNOSTICOS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().input('rid',sql.Int,req.params.recepcionId).query(`DECLARE @veh INT,@ing DATETIME2;SELECT @veh=VehiculoId,@ing=FechaHoraIngreso FROM Recepciones WHERE RecepcionId=@rid;DECLARE @cita INT;SELECT TOP 1 @cita=c.CitaId FROM Citas c WHERE c.VehiculoId=@veh AND c.FechaHoraInicio<=DATEADD(DAY,1,@ing) ORDER BY ABS(DATEDIFF(MINUTE,c.FechaHoraInicio,@ing));SELECT DISTINCT e.EmpleadoId,e.NombreCompleto,e.NombreCompleto+CASE WHEN NULLIF(e.Especialidad,N'') IS NOT NULL THEN N' — '+e.Especialidad ELSE N'' END Etiqueta FROM CitaMecanicos cm JOIN Empleados e ON e.EmpleadoId=cm.EmpleadoId WHERE cm.CitaId=@cita AND e.EstadoLaboral=N'ACTIVO' ORDER BY e.NombreCompleto;`);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});
router.get('/diagnosticos-list',async(req,res,next)=>{try{if(!can(req,'DIAGNOSTICOS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().input('q',sql.NVarChar(200),'%'+(req.query.q||'')+'%').query(`SELECT TOP 300 d.DiagnosticoId,d.NumeroDiagnostico,r.NumeroRecepcion,c.NombreRazonSocial Cliente,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre Vehiculo,d.ProblemasEncontrados,d.PruebasRealizadas,d.PosiblesCausas,d.Recomendaciones,d.ManoObraEstimada,d.TiempoEstimadoMinutos,d.CostoEstimado,e.NombreCompleto MecanicoResponsable,d.FechaHoraDiagnostico,d.Estado,q.CotizacionId FROM Diagnosticos d LEFT JOIN Cotizaciones q ON q.DiagnosticoId=d.DiagnosticoId JOIN Recepciones r ON r.RecepcionId=d.RecepcionId JOIN Vehiculos v ON v.VehiculoId=r.VehiculoId JOIN Clientes c ON c.ClienteId=r.ClienteId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId JOIN Empleados e ON e.EmpleadoId=d.MecanicoResponsableId WHERE d.NumeroDiagnostico LIKE @q OR v.Placa LIKE @q OR c.NombreRazonSocial LIKE @q OR ISNULL(d.ProblemasEncontrados,N'') LIKE @q OR e.NombreCompleto LIKE @q ORDER BY d.DiagnosticoId DESC`);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});

router.get('/cotizaciones-form',async(req,res,next)=>{try{if(!can(req,'COTIZACIONES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().query(`SELECT d.DiagnosticoId,d.TiempoEstimadoMinutos,d.CostoEstimado,d.ManoObraEstimada,v.Placa,c.NombreRazonSocial Cliente,ma.Nombre Marca,mo.Nombre Modelo,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre+N' — '+c.NombreRazonSocial Etiqueta FROM Diagnosticos d JOIN Recepciones r ON r.RecepcionId=d.RecepcionId JOIN Vehiculos v ON v.VehiculoId=r.VehiculoId JOIN Clientes c ON c.ClienteId=r.ClienteId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId WHERE d.Estado=N'FINALIZADO' AND NOT EXISTS(SELECT 1 FROM Cotizaciones q WHERE q.DiagnosticoId=d.DiagnosticoId) ORDER BY d.FechaHoraDiagnostico DESC`);res.json({ok:true,diagnosticos:r.recordset});}catch(e){next(e)}});
router.get('/cotizaciones-diagnostico/:id',async(req,res,next)=>{try{if(!can(req,'COTIZACIONES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const rs=await p.request().input('id',sql.Int,req.params.id).query(`SELECT d.DiagnosticoId,d.Estado,d.TiempoEstimadoMinutos,d.CostoEstimado,d.ManoObraEstimada,v.Placa,c.NombreRazonSocial Cliente,ma.Nombre+N' '+mo.Nombre MarcaModelo FROM Diagnosticos d JOIN Recepciones r ON r.RecepcionId=d.RecepcionId JOIN Vehiculos v ON v.VehiculoId=r.VehiculoId JOIN Clientes c ON c.ClienteId=r.ClienteId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId WHERE d.DiagnosticoId=@id;SELECT ds.DiagnosticoServicioId,ds.ServicioId,s.Nombre,ds.Cantidad,ds.PrecioEstimado PrecioUnitario,s.PorcentajeImpuesto,ds.TiempoEstimadoMinutos FROM DiagnosticoServicios ds JOIN Servicios s ON s.ServicioId=ds.ServicioId WHERE ds.DiagnosticoId=@id AND ds.Recomendado=1;SELECT dp.DiagnosticoProductoId,dp.ProductoId,p.Nombre,dp.Cantidad,dp.PrecioUnitarioEstimado PrecioUnitario,p.PorcentajeImpuesto FROM DiagnosticoProductos dp JOIN Productos p ON p.ProductoId=dp.ProductoId WHERE dp.DiagnosticoId=@id;`);const d=rs.recordsets[0][0];if(!d)return res.status(404).json({ok:false,message:'Diagnóstico no encontrado.'});if(d.Estado!=='FINALIZADO')return res.status(409).json({ok:false,message:'Solo un diagnóstico Finalizado puede cotizarse.'});res.json({ok:true,diagnostico:d,servicios:rs.recordsets[1],productos:rs.recordsets[2]});}catch(e){next(e)}});
router.get('/cotizaciones-detalle/:id',async(req,res,next)=>{try{if(!can(req,'COTIZACIONES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const rs=await p.request().input('id',sql.Int,req.params.id).query(`SELECT cs.CotizacionServicioId,cs.ServicioId,s.Nombre,cs.Cantidad,cs.PrecioUnitario,cs.ImpuestoPorcentaje,cs.Descuento,cs.Aprobado,cs.TiempoEstimadoMinutos FROM CotizacionServicios cs JOIN Servicios s ON s.ServicioId=cs.ServicioId WHERE cs.CotizacionId=@id;SELECT cp.CotizacionProductoId,cp.ProductoId,p.Nombre,cp.Cantidad,cp.PrecioUnitario,cp.ImpuestoPorcentaje,cp.Descuento,cp.Aprobado FROM CotizacionProductos cp JOIN Productos p ON p.ProductoId=cp.ProductoId WHERE cp.CotizacionId=@id;`);res.json({ok:true,servicios:rs.recordsets[0],productos:rs.recordsets[1]});}catch(e){next(e)}});
router.get('/cotizaciones-list',async(req,res,next)=>{try{if(!can(req,'COTIZACIONES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});const p=await getPool();const r=await p.request().input('q',sql.NVarChar(200),'%'+(req.query.q||'')+'%').query(`SELECT TOP 300 q.CotizacionId,q.NumeroCotizacion,q.DiagnosticoId,q.FechaEmision,q.FechaVencimiento,q.HorasManoObra,q.PrecioHoraManoObra,q.HorasManoObra*q.PrecioHoraManoObra MontoManoObra,d.CostoEstimado CostoDiagnostico,ISNULL(q.DescuentoPorcentaje,0) DescuentoPorcentaje,q.Descuento,q.Subtotal,q.Impuestos,q.TotalEstimado,q.Condiciones,q.Observaciones,q.Estado,c.NombreRazonSocial Cliente,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre Vehiculo,o.OrdenTrabajoId,o.NumeroOrden FROM Cotizaciones q JOIN Diagnosticos d ON d.DiagnosticoId=q.DiagnosticoId JOIN Recepciones r ON r.RecepcionId=d.RecepcionId JOIN Clientes c ON c.ClienteId=r.ClienteId JOIN Vehiculos v ON v.VehiculoId=r.VehiculoId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId LEFT JOIN OrdenesTrabajo o ON o.CotizacionId=q.CotizacionId WHERE q.NumeroCotizacion LIKE @q OR v.Placa LIKE @q OR c.NombreRazonSocial LIKE @q OR q.Estado LIKE @q ORDER BY q.CotizacionId DESC`);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});

router.get('/ordenes-form',async(req,res,next)=>{try{
 if(!can(req,'ORDENES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const r=await p.request().query(`SELECT q.CotizacionId,q.NumeroCotizacion,q.AprobacionTipo,v.VehiculoId,v.Placa,c.ClienteId,c.NombreRazonSocial Cliente,ma.Nombre+N' '+mo.Nombre MarcaModelo,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre Vehiculo FROM Cotizaciones q JOIN Diagnosticos d ON d.DiagnosticoId=q.DiagnosticoId JOIN Recepciones r ON r.RecepcionId=d.RecepcionId JOIN Vehiculos v ON v.VehiculoId=r.VehiculoId JOIN Clientes c ON c.ClienteId=r.ClienteId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId WHERE q.Estado=N'CONVERTIDA' AND NOT EXISTS(SELECT 1 FROM OrdenesTrabajo o WHERE o.CotizacionId=q.CotizacionId) ORDER BY q.CotizacionId DESC`);
 res.json({ok:true,cotizaciones:r.recordset});
}catch(e){next(e)}});
router.get('/ordenes-list',async(req,res,next)=>{try{
 if(!can(req,'ORDENES_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const r=await p.request().input('q',sql.NVarChar(200),'%'+(req.query.q||'')+'%').query(`SELECT TOP 300 o.OrdenTrabajoId,o.NumeroOrden,o.CotizacionId,q.NumeroCotizacion,o.FechaApertura,o.FechaEstimadaEntrega,o.Prioridad,o.Estado,o.Observaciones,c.NombreRazonSocial Cliente,v.Placa+N' — '+ma.Nombre+N' '+mo.Nombre Vehiculo FROM OrdenesTrabajo o LEFT JOIN Cotizaciones q ON q.CotizacionId=o.CotizacionId JOIN Clientes c ON c.ClienteId=o.ClienteId JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId JOIN ModelosVehiculo mo ON mo.ModeloId=v.ModeloId JOIN MarcasVehiculo ma ON ma.MarcaId=mo.MarcaId WHERE o.NumeroOrden LIKE @q OR ISNULL(q.NumeroCotizacion,N'') LIKE @q OR v.Placa LIKE @q OR c.NombreRazonSocial LIKE @q OR o.Estado LIKE @q OR o.Prioridad LIKE @q ORDER BY o.OrdenTrabajoId DESC`);
 res.json({ok:true,rows:r.recordset});
}catch(e){next(e)}});


router.get('/garantias-form',async(req,res,next)=>{try{
 if(!can(req,'GARANTIAS_CONSULTAR')&&!can(req,'GARANTIAS_REGISTRAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool();
 const ordenes=(await p.request().query(`
   SELECT DISTINCT o.OrdenTrabajoId,o.NumeroOrden,f.FacturaId,f.NumeroFactura,c.NombreRazonSocial Cliente,v.Placa,
          o.NumeroOrden+N' — '+v.Placa+N' — '+c.NombreRazonSocial+N' — '+f.NumeroFactura Etiqueta
   FROM OrdenesTrabajo o
   JOIN Facturas f ON f.OrdenTrabajoId=o.OrdenTrabajoId AND f.Estado=N'PAGADA' AND f.SaldoPendiente=0
   JOIN Clientes c ON c.ClienteId=o.ClienteId
   JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
   WHERE EXISTS(
      SELECT 1 FROM FacturaDetalles fd
      WHERE fd.FacturaId=f.FacturaId AND (fd.ProductoId IS NOT NULL OR fd.ServicioId IS NOT NULL)
   )
   ORDER BY o.OrdenTrabajoId DESC`)).recordset;
 const ventas=(await p.request().query(`
   SELECT DISTINCT v.VentaId,v.NumeroVenta,f.FacturaId,f.NumeroFactura,COALESCE(c.NombreRazonSocial,N'Consumidor final') Cliente,
          v.NumeroVenta+N' — '+COALESCE(c.NombreRazonSocial,N'Consumidor final')+N' — '+f.NumeroFactura Etiqueta
   FROM Ventas v
   JOIN Facturas f ON f.VentaId=v.VentaId AND f.Estado=N'PAGADA' AND f.SaldoPendiente=0
   LEFT JOIN Clientes c ON c.ClienteId=v.ClienteId
   WHERE EXISTS(SELECT 1 FROM FacturaDetalles fd WHERE fd.FacturaId=f.FacturaId AND fd.ProductoId IS NOT NULL)
   ORDER BY v.VentaId DESC`)).recordset;
 res.json({ok:true,ordenes,ventas});
}catch(e){next(e)}});

router.get('/garantias-detalle/:tipo/:id',async(req,res,next)=>{try{
 if(!can(req,'GARANTIAS_CONSULTAR')&&!can(req,'GARANTIAS_REGISTRAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool(); const tipo=String(req.params.tipo||'').toUpperCase(); const id=Number(req.params.id);
 let f;
 if(tipo==='ORDEN') f=(await p.request().input('id',sql.Int,id).query(`SELECT TOP 1 FacturaId,NumeroFactura FROM Facturas WHERE OrdenTrabajoId=@id AND Estado=N'PAGADA' AND SaldoPendiente=0 ORDER BY FacturaId DESC`)).recordset[0];
 else if(tipo==='VENTA') f=(await p.request().input('id',sql.Int,id).query(`SELECT TOP 1 FacturaId,NumeroFactura FROM Facturas WHERE VentaId=@id AND Estado=N'PAGADA' AND SaldoPendiente=0 ORDER BY FacturaId DESC`)).recordset[0];
 else return res.status(400).json({ok:false,message:'Origen inválido.'});
 if(!f)return res.status(409).json({ok:false,message:'El origen seleccionado no tiene una factura completamente pagada.'});
 const productos=(await p.request().input('fid',sql.Int,f.FacturaId).query(`
   SELECT DISTINCT p.ProductoId,p.Nombre,p.CodigoInterno,p.TipoProducto,
          p.Nombre+N' — '+p.CodigoInterno+N' — '+p.TipoProducto Etiqueta
   FROM FacturaDetalles fd JOIN Productos p ON p.ProductoId=fd.ProductoId
   WHERE fd.FacturaId=@fid AND fd.ProductoId IS NOT NULL
   ORDER BY p.Nombre`)).recordset;
 const servicios=tipo==='ORDEN'?(await p.request().input('fid',sql.Int,f.FacturaId).query(`
   SELECT DISTINCT s.ServicioId,s.Nombre,s.Codigo,s.Nombre+N' — '+s.Codigo Etiqueta
   FROM FacturaDetalles fd JOIN Servicios s ON s.ServicioId=fd.ServicioId
   WHERE fd.FacturaId=@fid AND fd.ServicioId IS NOT NULL
   ORDER BY s.Nombre`)).recordset:[];
 res.json({ok:true,factura:f,productos,servicios});
}catch(e){next(e)}});

router.get('/garantias-list',async(req,res,next)=>{try{
 if(!can(req,'GARANTIAS_CONSULTAR'))return res.status(403).json({ok:false,message:'Sin permiso.'});
 const p=await getPool(); const q='%'+(req.query.q||'')+'%';
 const r=await p.request().input('q',sql.NVarChar(200),q).query(`
   SELECT TOP 300 g.GarantiaId,
      CASE WHEN g.OrdenTrabajoId IS NOT NULL THEN o.NumeroOrden ELSE v.NumeroVenta END Origen,
      f.NumeroFactura,COALESCE(c.NombreRazonSocial,N'Consumidor final') Cliente,
      g.TipoCobertura,p.Nombre Producto,s.Nombre Servicio,g.FechaInicio,g.FechaVencimiento,g.Estado,g.Condiciones,g.Observaciones
   FROM Garantias g
   LEFT JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=g.OrdenTrabajoId
   LEFT JOIN Ventas v ON v.VentaId=g.VentaId
   LEFT JOIN Facturas f ON (f.OrdenTrabajoId=g.OrdenTrabajoId AND g.OrdenTrabajoId IS NOT NULL) OR (f.VentaId=g.VentaId AND g.VentaId IS NOT NULL)
   LEFT JOIN Clientes c ON c.ClienteId=f.ClienteId
   LEFT JOIN Productos p ON p.ProductoId=g.ProductoId
   LEFT JOIN Servicios s ON s.ServicioId=g.ServicioId
   WHERE ISNULL(o.NumeroOrden,N'') LIKE @q OR ISNULL(v.NumeroVenta,N'') LIKE @q OR ISNULL(f.NumeroFactura,N'') LIKE @q OR ISNULL(c.NombreRazonSocial,N'') LIKE @q OR ISNULL(p.Nombre,N'') LIKE @q OR ISNULL(s.Nombre,N'') LIKE @q OR g.TipoCobertura LIKE @q OR g.Estado LIKE @q
   ORDER BY g.GarantiaId DESC`);
 res.json({ok:true,rows:r.recordset});
}catch(e){next(e)}});

router.get('/:name',async(req,res,next)=>{try{if(!allowed[req.params.name])return res.status(404).json({ok:false});const p=await getPool();const r=await p.request().query(allowed[req.params.name]);res.json({ok:true,rows:r.recordset});}catch(e){next(e)}});
module.exports=router;
