const { createCrudRouter } = require('./crud');
module.exports = createCrudRouter({ table:'TIPOS_VEHICULO', id:'id_tipo_vehiculo', columns:['nombre','activo'], select:'SELECT id_tipo_vehiculo AS id,nombre,activo FROM TIPOS_VEHICULO ORDER BY nombre' });
