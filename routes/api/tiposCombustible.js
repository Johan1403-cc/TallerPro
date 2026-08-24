const { createCrudRouter } = require('./crud');
module.exports = createCrudRouter({ table:'TIPOS_COMBUSTIBLE', id:'id_tipo_combustible', columns:['nombre','activo'], select:'SELECT id_tipo_combustible AS id,nombre,activo FROM TIPOS_COMBUSTIBLE ORDER BY nombre' });
