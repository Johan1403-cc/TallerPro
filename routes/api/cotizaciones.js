const express = require('express');
const { getPool, query } = require('../bd');
const { createCrudRouter } = require('./crud');
const { requirePermission } = require('../auth');

const router = express.Router();


router.use((req,res,next)=>{
  if(['POST','PUT','PATCH'].includes(req.method)){
    const estado=String(req.body.estado||'').toUpperCase();
    if(['APROBADA','APROBADA_PARCIAL','RECHAZADA'].includes(estado)){
      req.body.id_usuario_decision=req.user.id_usuario;
      req.body.fecha_decision=new Date().toISOString();
    }else{
      delete req.body.id_usuario_decision;
      delete req.body.fecha_decision;
    }
  }
  next();
});


router.get('/:id/servicios', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT cs.id_detalle AS id, cs.id_cotizacion, cs.id_servicio,
             s.nombre AS servicio, cs.horas_mano_obra, cs.precio_hora, cs.subtotal
      FROM COTIZACION_SERVICIOS cs
      INNER JOIN SERVICIOS s ON s.id_servicio=cs.id_servicio
      WHERE cs.id_cotizacion=@id
      ORDER BY s.nombre`, { id: Number(req.params.id) });
    res.json(r.recordset);
  } catch (e) { next(e); }
});

router.post('/:id/servicios', async (req, res, next) => {
  try {
    const pool = await getPool();
    const r = await pool.request()
      .input('id_cotizacion', Number(req.params.id))
      .input('id_servicio', Number(req.body.id_servicio))
      .input('horas_mano_obra', req.body.horas_mano_obra ?? 0)
      .input('precio_hora', req.body.precio_hora ?? 0)
      .input('subtotal', req.body.subtotal ?? 0)
      .query(`
        INSERT INTO COTIZACION_SERVICIOS
          (id_cotizacion,id_servicio,horas_mano_obra,precio_hora,subtotal)
        OUTPUT INSERTED.id_detalle AS id
        VALUES(@id_cotizacion,@id_servicio,@horas_mano_obra,@precio_hora,@subtotal)`);
    res.status(201).json({ id: r.recordset[0].id });
  } catch (e) { next(e); }
});

router.delete('/:id/servicios/:detalle', async (req, res, next) => {
  try {
    await query(
      'DELETE FROM COTIZACION_SERVICIOS WHERE id_detalle=@detalle AND id_cotizacion=@id',
      { detalle: Number(req.params.detalle), id: Number(req.params.id) }
    );
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.get('/:id/repuestos', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT cr.id_detalle AS id, cr.id_cotizacion, cr.id_repuesto,
             r.nombre AS repuesto, cr.cantidad, cr.precio_unitario, cr.subtotal
      FROM COTIZACION_REPUESTOS cr
      INNER JOIN REPUESTOS r ON r.id_repuesto=cr.id_repuesto
      WHERE cr.id_cotizacion=@id
      ORDER BY r.nombre`, { id: Number(req.params.id) });
    res.json(r.recordset);
  } catch (e) { next(e); }
});

router.post('/:id/repuestos', async (req, res, next) => {
  try {
    const pool = await getPool();
    const r = await pool.request()
      .input('id_cotizacion', Number(req.params.id))
      .input('id_repuesto', Number(req.body.id_repuesto))
      .input('cantidad', req.body.cantidad ?? 1)
      .input('precio_unitario', req.body.precio_unitario ?? 0)
      .input('subtotal', req.body.subtotal ?? 0)
      .query(`
        INSERT INTO COTIZACION_REPUESTOS
          (id_cotizacion,id_repuesto,cantidad,precio_unitario,subtotal)
        OUTPUT INSERTED.id_detalle AS id
        VALUES(@id_cotizacion,@id_repuesto,@cantidad,@precio_unitario,@subtotal)`);
    res.status(201).json({ id: r.recordset[0].id });
  } catch (e) { next(e); }
});

router.delete('/:id/repuestos/:detalle', async (req, res, next) => {
  try {
    await query(
      'DELETE FROM COTIZACION_REPUESTOS WHERE id_detalle=@detalle AND id_cotizacion=@id',
      { detalle: Number(req.params.detalle), id: Number(req.params.id) }
    );
    res.json({ ok: true });
  } catch (e) { next(e); }
});


async function validateDiscount(req,res,next){
  try{
    if(!['POST','PUT','PATCH'].includes(req.method) || req.body.descuentos===undefined) return next();
    const subtotal=Number(req.body.subtotal||0);
    const descuento=Number(req.body.descuentos||0);
    if(descuento<0 || subtotal<0) return res.status(400).json({error:'Subtotal y descuento no pueden ser negativos.'});
    if(!subtotal || !descuento) return next();
    const cfg=await query(`SELECT valor FROM CONFIGURACION_GENERAL WHERE clave='LIMITE_DESCUENTO_SIN_AUTORIZACION'`);
    const limite=Number(cfg.recordset[0]?.valor||10);
    const porcentaje=(descuento/subtotal)*100;
    if(porcentaje<=limite) return next();
    return requirePermission('DESCUENTOS_APLICAR')(req,res,next);
  }catch(e){next(e);}
}
router.use(validateDiscount);

router.use(createCrudRouter({
  table: 'COTIZACIONES',
  id: 'id_cotizacion',
  columns: [
    'id_diagnostico','id_cliente','id_vehiculo','fecha_vencimiento',
    'subtotal','impuestos','descuentos','total','condiciones',
    'estado','id_usuario_decision','fecha_decision'
  ],
  select: `
    SELECT c.id_cotizacion AS id,
           c.id_diagnostico, d.id_recepcion, rec.numero_consecutivo AS recepcion_consecutivo,
           c.id_cliente, cl.nombre AS cliente,
           c.id_vehiculo, v.placa,
           c.fecha_emision, c.fecha_vencimiento,
           c.subtotal, c.impuestos, c.descuentos, c.total,
           c.condiciones, c.estado,
           c.id_usuario_decision, u.nombre_usuario AS usuario_decision,
           c.fecha_decision
    FROM COTIZACIONES c
    INNER JOIN DIAGNOSTICOS d ON d.id_diagnostico=c.id_diagnostico
    LEFT JOIN RECEPCIONES rec ON rec.id_recepcion=d.id_recepcion
    INNER JOIN CLIENTES cl ON cl.id_cliente=c.id_cliente
    INNER JOIN VEHICULOS v ON v.id_vehiculo=c.id_vehiculo
    LEFT JOIN USUARIOS u ON u.id_usuario=c.id_usuario_decision
    ORDER BY c.fecha_emision DESC`
}));

module.exports = router;
