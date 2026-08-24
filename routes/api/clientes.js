const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'CLIENTES',
  id: 'id_cliente',
  columns: ['nombre','telefono','email','identificacion','tipo_cliente','direccion','activo'],
  select: `SELECT id_cliente AS id,nombre,telefono,email,identificacion,tipo_cliente,direccion,activo
           FROM CLIENTES ORDER BY nombre`
});
