const { createCrudRouter } = require('./crud');
module.exports = createCrudRouter({ table:'MARCAS_VEHICULO', id:'id_marca', columns:['nombre','activo'], select:'SELECT id_marca AS id,nombre,activo FROM MARCAS_VEHICULO ORDER BY nombre' });
