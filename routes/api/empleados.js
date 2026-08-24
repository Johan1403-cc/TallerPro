const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'EMPLEADOS',
  id: 'id_empleado',
  columns: ['nombre','cargo','identificacion','telefono','email','direccion','fecha_contratacion','especialidad','estado_laboral','id_usuario'],
  select: `SELECT e.id_empleado AS id,e.nombre,e.cargo,e.identificacion,e.telefono,e.email,e.direccion,
                  e.fecha_contratacion,e.especialidad,e.estado_laboral,e.id_usuario,u.nombre_usuario AS usuario
           FROM EMPLEADOS e
           LEFT JOIN USUARIOS u ON u.id_usuario=e.id_usuario
           ORDER BY e.nombre`
});
