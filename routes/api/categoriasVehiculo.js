const { createCrudRouter } = require('./crud');
module.exports = createCrudRouter({ table:'CATEGORIAS_VEHICULO', id:'id_categoria_vehiculo', columns:['nombre','activo'], select:'SELECT id_categoria_vehiculo AS id,nombre,activo FROM CATEGORIAS_VEHICULO ORDER BY nombre' });
