const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'SERVICIOS',
  id: 'id_servicio',
  columns: ['nombre','precio_base','codigo','id_categoria_servicio','tiempo_estimado_min','estado','porcentaje_impuesto'],
  select: `SELECT s.id_servicio AS id,s.nombre,s.precio_base,s.codigo,s.id_categoria_servicio,
                  cs.nombre AS categoria,s.tiempo_estimado_min,s.estado,s.porcentaje_impuesto
           FROM SERVICIOS s
           LEFT JOIN CATEGORIAS_SERVICIO cs ON cs.id_categoria_servicio=s.id_categoria_servicio
           ORDER BY s.nombre`
});
