const express = require('express');

const router = express.Router();
const { requireAuth, requireRoles } = require('../auth');

// Autenticación y salud son públicas.
router.use('/auth', require('./auth'));
router.use('/health', require('./health'));

// Todo lo demás requiere una sesión válida.
router.use(requireAuth);

// Dashboard: cualquier usuario autenticado.
router.use('/dashboard', require('./dashboard'));

// Consultas y reportes.
router.use('/reportes', requireRoles('Administrador', 'Supervisor'), require('./reportes'));

// Administración general: solo Administrador.
router.use('/configuracion', requireRoles('Administrador'), require('./configuracion'));
router.use('/roles', requireRoles('Administrador'), require('./roles'));
router.use('/usuarios', requireRoles('Administrador'), require('./usuarios'));
router.use('/empleados', requireRoles('Administrador'), require('./empleados'));

// Catálogos generales: Administrador y Supervisor.
router.use('/catalogos', requireRoles('Administrador', 'Supervisor', 'Recepcionista', 'Mecánico', 'Encargado de inventario', 'Vendedor', 'Cajero'), require('./catalogos'));
router.use('/vehiculos-catalogo', requireRoles('Administrador', 'Supervisor', 'Recepcionista'), require('./vehiculosCatalogo'));
router.use('/marcas', requireRoles('Administrador', 'Supervisor', 'Recepcionista'), require('./marcas'));
router.use('/modelos', requireRoles('Administrador', 'Supervisor', 'Recepcionista'), require('./modelos'));
router.use('/tipos-vehiculo', requireRoles('Administrador', 'Supervisor', 'Recepcionista'), require('./tiposVehiculo'));
router.use('/tipos-combustible', requireRoles('Administrador', 'Supervisor', 'Recepcionista'), require('./tiposCombustible'));
router.use('/categorias-vehiculo', requireRoles('Administrador', 'Supervisor', 'Recepcionista'), require('./categoriasVehiculo'));
router.use('/categorias', requireRoles('Administrador', 'Supervisor', 'Encargado de inventario'), require('./categorias'));
router.use('/categorias-servicio', requireRoles('Administrador', 'Supervisor', 'Mecánico'), require('./categoriasServicio'));

// Recepción / atención al cliente.
router.use('/clientes', requireRoles('Administrador', 'Supervisor', 'Recepcionista', 'Vendedor', 'Cajero'), require('./clientes'));
router.use('/vehiculos', requireRoles('Administrador', 'Supervisor', 'Recepcionista', 'Mecánico'), require('./vehiculos'));
router.use('/citas', requireRoles('Administrador', 'Supervisor', 'Recepcionista'), require('./citas'));
router.use('/recepciones', requireRoles('Administrador', 'Supervisor', 'Recepcionista', 'Mecánico'), require('./recepciones'));
router.use('/cotizaciones', requireRoles('Administrador', 'Supervisor', 'Recepcionista', 'Mecánico'), require('./cotizaciones'));

// Operación del taller.
router.use('/diagnosticos', requireRoles('Administrador', 'Supervisor', 'Mecánico'), require('./diagnosticos'));
router.use('/ordenes', requireRoles('Administrador', 'Supervisor', 'Mecánico'), require('./ordenes'));
router.use('/servicios', requireRoles('Administrador', 'Supervisor', 'Mecánico'), require('./servicios'));
router.use('/garantias', requireRoles('Administrador', 'Supervisor', 'Recepcionista', 'Mecánico'), require('./garantias'));

// Inventario y abastecimiento.
router.use('/inventario', requireRoles('Administrador', 'Supervisor', 'Encargado de inventario', 'Vendedor'), require('./inventario'));
router.use('/proveedores', requireRoles('Administrador', 'Supervisor', 'Encargado de inventario'), require('./proveedores'));
router.use('/compras', requireRoles('Administrador', 'Supervisor', 'Encargado de inventario'), require('./compras'));

// Ventas y caja.
router.use('/ventas', requireRoles('Administrador', 'Supervisor', 'Vendedor', 'Cajero'), require('./ventas'));
router.use('/facturas', requireRoles('Administrador', 'Supervisor', 'Cajero'), require('./facturas'));

module.exports = router;
