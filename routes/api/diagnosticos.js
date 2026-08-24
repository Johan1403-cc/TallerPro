const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'DIAGNOSTICOS',
  id: 'id_diagnostico',
  columns: ['id_recepcion', 'id_empleado', 'problemas_encontrados', 'pruebas_realizadas', 'posibles_causas', 'recomendaciones', 'mano_obra_estimada', 'tiempo_estimado_horas', 'costo_estimado', 'estado'],
  select: 'SELECT d.id_diagnostico AS id, d.id_recepcion, r.numero_consecutivo, d.id_empleado, e.nombre AS empleado, d.problemas_encontrados, d.pruebas_realizadas, d.posibles_causas, d.recomendaciones, d.mano_obra_estimada, d.tiempo_estimado_horas, d.costo_estimado, d.estado, d.fecha_hora FROM DIAGNOSTICOS d INNER JOIN RECEPCIONES r ON r.id_recepcion=d.id_recepcion INNER JOIN EMPLEADOS e ON e.id_empleado=d.id_empleado ORDER BY d.fecha_hora DESC'
});
