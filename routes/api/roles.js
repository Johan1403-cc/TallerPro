const express = require('express');
const { query } = require('../bd');
const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT r.id_rol AS id,r.nombre,r.descripcion,r.activo,
             COUNT(DISTINCT ur.id_usuario) AS usuarios,
             COUNT(DISTINCT rp.id_permiso) AS permisos
      FROM ROLES r
      LEFT JOIN USUARIO_ROL ur ON ur.id_rol=r.id_rol
      LEFT JOIN ROL_PERMISO rp ON rp.id_rol=r.id_rol
      GROUP BY r.id_rol,r.nombre,r.descripcion,r.activo
      ORDER BY r.nombre
    `);
    res.json(r.recordset);
  } catch (e) { next(e); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const r = await query(`
      SELECT r.id_rol AS id,r.nombre,r.descripcion,r.activo,
             COUNT(DISTINCT ur.id_usuario) AS usuarios,
             COUNT(DISTINCT rp.id_permiso) AS permisos
      FROM ROLES r
      LEFT JOIN USUARIO_ROL ur ON ur.id_rol=r.id_rol
      LEFT JOIN ROL_PERMISO rp ON rp.id_rol=r.id_rol
      WHERE r.id_rol=@id
      GROUP BY r.id_rol,r.nombre,r.descripcion,r.activo
    `,{id:Number(req.params.id)});
    if(!r.recordset.length)return res.status(404).json({error:'Rol no encontrado.'});
    res.json(r.recordset[0]);
  } catch(e){next(e);}
});

router.post('/', async (req,res,next)=>{
  try{
    const nombre=String(req.body.nombre||'').trim();
    const descripcion=req.body.descripcion?String(req.body.descripcion).trim():null;
    const activo=req.body.activo===undefined?1:(['1',1,true,'true'].includes(req.body.activo)?1:0);
    if(!nombre)return res.status(400).json({error:'El nombre del rol es obligatorio.'});
    const exists=await query(`SELECT id_rol FROM ROLES WHERE LOWER(nombre)=LOWER(@nombre)`,{nombre});
    if(exists.recordset.length)return res.status(409).json({error:'Ya existe un rol con ese nombre.'});
    const r=await query(`INSERT INTO ROLES(nombre,descripcion,activo)
                         OUTPUT INSERTED.id_rol AS id
                         VALUES(@nombre,@descripcion,@activo)`,{nombre,descripcion,activo});
    res.status(201).json({id:r.recordset[0].id});
  }catch(e){next(e);}
});

router.put('/:id',async(req,res,next)=>{
  try{
    const id=Number(req.params.id);
    const current=await query(`SELECT id_rol,nombre,descripcion,activo FROM ROLES WHERE id_rol=@id`,{id});
    if(!current.recordset.length)return res.status(404).json({error:'Rol no encontrado.'});
    const nombre=req.body.nombre!==undefined?String(req.body.nombre).trim():current.recordset[0].nombre;
    const descripcion=req.body.descripcion!==undefined?(req.body.descripcion?String(req.body.descripcion).trim():null):current.recordset[0].descripcion;
    const activo=req.body.activo!==undefined?(['1',1,true,'true'].includes(req.body.activo)?1:0):current.recordset[0].activo;
    if(!nombre)return res.status(400).json({error:'El nombre del rol es obligatorio.'});
    const exists=await query(`SELECT id_rol FROM ROLES WHERE id_rol<>@id AND LOWER(nombre)=LOWER(@nombre)`,{id,nombre});
    if(exists.recordset.length)return res.status(409).json({error:'Ya existe otro rol con ese nombre.'});
    await query(`UPDATE ROLES SET nombre=@nombre,descripcion=@descripcion,activo=@activo WHERE id_rol=@id`,{id,nombre,descripcion,activo});
    res.json({ok:true});
  }catch(e){next(e);}
});

router.delete('/:id',async(req,res,next)=>{
  try{
    const id=Number(req.params.id);
    const usage=await query(`SELECT COUNT(*) cantidad FROM USUARIO_ROL WHERE id_rol=@id`,{id});
    if(Number(usage.recordset[0].cantidad)>0){
      await query(`UPDATE ROLES SET activo=0 WHERE id_rol=@id`,{id});
      return res.json({ok:true,desactivado:true,mensaje:'El rol tiene usuarios asociados y fue desactivado para conservar el historial.'});
    }
    await query(`DELETE FROM ROL_PERMISO WHERE id_rol=@id; DELETE FROM ROLES WHERE id_rol=@id;`,{id});
    res.json({ok:true});
  }catch(e){next(e);}
});

module.exports=router;
