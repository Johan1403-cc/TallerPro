const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'CATEGORIAS_REPUESTOS',
  id: 'id_categoria',
  columns: ['nombre'],
  select: 'SELECT id_categoria AS id, nombre FROM CATEGORIAS_REPUESTOS ORDER BY nombre'
});
