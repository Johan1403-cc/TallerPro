const { createCrudRouter } = require('./crud');
module.exports = createCrudRouter({
  table:'CATEGORIAS_SERVICIO',
  id:'id_categoria_servicio',
  columns:['nombre','activo'],
  select:'SELECT id_categoria_servicio AS id,nombre,activo FROM CATEGORIAS_SERVICIO ORDER BY nombre'
});
