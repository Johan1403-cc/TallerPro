const { createCrudRouter } = require('./crud');

module.exports = createCrudRouter({
  table: 'PROVEEDORES',
  id: 'id_proveedor',
  columns: ['nombre_empresa','identificacion','telefono','email','direccion','contacto_principal','condiciones_pago','estado'],
  select: `SELECT id_proveedor AS id,nombre_empresa,identificacion,telefono,email,direccion,
                  contacto_principal,condiciones_pago,estado
           FROM PROVEEDORES ORDER BY nombre_empresa`
});
