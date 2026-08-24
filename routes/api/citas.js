const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'CITAS',
  id: 'id_cita',
  columns: ['id_cliente', 'id_vehiculo', 'id_servicio', 'id_empleado', 'fecha_hora', 'duracion_estimada_min', 'estado', 'observaciones'],
  select: 'SELECT ci.id_cita AS id, ci.id_cliente, c.nombre AS cliente, ci.id_vehiculo, v.placa, ci.id_servicio, s.nombre AS servicio, ci.id_empleado, e.nombre AS empleado, ci.fecha_hora, ci.duracion_estimada_min, ci.estado, ci.observaciones FROM CITAS ci INNER JOIN CLIENTES c ON c.id_cliente=ci.id_cliente INNER JOIN VEHICULOS v ON v.id_vehiculo=ci.id_vehiculo LEFT JOIN SERVICIOS s ON s.id_servicio=ci.id_servicio LEFT JOIN EMPLEADOS e ON e.id_empleado=ci.id_empleado ORDER BY ci.fecha_hora DESC'
});
