const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'VEHICULOS_CATALOGO',
  id: 'id_vehiculo_catalogo',
  columns: [
    'id_marca',
    'id_modelo',
    'id_tipo_vehiculo',
    'id_tipo_combustible',
    'id_categoria_vehiculo',
    'activo'
  ],
  select: `
    SELECT
      vc.id_vehiculo_catalogo AS id,
      vc.id_marca,
      m.nombre AS marca,
      vc.id_modelo,
      mo.nombre AS modelo,
      vc.id_tipo_vehiculo,
      tv.nombre AS tipo_vehiculo,
      vc.id_tipo_combustible,
      tc.nombre AS tipo_combustible,
      vc.id_categoria_vehiculo,
      cv.nombre AS categoria_vehiculo,
      vc.activo
    FROM VEHICULOS_CATALOGO vc
    INNER JOIN MARCAS_VEHICULO m ON m.id_marca=vc.id_marca
    INNER JOIN MODELOS_VEHICULO mo ON mo.id_modelo=vc.id_modelo
    LEFT JOIN TIPOS_VEHICULO tv ON tv.id_tipo_vehiculo=vc.id_tipo_vehiculo
    INNER JOIN TIPOS_COMBUSTIBLE tc ON tc.id_tipo_combustible=vc.id_tipo_combustible
    INNER JOIN CATEGORIAS_VEHICULO cv ON cv.id_categoria_vehiculo=vc.id_categoria_vehiculo
    ORDER BY m.nombre, mo.nombre, cv.nombre
  `
});
