const express = require('express');
const { getPool, query } = require('../bd');
const router = express.Router();

const VALID_STATES = ['PROGRAMADA','CONFIRMADA','ATENDIDA','CANCELADA','REPROGRAMADA','AUSENTE'];

const SELECT = `
  SELECT ci.id_cita AS id, ci.id_cliente, c.nombre AS cliente,
         ci.id_vehiculo, v.placa, ci.id_servicio, s.nombre AS servicio,
         ci.id_empleado, e.nombre AS empleado, ci.fecha_hora,
         ci.duracion_estimada_min, ci.estado, ci.observaciones
  FROM CITAS ci
  INNER JOIN CLIENTES c ON c.id_cliente = ci.id_cliente
  INNER JOIN VEHICULOS v ON v.id_vehiculo = ci.id_vehiculo
  LEFT JOIN SERVICIOS s ON s.id_servicio = ci.id_servicio
  LEFT JOIN EMPLEADOS e ON e.id_empleado = ci.id_empleado
`;

function normalize(body) {
  const fecha_hora = body.fecha_hora;
  const duration = Number(body.duracion_estimada_min || 60);
  if (!fecha_hora || Number.isNaN(new Date(fecha_hora).getTime())) {
    return { error: 'La fecha y hora de la cita no son válidas.' };
  }
  if (!Number.isFinite(duration) || duration < 5 || duration > 1440) {
    return { error: 'La duración debe estar entre 5 y 1440 minutos.' };
  }
  const estado = String(body.estado || 'PROGRAMADA').toUpperCase();
  if (!VALID_STATES.includes(estado)) {
    return { error: 'El estado de la cita no es válido.' };
  }
  return { ...body, duracion_estimada_min: duration, estado };
}

async function findConflict(data, currentId = null) {
  if (['CANCELADA','AUSENTE'].includes(data.estado)) return null;

  const result = await query(`
    SELECT TOP 1
      c.id_cita,
      c.fecha_hora,
      c.duracion_estimada_min,
      e.nombre AS empleado,
      v.placa
    FROM CITAS c
    LEFT JOIN EMPLEADOS e ON e.id_empleado = c.id_empleado
    INNER JOIN VEHICULOS v ON v.id_vehiculo = c.id_vehiculo
    WHERE c.estado NOT IN ('CANCELADA','AUSENTE')
      AND (@currentId IS NULL OR c.id_cita <> @currentId)
      AND (
        (@id_empleado IS NOT NULL AND c.id_empleado = @id_empleado)
        OR c.id_vehiculo = @id_vehiculo
      )
      AND c.fecha_hora < DATEADD(MINUTE, @duracion, @fecha_hora)
      AND DATEADD(MINUTE, c.duracion_estimada_min, c.fecha_hora) > @fecha_hora
    ORDER BY c.fecha_hora
  `, {
    currentId,
    id_empleado: data.id_empleado ? Number(data.id_empleado) : null,
    id_vehiculo: Number(data.id_vehiculo),
    fecha_hora: data.fecha_hora,
    duracion: Number(data.duracion_estimada_min)
  });

  return result.recordset[0] || null;
}

router.get('/', async (req, res, next) => {
  try {
    const r = await query(`${SELECT} ORDER BY ci.fecha_hora DESC`);
    res.json(r.recordset);
  } catch (e) { next(e); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const r = await query('SELECT * FROM CITAS WHERE id_cita=@id', { id: Number(req.params.id) });
    if (!r.recordset.length) return res.status(404).json({ error: 'Cita no encontrada.' });
    res.json(r.recordset[0]);
  } catch (e) { next(e); }
});

async function save(req, res, next, isUpdate) {
  try {
    const data = normalize(req.body || {});
    if (data.error) return res.status(400).json({ error: data.error });
    if (!data.id_cliente || !data.id_vehiculo) {
      return res.status(400).json({ error: 'Cliente y vehículo son obligatorios.' });
    }

    const conflict = await findConflict(data, isUpdate ? Number(req.params.id) : null);
    if (conflict) {
      return res.status(409).json({
        error: conflict.empleado
          ? `La cita choca con otra asignación de ${conflict.empleado} o del vehículo ${conflict.placa}.`
          : `El vehículo ${conflict.placa} ya tiene una cita que se cruza con ese horario.`
      });
    }

    const pool = await getPool();
    const request = pool.request()
      .input('id_cliente', Number(data.id_cliente))
      .input('id_vehiculo', Number(data.id_vehiculo))
      .input('id_servicio', data.id_servicio ? Number(data.id_servicio) : null)
      .input('id_empleado', data.id_empleado ? Number(data.id_empleado) : null)
      .input('fecha_hora', data.fecha_hora)
      .input('duracion_estimada_min', Number(data.duracion_estimada_min))
      .input('estado', data.estado)
      .input('observaciones', data.observaciones || null);

    if (isUpdate) {
      request.input('id', Number(req.params.id));
      const r = await request.query(`
        UPDATE CITAS
        SET id_cliente=@id_cliente, id_vehiculo=@id_vehiculo,
            id_servicio=@id_servicio, id_empleado=@id_empleado,
            fecha_hora=@fecha_hora, duracion_estimada_min=@duracion_estimada_min,
            estado=@estado, observaciones=@observaciones
        WHERE id_cita=@id
      `);
      if (!r.rowsAffected[0]) return res.status(404).json({ error: 'Cita no encontrada.' });
      return res.json({ ok: true });
    }

    const r = await request.query(`
      INSERT INTO CITAS
        (id_cliente,id_vehiculo,id_servicio,id_empleado,fecha_hora,duracion_estimada_min,estado,observaciones)
      OUTPUT INSERTED.id_cita AS id
      VALUES
        (@id_cliente,@id_vehiculo,@id_servicio,@id_empleado,@fecha_hora,@duracion_estimada_min,@estado,@observaciones)
    `);
    res.status(201).json({ id: r.recordset[0].id });
  } catch (e) { next(e); }
}

router.post('/', (req,res,next) => save(req,res,next,false));
router.put('/:id', (req,res,next) => save(req,res,next,true));

// En lugar de borrar físicamente, cancelar la cita.
router.delete('/:id', async (req,res,next) => {
  try {
    const r = await query(`UPDATE CITAS SET estado='CANCELADA' WHERE id_cita=@id`, { id:Number(req.params.id) });
    if (!r.rowsAffected[0]) return res.status(404).json({ error:'Cita no encontrada.' });
    res.json({ ok:true });
  } catch(e) { next(e); }
});

module.exports = router;
