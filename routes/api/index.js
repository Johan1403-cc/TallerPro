const express = require('express');

const router = express.Router();
const { requireAuth } = require('../auth');

// Autenticación (pública)
router.use('/auth', require('./auth'));

// Salud (pública)
router.use('/health', require('./health'));

// Todo lo demás requiere una sesión válida
router.use(requireAuth);

// Infraestructura y consultas generales
router.use('/dashboard', require('./dashboard'));
router.use('/catalogos', require('./catalogos'));
router.use('/reportes', require('./reportes'));
router.use('/configuracion', require('./configuracion'));
router.use('/roles', require('./roles'));

// Módulos principales
router.use('/clientes', require('./clientes'));
router.use('/vehiculos', require('./vehiculos'));
router.use('/vehiculos-catalogo', require('./vehiculosCatalogo'));
router.use('/marcas', require('./marcas'));
router.use('/modelos', require('./modelos'));
router.use('/tipos-vehiculo', require('./tiposVehiculo'));
router.use('/tipos-combustible', require('./tiposCombustible'));
router.use('/categorias-vehiculo', require('./categoriasVehiculo'));
router.use('/empleados', require('./empleados'));
router.use('/servicios', require('./servicios'));
router.use('/proveedores', require('./proveedores'));
router.use('/categorias', require('./categorias'));
router.use('/categorias-servicio', require('./categoriasServicio'));
router.use('/inventario', require('./inventario'));
router.use('/citas', require('./citas'));
router.use('/recepciones', require('./recepciones'));
router.use('/diagnosticos', require('./diagnosticos'));
router.use('/cotizaciones', require('./cotizaciones'));
router.use('/ordenes', require('./ordenes'));
router.use('/compras', require('./compras'));
router.use('/ventas', require('./ventas'));
router.use('/facturas', require('./facturas'));
router.use('/usuarios', require('./usuarios'));
router.use('/garantias', require('./garantias'));

module.exports = router;
