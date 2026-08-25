const express = require('express');

const router = express.Router();
const { requireAuth, modulePermission } = require('../auth');

// Públicas
router.use('/auth', require('./auth'));
router.use('/health', require('./health'));

// Todo lo demás requiere sesión válida
router.use(requireAuth);

const modules = {
  dashboard: 'DASHBOARD',
  reportes: 'REPORTES',
  configuracion: 'CONFIGURACION',
  roles: 'ROLES',
  usuarios: 'USUARIOS',
  permisos: 'PERMISOS',
  empleados: 'EMPLEADOS',
  catalogos: 'CATALOGOS',
  'vehiculos-catalogo': 'CATALOGOS',
  marcas: 'MARCAS_VEHICULO',
  modelos: 'MODELOS_VEHICULO',
  'tipos-vehiculo': 'TIPOS_VEHICULO',
  'tipos-combustible': 'TIPOS_COMBUSTIBLE',
  'categorias-vehiculo': 'CATEGORIAS_VEHICULO',
  categorias: 'CATALOGOS',
  'categorias-servicio': 'CATEGORIAS_SERVICIO',
  clientes: 'CLIENTES',
  vehiculos: 'VEHICULOS',
  citas: 'CITAS',
  recepciones: 'RECEPCIONES',
  cotizaciones: 'COTIZACIONES',
  diagnosticos: 'DIAGNOSTICOS',
  ordenes: 'ORDENES',
  servicios: 'SERVICIOS',
  garantias: 'GARANTIAS',
  inventario: 'INVENTARIO',
  proveedores: 'PROVEEDORES',
  compras: 'COMPRAS',
  ventas: 'VENTAS',
  facturas: 'FACTURAS',
  notificaciones: 'NOTIFICACIONES'
};

function mount(path, file = path) {
  router.use(`/${path}`, modulePermission(modules[path]), require(`./${file}`));
}

mount('dashboard');
mount('reportes');
mount('configuracion');
mount('roles');
mount('usuarios');
mount('permisos');
mount('empleados');
mount('catalogos');
mount('vehiculos-catalogo', 'vehiculosCatalogo');
mount('marcas');
mount('modelos');
mount('tipos-vehiculo', 'tiposVehiculo');
mount('tipos-combustible', 'tiposCombustible');
mount('categorias-vehiculo', 'categoriasVehiculo');
mount('categorias');
mount('categorias-servicio', 'categoriasServicio');
mount('clientes');
mount('vehiculos');
mount('citas');
mount('recepciones');
mount('cotizaciones');
mount('diagnosticos');
mount('ordenes');
mount('servicios');
mount('garantias');
mount('inventario');
mount('proveedores');
mount('compras');
mount('ventas');
mount('facturas');
mount('notificaciones');

module.exports = router;
