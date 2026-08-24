const express = require('express');
const { query } = require('../bd');
const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const [clientes, vehiculos, empleados, servicios, proveedores, repuestos, usuarios,
      marcas, modelos, tiposVehiculo, tiposCombustible, categoriasVehiculo, categoriasServicio] = await Promise.all([
      query('SELECT id_cliente AS id,nombre,telefono,email FROM CLIENTES WHERE activo=1 ORDER BY nombre'),
      query(`
        SELECT
          v.id_vehiculo AS id,
          v.id_vehiculo_catalogo,
          CONCAT(cm.nombre, ' ', cmo.nombre) AS vehiculo_catalogo,
          v.id_cliente,
          c.nombre AS cliente,
          v.placa,
          v.vin,
          v.id_marca,
          m.nombre AS marca,
          v.id_modelo,
          mo.nombre AS modelo,
          v.anio,
          v.id_tipo_vehiculo,
          tv.nombre AS tipo_vehiculo,
          v.id_tipo_combustible,
          tc.nombre AS tipo_combustible,
          v.id_categoria_vehiculo,
          cv.nombre AS categoria_vehiculo,
          v.color,
          v.cilindraje,
          v.kilometraje,
          v.fecha_ingreso,
          v.observaciones,
          v.activo
        FROM VEHICULOS v
        INNER JOIN CLIENTES c ON c.id_cliente=v.id_cliente
        LEFT JOIN MARCAS_VEHICULO m ON m.id_marca=v.id_marca
        LEFT JOIN MODELOS_VEHICULO mo ON mo.id_modelo=v.id_modelo
        LEFT JOIN TIPOS_VEHICULO tv ON tv.id_tipo_vehiculo=v.id_tipo_vehiculo
        LEFT JOIN TIPOS_COMBUSTIBLE tc ON tc.id_tipo_combustible=v.id_tipo_combustible
        LEFT JOIN CATEGORIAS_VEHICULO cv ON cv.id_categoria_vehiculo=v.id_categoria_vehiculo
        LEFT JOIN VEHICULOS_CATALOGO vc ON vc.id_vehiculo_catalogo=v.id_vehiculo_catalogo
        LEFT JOIN MARCAS_VEHICULO cm ON cm.id_marca=vc.id_marca
        LEFT JOIN MODELOS_VEHICULO cmo ON cmo.id_modelo=vc.id_modelo
        WHERE v.activo=1
        ORDER BY v.placa
      `),
      query('SELECT id_empleado AS id,nombre,cargo FROM EMPLEADOS WHERE estado_laboral=\'ACTIVO\' ORDER BY nombre'),
      query('SELECT id_servicio AS id,nombre,precio_base FROM SERVICIOS WHERE estado=\'ACTIVO\' ORDER BY nombre'),
      query('SELECT id_proveedor AS id,nombre_empresa FROM PROVEEDORES WHERE estado=\'ACTIVO\' ORDER BY nombre_empresa'),
      query('SELECT id_repuesto AS id,nombre,stock_actual,precio_venta FROM REPUESTOS WHERE estado=\'ACTIVO\' ORDER BY nombre'),
      query('SELECT id_usuario AS id,nombre_usuario,email,activo FROM USUARIOS WHERE activo=1 ORDER BY nombre_usuario'),
      query('SELECT id_marca AS id,nombre FROM MARCAS_VEHICULO WHERE activo=1 ORDER BY nombre'),
      query('SELECT id_modelo AS id,id_marca,nombre FROM MODELOS_VEHICULO WHERE activo=1 ORDER BY nombre'),
      query('SELECT id_tipo_vehiculo AS id,nombre FROM TIPOS_VEHICULO WHERE activo=1 ORDER BY nombre'),
      query('SELECT id_tipo_combustible AS id,nombre FROM TIPOS_COMBUSTIBLE WHERE activo=1 ORDER BY nombre'),
      query('SELECT id_categoria_vehiculo AS id,nombre FROM CATEGORIAS_VEHICULO WHERE activo=1 ORDER BY nombre'),
      query('SELECT id_categoria_servicio AS id,nombre FROM CATEGORIAS_SERVICIO WHERE activo=1 ORDER BY nombre')
    ]);

    res.json({
      clientes: clientes.recordset,
      vehiculos: vehiculos.recordset,
      empleados: empleados.recordset,
      servicios: servicios.recordset,
      proveedores: proveedores.recordset,
      repuestos: repuestos.recordset,
      usuarios: usuarios.recordset,
      marcas: marcas.recordset,
      modelos: modelos.recordset,
      tiposVehiculo: tiposVehiculo.recordset,
      tiposCombustible: tiposCombustible.recordset,
      categoriasVehiculo: categoriasVehiculo.recordset,
      categoriasServicio: categoriasServicio.recordset
    });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
