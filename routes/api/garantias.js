const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'GARANTIAS',
  id: 'id_garantia',
  columns: ['tipo_garantia', 'id_orden', 'id_venta', 'descripcion_cubierto', 'fecha_inicio', 'fecha_vencimiento', 'condiciones', 'estado', 'observaciones'],
  select: 'SELECT g.id_garantia AS id, g.tipo_garantia, g.id_orden, g.id_venta, g.descripcion_cubierto, g.fecha_inicio, g.fecha_vencimiento, g.condiciones, g.estado, g.observaciones FROM GARANTIAS g ORDER BY g.fecha_vencimiento DESC'
});
