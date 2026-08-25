const express=require('express');
const {query,getPool,sql}=require('../bd');
const router=express.Router();

function cleanText(value,max=200){
  const v=value==null?null:String(value).trim();
  return v?v.slice(0,max):null;
}

router.get('/',async(req,res,next)=>{
 try{
  const r=await query(`
    SELECT p.id_permiso AS id,p.codigo,p.nombre,p.descripcion,p.modulo,
           COALESCE(STRING_AGG(r.nombre, ', '),'Sin asignar') roles,
           COUNT(DISTINCT rp.id_rol) cantidad_roles
    FROM PERMISOS p
    LEFT JOIN ROL_PERMISO rp ON rp.id_permiso=p.id_permiso
    LEFT JOIN ROLES r ON r.id_rol=rp.id_rol
    GROUP BY p.id_permiso,p.codigo,p.nombre,p.descripcion,p.modulo
    ORDER BY p.modulo,p.codigo`);
  res.json(r.recordset);
 }catch(e){next(e);}
});

router.get('/rol/:id',async(req,res,next)=>{
 try{
  const role=await query(`SELECT id_rol,nombre,descripcion,activo FROM ROLES WHERE id_rol=@id`,{id:Number(req.params.id)});
  if(!role.recordset.length)return res.status(404).json({error:'Rol no encontrado.'});
  const r=await query(`
    SELECT p.id_permiso AS id,p.codigo,p.nombre,p.descripcion,p.modulo,
           CASE WHEN rp.id_permiso IS NULL THEN 0 ELSE 1 END asignado
    FROM PERMISOS p
    LEFT JOIN ROL_PERMISO rp ON rp.id_permiso=p.id_permiso AND rp.id_rol=@id_rol
    ORDER BY p.modulo,p.codigo`,{id_rol:Number(req.params.id)});
  res.json({rol:role.recordset[0],permisos:r.recordset});
 }catch(e){next(e);}
});

router.put('/rol/:id',async(req,res,next)=>{
 const id_rol=Number(req.params.id);
 const ids=[...new Set((Array.isArray(req.body.id_permisos)?req.body.id_permisos:[]).map(Number).filter(Number.isInteger).filter(x=>x>0))];
 let tx;
 try{
  const pool=await getPool(); tx=new sql.Transaction(pool); await tx.begin();
  const role=await new sql.Request(tx).input('id_rol',id_rol).query(`SELECT id_rol FROM ROLES WHERE id_rol=@id_rol`);
  if(!role.recordset.length){await tx.rollback();return res.status(404).json({error:'Rol no encontrado.'});}
  if(ids.length){
    const valid=await new sql.Request(tx).input('ids',ids.join(',')).query(`
      SELECT id_permiso FROM PERMISOS
      WHERE id_permiso IN (SELECT TRY_CAST(value AS int) FROM STRING_SPLIT(@ids,','))`);
    if(valid.recordset.length!==ids.length){await tx.rollback();return res.status(400).json({error:'Uno o más permisos no existen.'});}
  }
  await new sql.Request(tx).input('id_rol',id_rol).query(`DELETE FROM ROL_PERMISO WHERE id_rol=@id_rol`);
  for(const id_permiso of ids){
    await new sql.Request(tx).input('id_rol',id_rol).input('id_permiso',id_permiso)
      .query(`INSERT INTO ROL_PERMISO(id_rol,id_permiso) VALUES(@id_rol,@id_permiso)`);
  }
  await tx.commit(); res.json({ok:true,cantidad:ids.length});
 }catch(e){try{await tx?.rollback();}catch{} next(e);}
});

router.get('/:id',async(req,res,next)=>{
 try{
  const r=await query(`SELECT id_permiso AS id,codigo,nombre,descripcion,modulo FROM PERMISOS WHERE id_permiso=@id`,{id:Number(req.params.id)});
  if(!r.recordset.length)return res.status(404).json({error:'Permiso no encontrado.'});
  res.json(r.recordset[0]);
 }catch(e){next(e);}
});

router.post('/',async(req,res,next)=>{
 try{
  const codigo=String(req.body.codigo||'').trim().toUpperCase().replace(/\s+/g,'_').slice(0,60);
  const nombre=String(req.body.nombre||'').trim().slice(0,120);
  const descripcion=cleanText(req.body.descripcion,200);
  const modulo=cleanText(req.body.modulo,60)?.toUpperCase();
  if(!codigo||!nombre||!modulo)return res.status(400).json({error:'Código, nombre y módulo son obligatorios.'});
  if(!/^[A-Z0-9_]+$/.test(codigo))return res.status(400).json({error:'El código solo puede contener letras, números y guion bajo.'});
  const exists=await query(`SELECT id_permiso FROM PERMISOS WHERE UPPER(codigo)=@codigo`,{codigo});
  if(exists.recordset.length)return res.status(409).json({error:'Ya existe un permiso con ese código.'});
  const r=await query(`INSERT INTO PERMISOS(codigo,nombre,descripcion,modulo)
                       OUTPUT INSERTED.id_permiso AS id VALUES(@codigo,@nombre,@descripcion,@modulo)`,
                      {codigo,nombre,descripcion,modulo});
  res.status(201).json({id:r.recordset[0].id});
 }catch(e){next(e);}
});

router.put('/:id',async(req,res,next)=>{
 try{
  const id=Number(req.params.id);
  const cur=await query(`SELECT id_permiso,codigo,nombre,descripcion,modulo FROM PERMISOS WHERE id_permiso=@id`,{id});
  if(!cur.recordset.length)return res.status(404).json({error:'Permiso no encontrado.'});
  const old=cur.recordset[0];
  const requestedCode=req.body.codigo!==undefined?String(req.body.codigo).trim().toUpperCase().replace(/\s+/g,'_').slice(0,60):old.codigo;
  if(requestedCode!==old.codigo){
    return res.status(400).json({error:'El código técnico del permiso no puede cambiarse porque el backend lo usa para autorizar operaciones.'});
  }
  const codigo=old.codigo;
  const nombre=req.body.nombre!==undefined?String(req.body.nombre).trim().slice(0,120):old.nombre;
  const descripcion=req.body.descripcion!==undefined?cleanText(req.body.descripcion,200):old.descripcion;
  const modulo=req.body.modulo!==undefined?cleanText(req.body.modulo,60)?.toUpperCase():old.modulo;
  if(!codigo||!nombre||!modulo)return res.status(400).json({error:'Código, nombre y módulo son obligatorios.'});
  if(!/^[A-Z0-9_]+$/.test(codigo))return res.status(400).json({error:'El código solo puede contener letras, números y guion bajo.'});
  const dup=await query(`SELECT id_permiso FROM PERMISOS WHERE id_permiso<>@id AND UPPER(codigo)=@codigo`,{id,codigo});
  if(dup.recordset.length)return res.status(409).json({error:'Ya existe otro permiso con ese código.'});
  await query(`UPDATE PERMISOS SET codigo=@codigo,nombre=@nombre,descripcion=@descripcion,modulo=@modulo WHERE id_permiso=@id`,
              {id,codigo,nombre,descripcion,modulo});
  res.json({ok:true});
 }catch(e){next(e);}
});

router.delete('/:id',async(req,res,next)=>{
 try{
  const id=Number(req.params.id);
  const used=await query(`SELECT COUNT(*) cantidad FROM ROL_PERMISO WHERE id_permiso=@id`,{id});
  if(Number(used.recordset[0].cantidad)>0){
    return res.status(409).json({error:'No se puede eliminar un permiso asignado a roles. Quítalo primero de todos los roles.'});
  }
  const r=await query(`DELETE FROM PERMISOS WHERE id_permiso=@id`,{id});
  if(!r.rowsAffected[0])return res.status(404).json({error:'Permiso no encontrado.'});
  res.json({ok:true});
 }catch(e){next(e);}
});

module.exports=router;
