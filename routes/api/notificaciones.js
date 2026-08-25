const express = require('express');
const { query, executeProcedure } = require('../bd');
const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    try {
      await executeProcedure('SP_GENERAR_NOTIFICACIONES_USUARIO', {
        id_usuario: Number(req.user.id_usuario)
      });
    } catch (e) {
      console.error('Generación automática de notificaciones:', e.message);
    }

    const items = await query(`
      SELECT TOP 50
        id_notificacion, tipo, mensaje, id_registro_relacionado, leida, fecha_hora
      FROM NOTIFICACIONES
      WHERE id_usuario_destino=@id_usuario
      ORDER BY leida ASC, fecha_hora DESC
    `, { id_usuario:Number(req.user.id_usuario) });

    const unread = await query(`
      SELECT COUNT(*) AS cantidad
      FROM NOTIFICACIONES
      WHERE id_usuario_destino=@id_usuario AND leida=0
    `, { id_usuario:Number(req.user.id_usuario) });

    res.json({
      items: items.recordset,
      unread: Number(unread.recordset[0]?.cantidad || 0)
    });
  } catch (e) { next(e); }
});

router.patch('/marcar-todas', async (req,res,next) => {
  try {
    await query(`
      UPDATE NOTIFICACIONES
      SET leida=1
      WHERE id_usuario_destino=@id_usuario AND leida=0
    `, { id_usuario:Number(req.user.id_usuario) });
    res.json({ ok:true });
  } catch(e) { next(e); }
});

router.patch('/:id/leida', async (req,res,next) => {
  try {
    const r = await query(`
      UPDATE NOTIFICACIONES
      SET leida=1
      WHERE id_notificacion=@id
        AND id_usuario_destino=@id_usuario
    `, {
      id:Number(req.params.id),
      id_usuario:Number(req.user.id_usuario)
    });
    if (!r.rowsAffected[0]) return res.status(404).json({ error:'Notificación no encontrada.' });
    res.json({ ok:true });
  } catch(e) { next(e); }
});

module.exports = router;
