const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'RECEPCIONES',
  id: 'id_recepcion',
  columns: ['numero_consecutivo', 'id_cliente', 'id_vehiculo', 'id_empleado_recibe', 'kilometraje_actual', 'nivel_combustible', 'motivo_visita', 'descripcion_problema', 'accesorios_entregados', 'danos_visibles', 'fecha_estimada_entrega', 'observaciones'],
  select: 'SELECT r.id_recepcion AS id, r.numero_consecutivo, r.id_cliente, c.nombre AS cliente, r.id_vehiculo, v.placa, r.id_empleado_recibe, e.nombre AS empleado, r.fecha_hora_ingreso, r.kilometraje_actual, r.nivel_combustible, r.motivo_visita, r.descripcion_problema, r.accesorios_entregados, r.danos_visibles, r.fecha_estimada_entrega, r.observaciones FROM RECEPCIONES r INNER JOIN CLIENTES c ON c.id_cliente=r.id_cliente INNER JOIN VEHICULOS v ON v.id_vehiculo=r.id_vehiculo LEFT JOIN EMPLEADOS e ON e.id_empleado=r.id_empleado_recibe ORDER BY r.fecha_hora_ingreso DESC'
});
