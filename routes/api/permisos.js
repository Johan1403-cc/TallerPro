const express = require('express');
const { query } = require('../bd');
const router = express.Router();

router.get('/', async (req,res,next) => {
  try {
    const r = await query(`
      SELECT p.id_permiso AS id,p.codigo,p.nombre,p.descripcion,p.modulo,
             COALESCE(STRING_AGG(r.nombre, ', '),'Sin asignar') roles
      FROM PERMISOS p
      LEFT JOIN ROL_PERMISO rp ON rp.id_permiso=p.id_permiso
      LEFT JOIN ROLES r ON r.id_rol=rp.id_rol
      GROUP BY p.id_permiso,p.codigo,p.nombre,p.descripcion,p.modulo
      ORDER BY p.modulo,p.codigo
    `);
    res.json(r.recordset);
  } catch(e) { next(e); }
});

router.get('/rol/:id', async (req,res,next) => {
  try {
    const r = await query(`
      SELECT p.id_permiso AS id,p.codigo,p.nombre,p.modulo,
             CASE WHEN rp.id_permiso IS NULL THEN 0 ELSE 1 END asignado
      FROM PERMISOS p
      LEFT JOIN ROL_PERMISO rp
        ON rp.id_permiso=p.id_permiso AND rp.id_rol=@id_rol
      ORDER BY p.modulo,p.codigo
    `,{id_rol:Number(req.params.id)});
    res.json(r.recordset);
  } catch(e){next(e);}
});

router.post('/rol/:id', async (req,res,next) => {
  try {
    const id_rol=Number(req.params.id), id_permiso=Number(req.body.id_permiso);
    if(!id_permiso) return res.status(400).json({error:'Permiso obligatorio.'});
    await query(`
      IF NOT EXISTS(SELECT 1 FROM ROL_PERMISO WHERE id_rol=@id_rol AND id_permiso=@id_permiso)
        INSERT INTO ROL_PERMISO(id_rol,id_permiso) VALUES(@id_rol,@id_permiso)
    `,{id_rol,id_permiso});
    res.json({ok:true});
  } catch(e){next(e);}
});

router.delete('/rol/:id/:permiso', async (req,res,next) => {
  try {
    await query(`
      DELETE FROM ROL_PERMISO
      WHERE id_rol=@id_rol AND id_permiso=@id_permiso
    `,{id_rol:Number(req.params.id),id_permiso:Number(req.params.permiso)});
    res.json({ok:true});
  } catch(e){next(e);}
});

module.exports=router;
