const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'VEHICULOS',
  id: 'id_vehiculo',
  columns: [
    'id_cliente',
    'placa',
    'vin',
    'id_marca',
    'id_modelo',
    'anio',
    'id_tipo_vehiculo',
    'id_tipo_combustible',
    'id_categoria_vehiculo',
    'id_vehiculo_catalogo',
    'color',
    'cilindraje',
    'kilometraje',
    'fecha_ingreso',
    'observaciones',
    'activo'
  ],
  select: `
    SELECT
      v.id_vehiculo AS id,
      v.id_vehiculo_catalogo,
      CONCAT(cm.nombre, ' ', cmo.nombre) AS vehiculo_catalogo,
      v.id_cliente,
      c.nombre AS cliente,
      v.placa,
      v.vin,
      v.id_marca,
      m.nombre AS marca,
      v.id_modelo,
      mo.nombre AS modelo,
      v.anio,
      v.id_tipo_vehiculo,
      tv.nombre AS tipo_vehiculo,
      v.id_tipo_combustible,
      tc.nombre AS tipo_combustible,
      v.id_categoria_vehiculo,
      cv.nombre AS categoria_vehiculo,
      v.color,
      v.cilindraje,
      v.kilometraje,
      v.fecha_ingreso,
      v.observaciones,
      v.activo
    FROM VEHICULOS v
    INNER JOIN CLIENTES c ON c.id_cliente = v.id_cliente
    LEFT JOIN MARCAS_VEHICULO m ON m.id_marca = v.id_marca
    LEFT JOIN MODELOS_VEHICULO mo ON mo.id_modelo = v.id_modelo
    LEFT JOIN TIPOS_VEHICULO tv ON tv.id_tipo_vehiculo = v.id_tipo_vehiculo
    LEFT JOIN TIPOS_COMBUSTIBLE tc ON tc.id_tipo_combustible = v.id_tipo_combustible
    LEFT JOIN CATEGORIAS_VEHICULO cv ON cv.id_categoria_vehiculo = v.id_categoria_vehiculo
    LEFT JOIN VEHICULOS_CATALOGO vc ON vc.id_vehiculo_catalogo=v.id_vehiculo_catalogo
    LEFT JOIN MARCAS_VEHICULO cm ON cm.id_marca=vc.id_marca
    LEFT JOIN MODELOS_VEHICULO cmo ON cmo.id_modelo=vc.id_modelo
    ORDER BY v.placa
  `
});
