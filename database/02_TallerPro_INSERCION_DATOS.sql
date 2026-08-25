/* ============================================================
   TallerProDB - SCRIPT FINAL CONSOLIDADO DE INSERCION DE DATOS
   Requiere ejecutar primero: 01_TallerPro_CREACION_BD.sql
   Diseñado para una base recién creada y vacía.

   Incluye como mínimo:
   - 50 clientes
   - 75 vehículos
   - 15 empleados
   - 15 usuarios (supera el mínimo de 10)
   - 7 roles
   - 79 permisos (supera el mínimo de 30)
   - 50 productos/repuestos
   - 15 servicios
   - 10 proveedores
   - 100 órdenes de trabajo
   - 250 movimientos de inventario (supera el mínimo de 150)
   - 100 ventas
   - 160 facturas (100 de ventas + 60 de órdenes; supera el mínimo de 100)
   ============================================================ */
USE TallerProDB;
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS(SELECT 1 FROM Roles) OR EXISTS(SELECT 1 FROM Clientes) OR EXISTS(SELECT 1 FROM Productos)
    THROW 51000, 'Este script debe ejecutarse sobre TallerProDB recién creada y sin datos de prueba.', 1;

BEGIN TRY
BEGIN TRANSACTION;

/* ================= CONFIGURACIÓN GENERAL ================= */
INSERT ConfiguracionGeneral(NombreTaller,IdentificacionJuridica,Direccion,Telefono,Correo,PorcentajeImpuestoGeneral,Moneda,LimiteDescuento,HorarioAtencion,PlazoGarantiaDias,ExistenciaMinimaPredeterminada)
VALUES(N'TallerPro Centro Automotriz',N'3-101-999999',N'Cartago, Costa Rica, 300 m este del centro',N'2550-2026',N'info@tallerpro.cr',13,N'CRC',10,N'Lunes a sábado de 7:30 a.m. a 5:30 p.m.',90,5);

INSERT FormasPago(Nombre,RequiereReferencia,Activa) VALUES
(N'EFECTIVO',0,1),(N'TARJETA',1,1),(N'TRANSFERENCIA',1,1),(N'SINPE MOVIL',1,1),(N'CREDITO',0,1);
INSERT Bodegas(Nombre,Ubicacion,Activa) VALUES
(N'Bodega Principal',N'Zona posterior del taller',1),(N'Bodega Secundaria',N'Área de repuestos de alta rotación',1);

/* ================= ROLES Y PERMISOS ================= */
INSERT Roles(Nombre,Descripcion) VALUES
(N'Administrador',N'Rol operativo de Administrador'),
(N'Recepcionista',N'Rol operativo de Recepcionista'),
(N'Mecánico',N'Rol operativo de Mecánico'),
(N'Encargado de inventario',N'Rol operativo de Encargado de inventario'),
(N'Vendedor',N'Rol operativo de Vendedor'),
(N'Cajero',N'Rol operativo de Cajero'),
(N'Supervisor o gerente',N'Rol operativo de Supervisor o gerente');
INSERT Permisos(Codigo,Nombre,Modulo,Descripcion) VALUES
('CLIENTES_CONSULTAR',N'Consultar clientes',N'CLIENTES',N'Permiso de consultar clientes'),
('CLIENTES_REGISTRAR',N'Registrar clientes',N'CLIENTES',N'Permiso de registrar clientes'),
('CLIENTES_MODIFICAR',N'Modificar clientes',N'CLIENTES',N'Permiso de modificar clientes'),
('CLIENTES_DESACTIVAR',N'Desactivar clientes',N'CLIENTES',N'Permiso de desactivar clientes'),
('EMPLEADOS_CONSULTAR',N'Consultar empleados',N'EMPLEADOS',N'Permiso de consultar empleados'),
('EMPLEADOS_REGISTRAR',N'Registrar empleados',N'EMPLEADOS',N'Permiso de registrar empleados'),
('EMPLEADOS_MODIFICAR',N'Modificar empleados',N'EMPLEADOS',N'Permiso de modificar empleados'),
('EMPLEADOS_DESACTIVAR',N'Desactivar empleados',N'EMPLEADOS',N'Permiso de desactivar empleados'),
('CATALOGOS_CONSULTAR',N'Consultar catalogos',N'CATALOGOS',N'Permiso de consultar catalogos'),
('CATALOGOS_REGISTRAR',N'Registrar catalogos',N'CATALOGOS',N'Permiso de registrar catalogos'),
('CATALOGOS_MODIFICAR',N'Modificar catalogos',N'CATALOGOS',N'Permiso de modificar catalogos'),
('CATALOGOS_DESACTIVAR',N'Desactivar catalogos',N'CATALOGOS',N'Permiso de desactivar catalogos'),
('VEHICULOS_CONSULTAR',N'Consultar vehiculos',N'VEHICULOS',N'Permiso de consultar vehiculos'),
('VEHICULOS_REGISTRAR',N'Registrar vehiculos',N'VEHICULOS',N'Permiso de registrar vehiculos'),
('VEHICULOS_MODIFICAR',N'Modificar vehiculos',N'VEHICULOS',N'Permiso de modificar vehiculos'),
('VEHICULOS_DESACTIVAR',N'Desactivar vehiculos',N'VEHICULOS',N'Permiso de desactivar vehiculos'),
('SERVICIOS_CONSULTAR',N'Consultar servicios',N'SERVICIOS',N'Permiso de consultar servicios'),
('SERVICIOS_REGISTRAR',N'Registrar servicios',N'SERVICIOS',N'Permiso de registrar servicios'),
('SERVICIOS_MODIFICAR',N'Modificar servicios',N'SERVICIOS',N'Permiso de modificar servicios'),
('SERVICIOS_DESACTIVAR',N'Desactivar servicios',N'SERVICIOS',N'Permiso de desactivar servicios'),
('PRODUCTOS_CONSULTAR',N'Consultar productos',N'PRODUCTOS',N'Permiso de consultar productos'),
('PRODUCTOS_REGISTRAR',N'Registrar productos',N'PRODUCTOS',N'Permiso de registrar productos'),
('PRODUCTOS_MODIFICAR',N'Modificar productos',N'PRODUCTOS',N'Permiso de modificar productos'),
('PRODUCTOS_DESACTIVAR',N'Desactivar productos',N'PRODUCTOS',N'Permiso de desactivar productos'),
('PROVEEDORES_CONSULTAR',N'Consultar proveedores',N'PROVEEDORES',N'Permiso de consultar proveedores'),
('PROVEEDORES_REGISTRAR',N'Registrar proveedores',N'PROVEEDORES',N'Permiso de registrar proveedores'),
('PROVEEDORES_MODIFICAR',N'Modificar proveedores',N'PROVEEDORES',N'Permiso de modificar proveedores'),
('PROVEEDORES_DESACTIVAR',N'Desactivar proveedores',N'PROVEEDORES',N'Permiso de desactivar proveedores'),
('CITAS_CONSULTAR',N'Consultar citas',N'CITAS',N'Permiso de consultar citas'),
('CITAS_REGISTRAR',N'Registrar citas',N'CITAS',N'Permiso de registrar citas'),
('CITAS_MODIFICAR',N'Modificar citas',N'CITAS',N'Permiso de modificar citas'),
('CITAS_DESACTIVAR',N'Desactivar citas',N'CITAS',N'Permiso de desactivar citas'),
('RECEPCIONES_CONSULTAR',N'Consultar recepciones',N'RECEPCIONES',N'Permiso de consultar recepciones'),
('RECEPCIONES_REGISTRAR',N'Registrar recepciones',N'RECEPCIONES',N'Permiso de registrar recepciones'),
('RECEPCIONES_MODIFICAR',N'Modificar recepciones',N'RECEPCIONES',N'Permiso de modificar recepciones'),
('RECEPCIONES_DESACTIVAR',N'Desactivar recepciones',N'RECEPCIONES',N'Permiso de desactivar recepciones'),
('DIAGNOSTICOS_CONSULTAR',N'Consultar diagnosticos',N'DIAGNOSTICOS',N'Permiso de consultar diagnosticos'),
('DIAGNOSTICOS_REGISTRAR',N'Registrar diagnosticos',N'DIAGNOSTICOS',N'Permiso de registrar diagnosticos'),
('DIAGNOSTICOS_MODIFICAR',N'Modificar diagnosticos',N'DIAGNOSTICOS',N'Permiso de modificar diagnosticos'),
('DIAGNOSTICOS_DESACTIVAR',N'Desactivar diagnosticos',N'DIAGNOSTICOS',N'Permiso de desactivar diagnosticos'),
('COTIZACIONES_CONSULTAR',N'Consultar cotizaciones',N'COTIZACIONES',N'Permiso de consultar cotizaciones'),
('COTIZACIONES_REGISTRAR',N'Registrar cotizaciones',N'COTIZACIONES',N'Permiso de registrar cotizaciones'),
('COTIZACIONES_MODIFICAR',N'Modificar cotizaciones',N'COTIZACIONES',N'Permiso de modificar cotizaciones'),
('COTIZACIONES_DESACTIVAR',N'Desactivar cotizaciones',N'COTIZACIONES',N'Permiso de desactivar cotizaciones'),
('ORDENES_CONSULTAR',N'Consultar ordenes',N'ORDENES',N'Permiso de consultar ordenes'),
('ORDENES_REGISTRAR',N'Registrar ordenes',N'ORDENES',N'Permiso de registrar ordenes'),
('ORDENES_MODIFICAR',N'Modificar ordenes',N'ORDENES',N'Permiso de modificar ordenes'),
('ORDENES_DESACTIVAR',N'Desactivar ordenes',N'ORDENES',N'Permiso de desactivar ordenes'),
('GARANTIAS_CONSULTAR',N'Consultar garantias',N'GARANTIAS',N'Permiso de consultar garantias'),
('GARANTIAS_REGISTRAR',N'Registrar garantias',N'GARANTIAS',N'Permiso de registrar garantias'),
('GARANTIAS_MODIFICAR',N'Modificar garantias',N'GARANTIAS',N'Permiso de modificar garantias'),
('GARANTIAS_DESACTIVAR',N'Desactivar garantias',N'GARANTIAS',N'Permiso de desactivar garantias'),
('CONFIGURACION_CONSULTAR',N'Consultar configuracion',N'CONFIGURACION',N'Permiso de consultar configuracion'),
('CONFIGURACION_REGISTRAR',N'Registrar configuracion',N'CONFIGURACION',N'Permiso de registrar configuracion'),
('CONFIGURACION_MODIFICAR',N'Modificar configuracion',N'CONFIGURACION',N'Permiso de modificar configuracion'),
('CONFIGURACION_DESACTIVAR',N'Desactivar configuracion',N'CONFIGURACION',N'Permiso de desactivar configuracion'),
('ADMIN_TOTAL',N'Acceso administrativo total',N'ADMINISTRACION',N'Permiso de acceso administrativo total'),
('USUARIOS_ADMINISTRAR',N'Administrar usuarios, roles y permisos',N'SEGURIDAD',N'Permiso de administrar usuarios, roles y permisos'),
('COTIZACIONES_APROBAR',N'Aprobar cotizaciones',N'COTIZACIONES',N'Permiso de aprobar cotizaciones'),
('DIAGNOSTICOS_APROBAR',N'Aprobar diagnósticos',N'DIAGNOSTICOS',N'Permiso de aprobar diagnósticos'),
('ORDENES_APROBAR',N'Aprobar órdenes de trabajo',N'ORDENES',N'Permiso de aprobar órdenes de trabajo'),
('ORDENES_MODIFICAR_FINALIZADA',N'Modificar órdenes cerradas con autorización',N'ORDENES',N'Permiso de modificar órdenes cerradas con autorización'),
('COMPRAS_REGISTRAR',N'Registrar y confirmar compras',N'COMPRAS',N'Permiso de registrar y confirmar compras'),
('COMPRAS_CONSULTAR',N'Consultar compras',N'COMPRAS',N'Permiso de consultar compras'),
('VENTAS_REGISTRAR',N'Registrar y confirmar ventas',N'VENTAS',N'Permiso de registrar y confirmar ventas'),
('VENTAS_CONSULTAR',N'Consultar ventas',N'VENTAS',N'Permiso de consultar ventas'),
('VENTAS_ANULAR',N'Anular ventas',N'VENTAS',N'Permiso de anular ventas'),
('FACTURAS_REGISTRAR',N'Emitir facturas',N'FACTURACION',N'Permiso de emitir facturas'),
('FACTURAS_CONSULTAR',N'Consultar facturas',N'FACTURACION',N'Permiso de consultar facturas'),
('FACTURAS_ANULAR',N'Anular facturas',N'FACTURACION',N'Permiso de anular facturas'),
('PAGOS_REGISTRAR',N'Registrar pagos',N'PAGOS',N'Permiso de registrar pagos'),
('PAGOS_CONSULTAR',N'Consultar pagos',N'PAGOS',N'Permiso de consultar pagos'),
('DESCUENTOS_APLICAR',N'Aplicar descuentos dentro del límite',N'VENTAS',N'Permiso de aplicar descuentos dentro del límite'),
('DESCUENTOS_SUPERIOR_LIMITE',N'Autorizar descuentos superiores al límite',N'VENTAS',N'Permiso de autorizar descuentos superiores al límite'),
('INVENTARIO_CONSULTAR',N'Consultar inventario',N'INVENTARIO',N'Permiso de consultar inventario'),
('INVENTARIO_AJUSTAR',N'Registrar ajustes de inventario',N'INVENTARIO',N'Permiso de registrar ajustes de inventario'),
('INVENTARIO_NEGATIVO',N'Autorizar existencia negativa',N'INVENTARIO',N'Permiso de autorizar existencia negativa'),
('REPORTES_CONSULTAR',N'Consultar reportes',N'REPORTES',N'Permiso de consultar reportes'),
('AUDITORIA_CONSULTAR',N'Consultar bitácora de auditoría',N'AUDITORIA',N'Permiso de consultar bitácora de auditoría');
INSERT RolPermisos(RolId,PermisoId)
SELECT r.RolId,p.PermisoId FROM Roles r CROSS JOIN Permisos p
WHERE r.Nombre=N'Administrador' AND p.Codigo IN('CLIENTES_CONSULTAR','CLIENTES_REGISTRAR','CLIENTES_MODIFICAR','CLIENTES_DESACTIVAR','EMPLEADOS_CONSULTAR','EMPLEADOS_REGISTRAR','EMPLEADOS_MODIFICAR','EMPLEADOS_DESACTIVAR','CATALOGOS_CONSULTAR','CATALOGOS_REGISTRAR','CATALOGOS_MODIFICAR','CATALOGOS_DESACTIVAR','VEHICULOS_CONSULTAR','VEHICULOS_REGISTRAR','VEHICULOS_MODIFICAR','VEHICULOS_DESACTIVAR','SERVICIOS_CONSULTAR','SERVICIOS_REGISTRAR','SERVICIOS_MODIFICAR','SERVICIOS_DESACTIVAR','PRODUCTOS_CONSULTAR','PRODUCTOS_REGISTRAR','PRODUCTOS_MODIFICAR','PRODUCTOS_DESACTIVAR','PROVEEDORES_CONSULTAR','PROVEEDORES_REGISTRAR','PROVEEDORES_MODIFICAR','PROVEEDORES_DESACTIVAR','CITAS_CONSULTAR','CITAS_REGISTRAR','CITAS_MODIFICAR','CITAS_DESACTIVAR','RECEPCIONES_CONSULTAR','RECEPCIONES_REGISTRAR','RECEPCIONES_MODIFICAR','RECEPCIONES_DESACTIVAR','DIAGNOSTICOS_CONSULTAR','DIAGNOSTICOS_REGISTRAR','DIAGNOSTICOS_MODIFICAR','DIAGNOSTICOS_DESACTIVAR','COTIZACIONES_CONSULTAR','COTIZACIONES_REGISTRAR','COTIZACIONES_MODIFICAR','COTIZACIONES_DESACTIVAR','ORDENES_CONSULTAR','ORDENES_REGISTRAR','ORDENES_MODIFICAR','ORDENES_DESACTIVAR','GARANTIAS_CONSULTAR','GARANTIAS_REGISTRAR','GARANTIAS_MODIFICAR','GARANTIAS_DESACTIVAR','CONFIGURACION_CONSULTAR','CONFIGURACION_REGISTRAR','CONFIGURACION_MODIFICAR','CONFIGURACION_DESACTIVAR','ADMIN_TOTAL','USUARIOS_ADMINISTRAR','COTIZACIONES_APROBAR','DIAGNOSTICOS_APROBAR','ORDENES_APROBAR','ORDENES_MODIFICAR_FINALIZADA','COMPRAS_REGISTRAR','COMPRAS_CONSULTAR','VENTAS_REGISTRAR','VENTAS_CONSULTAR','VENTAS_ANULAR','FACTURAS_REGISTRAR','FACTURAS_CONSULTAR','FACTURAS_ANULAR','PAGOS_REGISTRAR','PAGOS_CONSULTAR','DESCUENTOS_APLICAR','DESCUENTOS_SUPERIOR_LIMITE','INVENTARIO_CONSULTAR','INVENTARIO_AJUSTAR','INVENTARIO_NEGATIVO','REPORTES_CONSULTAR','AUDITORIA_CONSULTAR');
INSERT RolPermisos(RolId,PermisoId)
SELECT r.RolId,p.PermisoId FROM Roles r CROSS JOIN Permisos p
WHERE r.Nombre=N'Recepcionista' AND p.Codigo IN('CLIENTES_CONSULTAR','CLIENTES_REGISTRAR','CLIENTES_MODIFICAR','CLIENTES_DESACTIVAR','VEHICULOS_CONSULTAR','VEHICULOS_REGISTRAR','VEHICULOS_MODIFICAR','VEHICULOS_DESACTIVAR','CITAS_CONSULTAR','CITAS_REGISTRAR','CITAS_MODIFICAR','CITAS_DESACTIVAR','RECEPCIONES_CONSULTAR','RECEPCIONES_REGISTRAR','RECEPCIONES_MODIFICAR','RECEPCIONES_DESACTIVAR','COTIZACIONES_CONSULTAR','ORDENES_CONSULTAR','GARANTIAS_CONSULTAR','FACTURAS_CONSULTAR','PAGOS_CONSULTAR');
INSERT RolPermisos(RolId,PermisoId)
SELECT r.RolId,p.PermisoId FROM Roles r CROSS JOIN Permisos p
WHERE r.Nombre=N'Mecánico' AND p.Codigo IN('VEHICULOS_CONSULTAR','SERVICIOS_CONSULTAR','PRODUCTOS_CONSULTAR','RECEPCIONES_CONSULTAR','DIAGNOSTICOS_CONSULTAR','DIAGNOSTICOS_REGISTRAR','DIAGNOSTICOS_MODIFICAR','DIAGNOSTICOS_DESACTIVAR','ORDENES_CONSULTAR','ORDENES_MODIFICAR','GARANTIAS_CONSULTAR','DIAGNOSTICOS_APROBAR','ORDENES_MODIFICAR_FINALIZADA','INVENTARIO_CONSULTAR');
INSERT RolPermisos(RolId,PermisoId)
SELECT r.RolId,p.PermisoId FROM Roles r CROSS JOIN Permisos p
WHERE r.Nombre=N'Encargado de inventario' AND p.Codigo IN('PRODUCTOS_CONSULTAR','PRODUCTOS_REGISTRAR','PRODUCTOS_MODIFICAR','PRODUCTOS_DESACTIVAR','PROVEEDORES_CONSULTAR','PROVEEDORES_REGISTRAR','PROVEEDORES_MODIFICAR','PROVEEDORES_DESACTIVAR','COMPRAS_REGISTRAR','COMPRAS_CONSULTAR','VENTAS_CONSULTAR','INVENTARIO_CONSULTAR','INVENTARIO_AJUSTAR','INVENTARIO_NEGATIVO');
INSERT RolPermisos(RolId,PermisoId)
SELECT r.RolId,p.PermisoId FROM Roles r CROSS JOIN Permisos p
WHERE r.Nombre=N'Vendedor' AND p.Codigo IN('CLIENTES_CONSULTAR','CLIENTES_REGISTRAR','PRODUCTOS_CONSULTAR','VENTAS_REGISTRAR','VENTAS_CONSULTAR','FACTURAS_CONSULTAR','DESCUENTOS_APLICAR');
INSERT RolPermisos(RolId,PermisoId)
SELECT r.RolId,p.PermisoId FROM Roles r CROSS JOIN Permisos p
WHERE r.Nombre=N'Cajero' AND p.Codigo IN('CLIENTES_CONSULTAR','VENTAS_CONSULTAR','FACTURAS_REGISTRAR','FACTURAS_CONSULTAR','PAGOS_REGISTRAR','PAGOS_CONSULTAR','DESCUENTOS_APLICAR');
INSERT RolPermisos(RolId,PermisoId)
SELECT r.RolId,p.PermisoId FROM Roles r CROSS JOIN Permisos p
WHERE r.Nombre=N'Supervisor o gerente' AND p.Codigo IN('CLIENTES_CONSULTAR','EMPLEADOS_CONSULTAR','CATALOGOS_CONSULTAR','VEHICULOS_CONSULTAR','SERVICIOS_CONSULTAR','PRODUCTOS_CONSULTAR','PROVEEDORES_CONSULTAR','CITAS_CONSULTAR','RECEPCIONES_CONSULTAR','DIAGNOSTICOS_CONSULTAR','COTIZACIONES_CONSULTAR','ORDENES_CONSULTAR','GARANTIAS_CONSULTAR','CONFIGURACION_CONSULTAR','COTIZACIONES_APROBAR','DIAGNOSTICOS_APROBAR','ORDENES_APROBAR','ORDENES_MODIFICAR_FINALIZADA','COMPRAS_CONSULTAR','VENTAS_CONSULTAR','VENTAS_ANULAR','FACTURAS_CONSULTAR','FACTURAS_ANULAR','PAGOS_CONSULTAR','DESCUENTOS_APLICAR','DESCUENTOS_SUPERIOR_LIMITE','INVENTARIO_CONSULTAR','REPORTES_CONSULTAR','AUDITORIA_CONSULTAR');
/* ================= USUARIOS Y EMPLEADOS =================
   Credenciales:
   admin / Admin2026!
   todos los demás usuarios / TallerPro2026!
   Las claves están almacenadas con scrypt + sal, no en texto plano.
*/
INSERT Usuarios(NombreUsuario,Correo,PasswordSalt,PasswordHash,Activo,DebeCambiarPassword) VALUES
(N'admin',N'admin@tallerpro.cr','38571dcceed0fad07e87d69dee5527ec','e3c35875af1785ea8a239bf4451ec89d52be225ec866ff45203608a9356096611eba16ec7fead5ff5a68f4774ac0526db6e997c374e2dfce157136b95e9db950',1,0),
(N'recepcion1',N'recepcion1@tallerpro.cr','8042361c59f60a33208cf8860d7c89ac','2d8a4f48146c27538f99ae41acb26077ae173b542c81d9fc0d01421b6a3dfcb7e55af80e0180d7c504902fd84e0dd2d7cc87386289a119f6ecc5ca96ce292f59',1,0),
(N'mecanico1',N'mecanico1@tallerpro.cr','a131c764cccb31ca362450e6b0f7ebc9','40306aa608131a8aa8b2d993f124d55bb6af45b1f791e80f5401796256954be85cc7d68f3a531bf91fbd635ae2425627edb448376ede75aa8b6be5e892fae026',1,0),
(N'mecanico2',N'mecanico2@tallerpro.cr','b3522693c982030b4656f6c3391e1fa7','b5c64ee851c0aea1591ba13b6ec46324a42b96d53379d9c65f8b0feca747fd563245e6f031ad43d01297cd4ba31931a42caf7ada3ec976c69c78b68aa44e9452',1,0),
(N'inventario1',N'inventario1@tallerpro.cr','f642c67c4c6f5183d822183028da1ba0','eaea085fc36a7d8e9474cfd9d33c6b3fc715189555e8dbe4d227cba73d798106629f5b4a47cf18b6f8656b0394ba2b53b5ea808c4daba10205d93f9e0641ece8',1,0),
(N'vendedor1',N'vendedor1@tallerpro.cr','283d3d2c5e5ca0dc7fd893467cbc2b43','85cdd05e6528e140cc5c494d9cfad58a1a4dd3609caf676beec291f6cf007d99581c5998caa353e112596544371342903a260a428d1fc425a6e87c736be53e52',1,0),
(N'cajero1',N'cajero1@tallerpro.cr','a9f26b37a9591dc236be5fcc4ce12e4a','67e01febba78deefa52ea3ef6e2498307f34dbfa9c781b242ec6cd48c61315f034d2f36aa93103459694b3d379b9063ccb55193183baa1d4feba6b3cbb4048f9',1,0),
(N'gerente1',N'gerente1@tallerpro.cr','430cd3372d0174a74e6b53eb4797ad87','29480a9092fe9e785086837b17e7ba21064ed7a3e4c7b75a6a6a8d946a924a32e4725a79c4bb0ff1db7628bdb5369301320d84b83bf0d4fcda3430a203dd1666',1,0),
(N'recepcion2',N'recepcion2@tallerpro.cr','0a4b962df42c577a2c58ded55901ccf7','b9135320ec5e265e0a7bde4541fa744c53a48629a06a09f67bc6bbaafcb6dae708dca5a3d82575086a2ffac600fe56f965119566eb8280605b5110e01f3e50a7',1,0),
(N'mecanico3',N'mecanico3@tallerpro.cr','0274eb961858dbff8db5c00ca1dfd8d1','315f184ef1759dbabbf0fac7e6dfe998e702475dfa921d35b316a32eef08cf81df4addea587e8565d8a24c60014d7c97bc26cb37149909b96a5f17e13fd80e6f',1,0),
(N'mecanico4',N'mecanico4@tallerpro.cr','3222c74a87f987c7722dc26cd5e58173','cc63f85afaa6def3d55f453e6d28c2288374f28bc8b5e398bc3925db9f46a424bc08925fae9afe19ad1f0720eb0fc4ac34272a45b164be356630b2063aacf6d5',1,0),
(N'mecanico5',N'mecanico5@tallerpro.cr','c07822d9994ff20c7c5771060f91f5a0','801e93cc336235beab60ba2ced395694c8856db0aac69933bcb27ce502d5effa1e90f87bb600d96485f183323cb0962697f53d5f3be3367f8a98d913113d5a56',1,0),
(N'mecanico6',N'mecanico6@tallerpro.cr','ff9ddaeb98a8db0fab35e43902f04beb','a9025acd1ef2484e91e6619a95a8897bbed6dd71efe8dc4741e65b09854c3dab48fd28d752dd967f34238d692d0e66b16beaa8af8253b82215103614bca939ec',1,0),
(N'inventario2',N'inventario2@tallerpro.cr','e4c8c16f5c98569462d3038e020a303c','463e18bd6d4309307a61e22d427ced448dca7ae72c09a5af831b4bcd89bd251b950101130b91466e50b2f4b4a453ab77e57d9c1d06f7497070d14cef8ad87d30',1,0),
(N'vendedor2',N'vendedor2@tallerpro.cr','f98551b4f90b2df9d9f0e17d983203b1','638a208377f3e82bb285e2734cc578e82ed0469d023ff6062c9a864cc6154f0d3b978c6f4b1bf8110b72591d78757930f18cad08c753c736e55d486d716a8442',1,0);
INSERT UsuarioRoles(UsuarioId,RolId)
SELECT u.UsuarioId,r.RolId FROM (VALUES
(N'admin',N'Administrador'),
(N'recepcion1',N'Recepcionista'),
(N'mecanico1',N'Mecánico'),
(N'mecanico2',N'Mecánico'),
(N'inventario1',N'Encargado de inventario'),
(N'vendedor1',N'Vendedor'),
(N'cajero1',N'Cajero'),
(N'gerente1',N'Supervisor o gerente'),
(N'recepcion2',N'Recepcionista'),
(N'mecanico3',N'Mecánico'),
(N'mecanico4',N'Mecánico'),
(N'mecanico5',N'Mecánico'),
(N'mecanico6',N'Mecánico'),
(N'inventario2',N'Encargado de inventario'),
(N'vendedor2',N'Vendedor')
) x(Usuario,Rol) JOIN Usuarios u ON u.NombreUsuario=x.Usuario JOIN Roles r ON r.Nombre=x.Rol;
INSERT Empleados(Identificacion,NombreCompleto,Telefono,Correo,Direccion,FechaContratacion,Especialidad,EstadoLaboral,UsuarioId) VALUES
(N'1-1111-1111',N'Carlos Andrés Vargas Mora',N'7001-1001',N'carlos.vargas@tallerpro.cr',N'San José, Desamparados','2021-01-15',N'Administración general',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'admin')),
(N'1-2222-2222',N'María Fernanda Rojas Solano',N'7001-1002',N'maria.rojas@tallerpro.cr',N'Cartago, El Carmen','2022-03-01',N'Recepción y servicio al cliente',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'recepcion1')),
(N'3-3333-3333',N'José Manuel Jiménez Araya',N'7001-1003',N'jose.jimenez@tallerpro.cr',N'Cartago, Paraíso','2020-06-10',N'Mecánica general',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'mecanico1')),
(N'3-4444-4444',N'Andrés Felipe Quesada León',N'7001-1004',N'andres.quesada@tallerpro.cr',N'Cartago, Oreamuno','2021-09-20',N'Diagnóstico electrónico',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'mecanico2')),
(N'2-5555-5555',N'Laura Sofía Ramírez Castro',N'7001-1005',N'laura.ramirez@tallerpro.cr',N'San José, Curridabat','2023-02-13',N'Inventario y bodega',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'inventario1')),
(N'1-6666-6666',N'Daniel Esteban Mora Chaves',N'7001-1006',N'daniel.mora@tallerpro.cr',N'Heredia, San Francisco','2022-11-07',N'Ventas de repuestos',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'vendedor1')),
(N'4-7777-7777',N'Paola Andrea Brenes Soto',N'7001-1007',N'paola.brenes@tallerpro.cr',N'Alajuela, Centro','2024-01-08',N'Caja y facturación',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'cajero1')),
(N'2-8888-8888',N'Roberto Enrique Salas Vega',N'7001-1008',N'roberto.salas@tallerpro.cr',N'Heredia, Santo Domingo','2019-05-06',N'Supervisión de operaciones',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'gerente1')),
(N'3-9999-9999',N'Valeria María Cordero Arias',N'7001-1009',N'valeria.cordero@tallerpro.cr',N'Cartago, La Unión','2023-07-17',N'Recepción y agenda',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'recepcion2')),
(N'1-1010-1010',N'Kevin Alonso Hernández Ruiz',N'7001-1010',N'kevin.hernandez@tallerpro.cr',N'San José, Goicoechea','2022-04-25',N'Frenos y suspensión',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'mecanico3')),
(N'2-1111-1212',N'Luis Diego Campos Navarro',N'7001-1011',N'luis.campos@tallerpro.cr',N'Heredia, Barva','2020-10-12',N'Motores gasolina',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'mecanico4')),
(N'3-1212-1313',N'Sofía Elena Méndez Picado',N'7001-1012',N'sofia.mendez@tallerpro.cr',N'Cartago, Tejar','2021-08-02',N'Transmisiones',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'mecanico5')),
(N'1-1313-1414',N'Marco Antonio Villalobos Peña',N'7001-1013',N'marco.villalobos@tallerpro.cr',N'San José, Tibás','2023-05-15',N'Electricidad automotriz',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'mecanico6')),
(N'2-1414-1515',N'Natalia Gabriela Zúñiga Roldán',N'7001-1014',N'natalia.zuniga@tallerpro.cr',N'Heredia, Belén','2024-02-19',N'Inventario y compras',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'inventario2')),
(N'4-1515-1616',N'Esteban Mauricio Alfaro Segura',N'7001-1015',N'esteban.alfaro@tallerpro.cr',N'Alajuela, Grecia','2023-09-11',N'Ventas y caja',N'ACTIVO',(SELECT UsuarioId FROM Usuarios WHERE NombreUsuario=N'vendedor2'));
/* ================= CLIENTES ================= */
INSERT Clientes(TipoCliente,NombreRazonSocial,Identificacion,Telefono,Correo,Direccion,Activo) VALUES
(N'FISICO',N'Juan Carlos Rodríguez López',N'1-0456-0789',N'6100-0001',N'juan.rodriguez@email.cr',N'San José, Desamparados',1),
(N'FISICO',N'Ana Lucía Gómez Vargas',N'2-0345-0678',N'6100-0002',N'ana.gomez@email.cr',N'Heredia, Barva',1),
(N'FISICO',N'Miguel Ángel Sánchez Mora',N'3-0567-0890',N'6100-0003',N'miguel.sanchez@email.cr',N'Cartago, Paraíso',1),
(N'FISICO',N'Daniela María Castro Rojas',N'1-0678-0901',N'6100-0004',N'daniela.castro@email.cr',N'San José, Curridabat',1),
(N'FISICO',N'José Pablo Hernández Solís',N'4-0789-0123',N'6100-0005',N'jose.hernandez@email.cr',N'Alajuela, Grecia',1),
(N'FISICO',N'María José Ramírez León',N'2-0890-0234',N'6100-0006',N'maria.ramirez@email.cr',N'Heredia, Belén',1),
(N'FISICO',N'Andrés Mauricio Jiménez Soto',N'3-0901-0345',N'6100-0007',N'andres.jimenez@email.cr',N'Cartago, Oreamuno',1),
(N'FISICO',N'Laura Vanessa Quesada Arias',N'1-0123-0456',N'6100-0008',N'laura.quesada@email.cr',N'San José, Tibás',1),
(N'FISICO',N'Carlos Eduardo Mora Chaves',N'2-0234-0567',N'6100-0009',N'carlos.mora@email.cr',N'Heredia, Santo Domingo',1),
(N'FISICO',N'Sofía Alejandra Brenes Vega',N'4-0345-0678',N'6100-0010',N'sofia.brenes@email.cr',N'Alajuela, Centro',1),
(N'FISICO',N'Roberto Daniel Salazar Ruiz',N'1-0456-0891',N'6100-0011',N'roberto.salazar@email.cr',N'San José, Goicoechea',1),
(N'FISICO',N'Valeria Fernanda Cordero Peña',N'3-0567-0902',N'6100-0012',N'valeria.cordero@email.cr',N'Cartago, La Unión',1),
(N'FISICO',N'Luis Fernando Campos Navarro',N'2-0678-0124',N'6100-0013',N'luis.campos@email.cr',N'Heredia, San Rafael',1),
(N'FISICO',N'Natalia Elena Méndez Picado',N'1-0789-0235',N'6100-0014',N'natalia.mendez@email.cr',N'San José, Moravia',1),
(N'FISICO',N'Kevin Alonso Villalobos Segura',N'4-0890-0346',N'6100-0015',N'kevin.villalobos@email.cr',N'Alajuela, Atenas',1),
(N'FISICO',N'Gabriela Andrea Alfaro Roldán',N'3-0901-0457',N'6100-0016',N'gabriela.alfaro@email.cr',N'Cartago, Tejar',1),
(N'FISICO',N'Diego Alejandro Araya Solano',N'1-0123-0568',N'6100-0017',N'diego.araya@email.cr',N'San José, Escazú',1),
(N'FISICO',N'Melissa Carolina Vega Castro',N'2-0234-0679',N'6100-0018',N'melissa.vega@email.cr',N'Heredia, Flores',1),
(N'FISICO',N'Fernando Esteban Soto Vargas',N'3-0345-0780',N'6100-0019',N'fernando.soto@email.cr',N'Cartago, Centro',1),
(N'FISICO',N'Adriana Marcela León Mora',N'1-0456-0892',N'6100-0020',N'adriana.leon@email.cr',N'San José, Montes de Oca',1),
(N'FISICO',N'Jorge Andrés Solís Quesada',N'4-0567-0903',N'6100-0021',N'jorge.solis@email.cr',N'Alajuela, San Ramón',1),
(N'FISICO',N'Paula Cristina Rojas Hernández',N'2-0678-0125',N'6100-0022',N'paula.rojas@email.cr',N'Heredia, San Isidro',1),
(N'FISICO',N'Manuel Antonio Chaves Jiménez',N'3-0789-0236',N'6100-0023',N'manuel.chaves@email.cr',N'Cartago, Turrialba',1),
(N'FISICO',N'Andrea Sofía Ruiz Brenes',N'1-0890-0347',N'6100-0024',N'andrea.ruiz@email.cr',N'San José, Santa Ana',1),
(N'FISICO',N'Ricardo José Peña Campos',N'2-0901-0458',N'6100-0025',N'ricardo.pena@email.cr',N'Heredia, Sarapiquí',1),
(N'FISICO',N'Mónica Isabel Navarro Méndez',N'3-0123-0569',N'6100-0026',N'monica.navarro@email.cr',N'Cartago, El Guarco',1),
(N'FISICO',N'Óscar Mauricio Picado Villalobos',N'1-0234-0680',N'6100-0027',N'oscar.picado@email.cr',N'San José, Aserrí',1),
(N'FISICO',N'Alejandra María Segura Alfaro',N'4-0345-0781',N'6100-0028',N'alejandra.segura@email.cr',N'Alajuela, Naranjo',1),
(N'FISICO',N'Cristian David Roldán Araya',N'2-0456-0893',N'6100-0029',N'cristian.roldan@email.cr',N'Heredia, San Pablo',1),
(N'FISICO',N'Isabel Cristina Solano Vega',N'3-0567-0904',N'6100-0030',N'isabel.solano@email.cr',N'Cartago, Alvarado',1),
(N'FISICO',N'Pablo Andrés Castro Soto',N'1-0678-0126',N'6100-0031',N'pablo.castro@email.cr',N'San José, Alajuelita',1),
(N'FISICO',N'Mariana Fernanda Vargas León',N'2-0789-0237',N'6100-0032',N'mariana.vargas@email.cr',N'Heredia, Centro',1),
(N'FISICO',N'Héctor Alonso Mora Solís',N'3-0890-0348',N'6100-0033',N'hector.mora@email.cr',N'Cartago, Jiménez',1),
(N'FISICO',N'Lucía Gabriela Quesada Rojas',N'1-0901-0459',N'6100-0034',N'lucia.quesada@email.cr',N'San José, Pérez Zeledón',1),
(N'FISICO',N'Sebastián José Hernández Chaves',N'4-0123-0570',N'6100-0035',N'sebastian.hernandez@email.cr',N'Alajuela, Palmares',1),
(N'FISICO',N'Camila Andrea Jiménez Ruiz',N'2-0234-0681',N'6100-0036',N'camila.jimenez@email.cr',N'Heredia, Santa Bárbara',1),
(N'FISICO',N'Felipe Daniel Brenes Peña',N'3-0345-0782',N'6100-0037',N'felipe.brenes@email.cr',N'Cartago, Cervantes',1),
(N'FISICO',N'Karina Vanessa Campos Picado',N'1-0456-0894',N'6100-0038',N'karina.campos@email.cr',N'San José, Coronado',1),
(N'FISICO',N'Mauricio Esteban Méndez Segura',N'2-0567-0905',N'6100-0039',N'mauricio.mendez@email.cr',N'Heredia, Mercedes',1),
(N'FISICO',N'Erika Sofía Villalobos Alfaro',N'3-0678-0127',N'6100-0040',N'erika.villalobos@email.cr',N'Cartago, Tres Ríos',1),
(N'FISICO',N'Jonathan Andrés Araya Roldán',N'1-0789-0238',N'6100-0041',N'jonathan.araya@email.cr',N'San José, Hatillo',1),
(N'FISICO',N'Patricia Elena Solano Castro',N'4-0890-0349',N'6100-0042',N'patricia.solano@email.cr',N'Alajuela, Poás',1),
(N'FISICO',N'Alexander José Vega Vargas',N'2-0901-0460',N'6100-0043',N'alexander.vega@email.cr',N'Heredia, Ulloa',1),
(N'FISICO',N'Diana Carolina Soto Mora',N'3-0123-0571',N'6100-0044',N'diana.soto@email.cr',N'Cartago, Pacayas',1),
(N'FISICO',N'Francisco Javier León Quesada',N'1-0234-0682',N'6100-0045',N'francisco.leon@email.cr',N'San José, Pavas',1),
(N'JURIDICO',N'Transportes Valle Central S.A.',N'3-101-900001',N'6200-0001',N'flota@transportesvalle.cr',N'San José, La Uruca',1),
(N'JURIDICO',N'Distribuidora Cartago Norte S.R.L.',N'3-102-900002',N'6200-0002',N'administracion@cartagonorte.cr',N'Cartago, Ochomogo',1),
(N'JURIDICO',N'Servicios Técnicos Heredia S.A.',N'3-101-900003',N'6200-0003',N'compras@serviciostecnicos.cr',N'Heredia, Zona Industrial',1),
(N'JURIDICO',N'Comercializadora del Este S.A.',N'3-101-900004',N'6200-0004',N'gerencia@comercialeste.cr',N'San José, Curridabat',1),
(N'JURIDICO',N'Logística Alajuela S.R.L.',N'3-102-900005',N'6200-0005',N'flota@logisticaalajuela.cr',N'Alajuela, El Coyol',1);
/* ================= CATÁLOGOS DE VEHÍCULO ================= */
INSERT MarcasVehiculo(Nombre) VALUES
(N'Toyota'),
(N'Hyundai'),
(N'Nissan'),
(N'Honda'),
(N'Suzuki'),
(N'Chevrolet'),
(N'Kia'),
(N'Mitsubishi'),
(N'Ford'),
(N'Mazda');
INSERT ModelosVehiculo(MarcaId,Nombre) VALUES
(1,N'Corolla'),
(1,N'RAV4'),
(2,N'Accent'),
(2,N'Tucson'),
(3,N'Sentra'),
(3,N'X-Trail'),
(4,N'Civic'),
(4,N'CR-V'),
(5,N'Swift'),
(5,N'Vitara'),
(6,N'Sail'),
(6,N'Tracker'),
(7,N'Rio'),
(7,N'Sportage'),
(8,N'Lancer'),
(8,N'Montero Sport'),
(9,N'Ranger'),
(9,N'Escape'),
(10,N'Mazda 3'),
(10,N'CX-5');
INSERT TiposVehiculo(Nombre) VALUES(N'SEDÁN'),(N'SUV'),(N'PICKUP'),(N'HATCHBACK'),(N'VAN');
INSERT TiposCombustible(Nombre) VALUES(N'GASOLINA'),(N'DIÉSEL'),(N'HÍBRIDO'),(N'ELÉCTRICO');
INSERT CategoriasVehiculo(Nombre) VALUES(N'LIVIANO'),(N'SUV'),(N'CARGA'),(N'COMERCIAL');
/* 25 clientes poseen 2 vehículos y 25 clientes poseen 1: total 75. */
INSERT Vehiculos(ClienteId,Placa,VIN,ModeloId,TipoVehiculoId,TipoCombustibleId,CategoriaVehiculoId,Anio,Color,CilindrajeCC,KilometrajeActual,FechaIngreso,Observaciones,Activo) VALUES
(1,N'TP0001',N'TPCR2600000000001',1,1,1,1,2015,N'Blanco',2000,19375,DATEADD(DAY,-225,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(2,N'TP0002',N'TPCR2600000000002',2,2,1,2,2018,N'Negro',2400,20750,DATEADD(DAY,-222,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(3,N'TP0003',N'TPCR2600000000003',3,1,1,1,2021,N'Gris',2800,22125,DATEADD(DAY,-219,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(4,N'TP0004',N'TPCR2600000000004',4,2,1,2,2024,N'Plata',3200,23500,DATEADD(DAY,-216,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(5,N'TP0005',N'TPCR2600000000005',5,1,1,1,2012,N'Rojo',1600,24875,DATEADD(DAY,-213,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(6,N'TP0006',N'TPCR2600000000006',6,2,1,2,2015,N'Azul',2000,26250,DATEADD(DAY,-210,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(7,N'TP0007',N'TPCR2600000000007',7,1,2,1,2018,N'Verde',2400,27625,DATEADD(DAY,-207,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(8,N'TP0008',N'TPCR2600000000008',8,2,1,2,2021,N'Beige',2800,29000,DATEADD(DAY,-204,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(9,N'TP0009',N'TPCR2600000000009',9,1,1,1,2024,N'Blanco',3200,30375,DATEADD(DAY,-201,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(10,N'TP0010',N'TPCR2600000000010',10,2,1,2,2012,N'Negro',1600,31750,DATEADD(DAY,-198,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(11,N'TP0011',N'TPCR2600000000011',11,1,1,1,2015,N'Gris',2000,33125,DATEADD(DAY,-195,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(12,N'TP0012',N'TPCR2600000000012',12,2,1,2,2018,N'Plata',2400,34500,DATEADD(DAY,-192,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(13,N'TP0013',N'TPCR2600000000013',13,1,1,1,2021,N'Rojo',2800,35875,DATEADD(DAY,-189,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(14,N'TP0014',N'TPCR2600000000014',14,2,2,2,2024,N'Azul',3200,37250,DATEADD(DAY,-186,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(15,N'TP0015',N'TPCR2600000000015',15,1,1,1,2012,N'Verde',1600,38625,DATEADD(DAY,-183,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(16,N'TP0016',N'TPCR2600000000016',16,2,1,2,2015,N'Beige',2000,40000,DATEADD(DAY,-180,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(17,N'TP0017',N'TPCR2600000000017',17,3,1,3,2018,N'Blanco',2400,41375,DATEADD(DAY,-177,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(18,N'TP0018',N'TPCR2600000000018',18,2,1,2,2021,N'Negro',2800,42750,DATEADD(DAY,-174,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(19,N'TP0019',N'TPCR2600000000019',19,1,1,1,2024,N'Gris',3200,44125,DATEADD(DAY,-171,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(20,N'TP0020',N'TPCR2600000000020',20,2,1,2,2012,N'Plata',1600,45500,DATEADD(DAY,-168,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(21,N'TP0021',N'TPCR2600000000021',1,1,2,1,2015,N'Rojo',2000,46875,DATEADD(DAY,-165,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(22,N'TP0022',N'TPCR2600000000022',2,2,1,2,2018,N'Azul',2400,48250,DATEADD(DAY,-162,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(23,N'TP0023',N'TPCR2600000000023',3,1,1,1,2021,N'Verde',2800,49625,DATEADD(DAY,-159,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(24,N'TP0024',N'TPCR2600000000024',4,2,1,2,2024,N'Beige',3200,51000,DATEADD(DAY,-156,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(25,N'TP0025',N'TPCR2600000000025',5,1,1,1,2012,N'Blanco',1600,52375,DATEADD(DAY,-153,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(26,N'TP0026',N'TPCR2600000000026',6,2,1,2,2015,N'Negro',2000,53750,DATEADD(DAY,-150,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(27,N'TP0027',N'TPCR2600000000027',7,1,1,1,2018,N'Gris',2400,55125,DATEADD(DAY,-147,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(28,N'TP0028',N'TPCR2600000000028',8,2,2,2,2021,N'Plata',2800,56500,DATEADD(DAY,-144,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(29,N'TP0029',N'TPCR2600000000029',9,1,1,1,2024,N'Rojo',3200,57875,DATEADD(DAY,-141,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(30,N'TP0030',N'TPCR2600000000030',10,2,1,2,2012,N'Azul',1600,59250,DATEADD(DAY,-138,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(31,N'TP0031',N'TPCR2600000000031',11,1,1,1,2015,N'Verde',2000,60625,DATEADD(DAY,-135,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(32,N'TP0032',N'TPCR2600000000032',12,2,1,2,2018,N'Beige',2400,62000,DATEADD(DAY,-132,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(33,N'TP0033',N'TPCR2600000000033',13,1,1,1,2021,N'Blanco',2800,63375,DATEADD(DAY,-129,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(34,N'TP0034',N'TPCR2600000000034',14,2,1,2,2024,N'Negro',3200,64750,DATEADD(DAY,-126,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(35,N'TP0035',N'TPCR2600000000035',15,1,2,1,2012,N'Gris',1600,66125,DATEADD(DAY,-123,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(36,N'TP0036',N'TPCR2600000000036',16,2,1,2,2015,N'Plata',2000,67500,DATEADD(DAY,-120,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(37,N'TP0037',N'TPCR2600000000037',17,3,1,3,2018,N'Rojo',2400,68875,DATEADD(DAY,-117,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(38,N'TP0038',N'TPCR2600000000038',18,2,1,2,2021,N'Azul',2800,70250,DATEADD(DAY,-114,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(39,N'TP0039',N'TPCR2600000000039',19,1,1,1,2024,N'Verde',3200,71625,DATEADD(DAY,-111,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(40,N'TP0040',N'TPCR2600000000040',20,2,1,2,2012,N'Beige',1600,73000,DATEADD(DAY,-108,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(41,N'TP0041',N'TPCR2600000000041',1,1,1,1,2015,N'Blanco',2000,74375,DATEADD(DAY,-105,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(42,N'TP0042',N'TPCR2600000000042',2,2,2,2,2018,N'Negro',2400,75750,DATEADD(DAY,-102,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(43,N'TP0043',N'TPCR2600000000043',3,1,1,1,2021,N'Gris',2800,77125,DATEADD(DAY,-99,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(44,N'TP0044',N'TPCR2600000000044',4,2,1,2,2024,N'Plata',3200,78500,DATEADD(DAY,-96,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(45,N'TP0045',N'TPCR2600000000045',5,1,1,1,2012,N'Rojo',1600,79875,DATEADD(DAY,-93,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(46,N'TP0046',N'TPCR2600000000046',6,2,1,2,2015,N'Azul',2000,81250,DATEADD(DAY,-90,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(47,N'TP0047',N'TPCR2600000000047',7,1,1,1,2018,N'Verde',2400,82625,DATEADD(DAY,-87,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(48,N'TP0048',N'TPCR2600000000048',8,2,1,2,2021,N'Beige',2800,84000,DATEADD(DAY,-84,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(49,N'TP0049',N'TPCR2600000000049',9,1,2,1,2024,N'Blanco',3200,85375,DATEADD(DAY,-81,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(50,N'TP0050',N'TPCR2600000000050',10,2,1,2,2012,N'Negro',1600,86750,DATEADD(DAY,-78,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(1,N'TP0051',N'TPCR2600000000051',11,1,1,1,2015,N'Gris',2000,88125,DATEADD(DAY,-75,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(2,N'TP0052',N'TPCR2600000000052',12,2,1,2,2018,N'Plata',2400,89500,DATEADD(DAY,-72,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(3,N'TP0053',N'TPCR2600000000053',13,1,1,1,2021,N'Rojo',2800,90875,DATEADD(DAY,-69,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(4,N'TP0054',N'TPCR2600000000054',14,2,1,2,2024,N'Azul',3200,92250,DATEADD(DAY,-66,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(5,N'TP0055',N'TPCR2600000000055',15,1,1,1,2012,N'Verde',1600,93625,DATEADD(DAY,-63,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(6,N'TP0056',N'TPCR2600000000056',16,2,2,2,2015,N'Beige',2000,95000,DATEADD(DAY,-60,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(7,N'TP0057',N'TPCR2600000000057',17,3,1,3,2018,N'Blanco',2400,96375,DATEADD(DAY,-57,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(8,N'TP0058',N'TPCR2600000000058',18,2,1,2,2021,N'Negro',2800,97750,DATEADD(DAY,-54,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(9,N'TP0059',N'TPCR2600000000059',19,1,1,1,2024,N'Gris',3200,99125,DATEADD(DAY,-51,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(10,N'TP0060',N'TPCR2600000000060',20,2,1,2,2012,N'Plata',1600,100500,DATEADD(DAY,-48,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(11,N'TP0061',N'TPCR2600000000061',1,1,1,1,2015,N'Rojo',2000,101875,DATEADD(DAY,-45,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(12,N'TP0062',N'TPCR2600000000062',2,2,1,2,2018,N'Azul',2400,103250,DATEADD(DAY,-42,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(13,N'TP0063',N'TPCR2600000000063',3,1,2,1,2021,N'Verde',2800,104625,DATEADD(DAY,-39,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(14,N'TP0064',N'TPCR2600000000064',4,2,1,2,2024,N'Beige',3200,106000,DATEADD(DAY,-36,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(15,N'TP0065',N'TPCR2600000000065',5,1,1,1,2012,N'Blanco',1600,107375,DATEADD(DAY,-33,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(16,N'TP0066',N'TPCR2600000000066',6,2,1,2,2015,N'Negro',2000,108750,DATEADD(DAY,-30,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(17,N'TP0067',N'TPCR2600000000067',7,1,1,1,2018,N'Gris',2400,110125,DATEADD(DAY,-27,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(18,N'TP0068',N'TPCR2600000000068',8,2,1,2,2021,N'Plata',2800,111500,DATEADD(DAY,-24,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(19,N'TP0069',N'TPCR2600000000069',9,1,1,1,2024,N'Rojo',3200,112875,DATEADD(DAY,-21,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(20,N'TP0070',N'TPCR2600000000070',10,2,2,2,2012,N'Azul',1600,114250,DATEADD(DAY,-18,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(21,N'TP0071',N'TPCR2600000000071',11,1,1,1,2015,N'Verde',2000,115625,DATEADD(DAY,-15,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(22,N'TP0072',N'TPCR2600000000072',12,2,1,2,2018,N'Beige',2400,117000,DATEADD(DAY,-12,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(23,N'TP0073',N'TPCR2600000000073',13,1,1,1,2021,N'Blanco',2800,118375,DATEADD(DAY,-9,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(24,N'TP0074',N'TPCR2600000000074',14,2,1,2,2024,N'Negro',3200,119750,DATEADD(DAY,-6,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1),
(25,N'TP0075',N'TPCR2600000000075',15,1,1,1,2012,N'Gris',1600,121125,DATEADD(DAY,-3,CAST(GETDATE() AS DATE)),N'Vehículo registrado para atención y seguimiento histórico.',1);
INSERT HistorialKilometraje(VehiculoId,Kilometraje,FechaHora,Origen)
SELECT VehiculoId,KilometrajeActual,DATEADD(DAY,-30,CAST(GETDATE() AS DATETIME2)),N'REGISTRO INICIAL' FROM Vehiculos;

/* ================= SERVICIOS ================= */
INSERT Servicios(Codigo,Nombre,Descripcion,Categoria,PrecioBase,TiempoEstimadoMinutos,PorcentajeImpuesto,Activo) VALUES
(N'SRV-001',N'Cambio de aceite',N'Cambio de aceite de motor y filtro',N'Mantenimiento',22000,45,13,1),
(N'SRV-002',N'Revisión de frenos',N'Inspección de pastillas, discos, líquido y sistema',N'Frenos',18000,60,13,1),
(N'SRV-003',N'Alineamiento',N'Alineación de dirección y geometría',N'Suspensión',18000,45,13,1),
(N'SRV-004',N'Balanceo',N'Balanceo de cuatro ruedas',N'Llantas',16000,45,13,1),
(N'SRV-005',N'Diagnóstico electrónico',N'Escaneo computarizado y revisión de códigos',N'Diagnóstico',25000,60,13,1),
(N'SRV-006',N'Reparación de motor',N'Diagnóstico y reparación mecánica de motor',N'Motor',95000,480,13,1),
(N'SRV-007',N'Reparación de transmisión',N'Revisión y reparación de transmisión',N'Transmisión',110000,540,13,1),
(N'SRV-008',N'Sistema eléctrico',N'Diagnóstico y reparación eléctrica',N'Electricidad',45000,180,13,1),
(N'SRV-009',N'Cambio de llantas',N'Desmontaje, montaje y revisión de llantas',N'Llantas',20000,60,13,1),
(N'SRV-010',N'Mantenimiento preventivo',N'Inspección general preventiva',N'Mantenimiento',48000,150,13,1),
(N'SRV-011',N'Cambio de batería',N'Diagnóstico y sustitución de batería',N'Electricidad',15000,30,13,1),
(N'SRV-012',N'Limpieza de inyectores',N'Limpieza y prueba de inyectores',N'Motor',42000,120,13,1),
(N'SRV-013',N'Cambio de refrigerante',N'Drenado, limpieza y llenado de refrigerante',N'Mantenimiento',22000,60,13,1),
(N'SRV-014',N'Cambio de bujías',N'Sustitución de bujías y revisión de encendido',N'Motor',26000,75,13,1),
(N'SRV-015',N'Revisión de suspensión',N'Inspección de amortiguadores, rótulas y bujes',N'Suspensión',28000,90,13,1);
/* ================= PROVEEDORES ================= */
INSERT Proveedores(TipoIdentificacion,Identificacion,NombreRazonSocial,Telefono,Correo,Direccion,ContactoPrincipal,CondicionesPago,Activo) VALUES
(N'JURIDICA',N'3-101-800001',N'AutoPartes Central S.A.',N'2201-1001',N'ventas@autopartescentral.cr',N'San José, La Uruca',N'Mario Segura',N'Crédito 30 días',1),
(N'JURIDICA',N'3-101-800002',N'Repuestos del Valle S.A.',N'2201-1002',N'pedidos@repuestosvalle.cr',N'Cartago, Ochomogo',N'Andrea Mora',N'Contado / crédito 15 días',1),
(N'JURIDICA',N'3-101-800003',N'Lubricantes Premium S.R.L.',N'2201-1003',N'ventas@lubripremium.cr',N'Heredia, Belén',N'José Rojas',N'Crédito 30 días',1),
(N'JURIDICA',N'3-101-800004',N'Frenos y Suspensión CR S.A.',N'2201-1004',N'ventas@frenoscr.cr',N'San José, Tibás',N'Laura Chaves',N'Crédito 30 días',1),
(N'JURIDICA',N'3-101-800005',N'Baterías Nacionales S.A.',N'2201-1005',N'pedidos@bateriasnacionales.cr',N'Alajuela, El Coyol',N'Esteban León',N'Contado',1),
(N'JURIDICA',N'3-101-800006',N'Filtros Técnicos S.R.L.',N'2201-1006',N'ventas@filtrostecnicos.cr',N'Cartago, Tejar',N'Sofía Ruiz',N'Crédito 15 días',1),
(N'JURIDICA',N'3-101-800007',N'Llantas y Accesorios S.A.',N'2201-1007',N'ventas@llantasaccesorios.cr',N'San José, Pavas',N'Carlos Campos',N'Crédito 30 días',1),
(N'JURIDICA',N'3-101-800008',N'Importadora Motriz S.A.',N'2201-1008',N'compras@importadoramotriz.cr',N'Heredia, Ulloa',N'Daniela Quesada',N'Crédito 45 días',1),
(N'JURIDICA',N'3-101-800009',N'Herramientas Taller S.R.L.',N'2201-1009',N'ventas@herramientastaller.cr',N'Alajuela, Grecia',N'Roberto Araya',N'Contado',1),
(N'JURIDICA',N'3-101-800010',N'Distribuidora Automotriz CR S.A.',N'2201-1010',N'ventas@dacr.cr',N'Cartago, Zona Industrial',N'Valeria Solano',N'Crédito 30 días',1);
INSERT ProveedorContactos(ProveedorId,Nombre,Telefono,Correo,Cargo)
SELECT ProveedorId,ContactoPrincipal,Telefono,Correo,N'Asesor comercial' FROM Proveedores;

/* ================= PRODUCTOS Y REPUESTOS ================= */
INSERT Productos(CodigoInterno,CodigoBarras,Nombre,Descripcion,Categoria,Marca,UnidadMedida,PrecioCompra,PrecioVenta,PorcentajeImpuesto,ExistenciaActual,ExistenciaMinima,ExistenciaMaxima,Ubicacion,ProveedorPrincipalId,TipoProducto,Activo) VALUES
(N'PRD-001',N'744000000001',N'Filtro de aceite',N'Producto de prueba Filtro de aceite',N'Filtros',N'Bosch',N'UNIDAD',4500,7500,13,0,5,150,N'A-1-1',1,N'REPUESTO',1),
(N'PRD-002',N'744000000002',N'Filtro de aire',N'Producto de prueba Filtro de aire',N'Filtros',N'Bosch',N'UNIDAD',6000,9800,13,0,5,150,N'A-1-2',2,N'REPUESTO',1),
(N'PRD-003',N'744000000003',N'Pastillas de freno delanteras',N'Producto de prueba Pastillas de freno delanteras',N'Frenos',N'Brembo',N'UNIDAD',22000,35000,13,0,5,150,N'A-1-3',3,N'REPUESTO',1),
(N'PRD-004',N'744000000004',N'Discos de freno delanteros',N'Producto de prueba Discos de freno delanteros',N'Frenos',N'Brembo',N'UNIDAD',38000,56000,13,0,5,150,N'A-1-4',4,N'REPUESTO',1),
(N'PRD-005',N'744000000005',N'Aceite motor 5W-30 1L',N'Producto de prueba Aceite motor 5W-30 1L',N'Lubricantes',N'Mobil',N'UNIDAD',5200,7800,13,0,5,150,N'A-1-5',5,N'LUBRICANTE',1),
(N'PRD-006',N'744000000006',N'Aceite motor 10W-40 1L',N'Producto de prueba Aceite motor 10W-40 1L',N'Lubricantes',N'Castrol',N'UNIDAD',4800,7200,13,0,5,150,N'A-1-6',6,N'LUBRICANTE',1),
(N'PRD-007',N'744000000007',N'Refrigerante 1L',N'Producto de prueba Refrigerante 1L',N'Lubricantes',N'Prestone',N'UNIDAD',4200,6500,13,0,5,150,N'A-1-7',7,N'LUBRICANTE',1),
(N'PRD-008',N'744000000008',N'Líquido de frenos DOT4',N'Producto de prueba Líquido de frenos DOT4',N'Lubricantes',N'Bosch',N'UNIDAD',3500,5800,13,0,5,150,N'A-1-8',8,N'LUBRICANTE',1),
(N'PRD-009',N'744000000009',N'Bujía iridium',N'Producto de prueba Bujía iridium',N'Encendido',N'NGK',N'UNIDAD',6500,9500,13,0,5,150,N'A-1-9',9,N'REPUESTO',1),
(N'PRD-010',N'744000000010',N'Batería 12V 45Ah',N'Producto de prueba Batería 12V 45Ah',N'Electricidad',N'LTH',N'UNIDAD',52000,72000,13,0,5,150,N'A-1-10',10,N'REPUESTO',1),
(N'PRD-011',N'744000000011',N'Batería 12V 65Ah',N'Producto de prueba Batería 12V 65Ah',N'Electricidad',N'LTH',N'UNIDAD',62000,85000,13,0,5,150,N'A-2-1',1,N'REPUESTO',1),
(N'PRD-012',N'744000000012',N'Correa de accesorios',N'Producto de prueba Correa de accesorios',N'Motor',N'Gates',N'UNIDAD',15000,24000,13,0,5,150,N'A-2-2',2,N'REPUESTO',1),
(N'PRD-013',N'744000000013',N'Kit correa distribución',N'Producto de prueba Kit correa distribución',N'Motor',N'Gates',N'UNIDAD',48000,72000,13,0,5,150,N'A-2-3',3,N'REPUESTO',1),
(N'PRD-014',N'744000000014',N'Bomba de agua',N'Producto de prueba Bomba de agua',N'Motor',N'Aisin',N'UNIDAD',35000,52000,13,0,5,150,N'A-2-4',4,N'REPUESTO',1),
(N'PRD-015',N'744000000015',N'Termostato',N'Producto de prueba Termostato',N'Motor',N'Aisin',N'UNIDAD',12000,19000,13,0,5,150,N'A-2-5',5,N'REPUESTO',1),
(N'PRD-016',N'744000000016',N'Amortiguador delantero',N'Producto de prueba Amortiguador delantero',N'Suspensión',N'KYB',N'UNIDAD',42000,62000,13,0,5,150,N'A-2-6',6,N'REPUESTO',1),
(N'PRD-017',N'744000000017',N'Amortiguador trasero',N'Producto de prueba Amortiguador trasero',N'Suspensión',N'KYB',N'UNIDAD',38000,57000,13,0,5,150,N'A-2-7',7,N'REPUESTO',1),
(N'PRD-018',N'744000000018',N'Rótula suspensión',N'Producto de prueba Rótula suspensión',N'Suspensión',N'555',N'UNIDAD',18000,28000,13,0,5,150,N'A-2-8',8,N'REPUESTO',1),
(N'PRD-019',N'744000000019',N'Terminal dirección',N'Producto de prueba Terminal dirección',N'Dirección',N'555',N'UNIDAD',16000,26000,13,0,5,150,N'A-2-9',9,N'REPUESTO',1),
(N'PRD-020',N'744000000020',N'Rodamiento rueda',N'Producto de prueba Rodamiento rueda',N'Rodamientos',N'SKF',N'UNIDAD',22000,34000,13,0,5,150,N'A-2-10',10,N'REPUESTO',1),
(N'PRD-021',N'744000000021',N'Bombillo H4',N'Producto de prueba Bombillo H4',N'Electricidad',N'Philips',N'UNIDAD',4500,7000,13,0,5,150,N'A-3-1',1,N'REPUESTO',1),
(N'PRD-022',N'744000000022',N'Fusible automotriz 20A',N'Producto de prueba Fusible automotriz 20A',N'Electricidad',N'Bussmann',N'UNIDAD',500,1000,13,0,5,150,N'A-3-2',2,N'REPUESTO',1),
(N'PRD-023',N'744000000023',N'Relay universal 12V',N'Producto de prueba Relay universal 12V',N'Electricidad',N'Bosch',N'UNIDAD',4500,7500,13,0,5,150,N'A-3-3',3,N'REPUESTO',1),
(N'PRD-024',N'744000000024',N'Sensor oxígeno',N'Producto de prueba Sensor oxígeno',N'Sensores',N'Denso',N'UNIDAD',35000,52000,13,0,5,150,N'A-3-4',4,N'REPUESTO',1),
(N'PRD-025',N'744000000025',N'Sensor temperatura',N'Producto de prueba Sensor temperatura',N'Sensores',N'Denso',N'UNIDAD',18000,28000,13,0,5,150,N'A-3-5',5,N'REPUESTO',1),
(N'PRD-026',N'744000000026',N'Filtro combustible',N'Producto de prueba Filtro combustible',N'Filtros',N'Mann',N'UNIDAD',9000,14500,13,0,5,150,N'A-3-6',6,N'REPUESTO',1),
(N'PRD-027',N'744000000027',N'Filtro cabina',N'Producto de prueba Filtro cabina',N'Filtros',N'Mann',N'UNIDAD',7500,12000,13,0,5,150,N'A-3-7',7,N'REPUESTO',1),
(N'PRD-028',N'744000000028',N'Limpiaparabrisas 22in',N'Producto de prueba Limpiaparabrisas 22in',N'Accesorios',N'Bosch',N'UNIDAD',5500,8500,13,0,5,150,N'A-3-8',8,N'ACCESORIO',1),
(N'PRD-029',N'744000000029',N'Limpiaparabrisas 18in',N'Producto de prueba Limpiaparabrisas 18in',N'Accesorios',N'Bosch',N'UNIDAD',5000,8000,13,0,5,150,N'A-3-9',9,N'ACCESORIO',1),
(N'PRD-030',N'744000000030',N'Aditivo limpiainyectores',N'Producto de prueba Aditivo limpiainyectores',N'Lubricantes',N'Liqui Moly',N'UNIDAD',6000,9500,13,0,5,150,N'A-3-10',10,N'LUBRICANTE',1),
(N'PRD-031',N'744000000031',N'Grasa multipropósito',N'Producto de prueba Grasa multipropósito',N'Lubricantes',N'Mobil',N'UNIDAD',3500,6000,13,0,5,150,N'A-4-1',1,N'LUBRICANTE',1),
(N'PRD-032',N'744000000032',N'Silicón alta temperatura',N'Producto de prueba Silicón alta temperatura',N'Consumibles',N'Permatex',N'UNIDAD',4500,7500,13,0,5,150,N'A-4-2',2,N'OTRO',1),
(N'PRD-033',N'744000000033',N'Sellador de roscas',N'Producto de prueba Sellador de roscas',N'Consumibles',N'Loctite',N'UNIDAD',5500,8500,13,0,5,150,N'A-4-3',3,N'OTRO',1),
(N'PRD-034',N'744000000034',N'Abrazadera metálica',N'Producto de prueba Abrazadera metálica',N'Consumibles',N'Tridon',N'UNIDAD',700,1500,13,0,5,150,N'A-4-4',4,N'REPUESTO',1),
(N'PRD-035',N'744000000035',N'Manguera radiador superior',N'Producto de prueba Manguera radiador superior',N'Enfriamiento',N'Gates',N'UNIDAD',16000,25000,13,0,5,150,N'A-4-5',5,N'REPUESTO',1),
(N'PRD-036',N'744000000036',N'Manguera radiador inferior',N'Producto de prueba Manguera radiador inferior',N'Enfriamiento',N'Gates',N'UNIDAD',17000,26000,13,0,5,150,N'A-4-6',6,N'REPUESTO',1),
(N'PRD-037',N'744000000037',N'Kit clutch',N'Producto de prueba Kit clutch',N'Transmisión',N'Exedy',N'UNIDAD',85000,125000,13,0,5,150,N'A-4-7',7,N'REPUESTO',1),
(N'PRD-038',N'744000000038',N'Aceite transmisión ATF 1L',N'Producto de prueba Aceite transmisión ATF 1L',N'Lubricantes',N'Valvoline',N'UNIDAD',6500,9500,13,0,5,150,N'A-4-8',8,N'LUBRICANTE',1),
(N'PRD-039',N'744000000039',N'Aceite transmisión 75W-90 1L',N'Producto de prueba Aceite transmisión 75W-90 1L',N'Lubricantes',N'Valvoline',N'UNIDAD',7200,10500,13,0,5,150,N'A-4-9',9,N'LUBRICANTE',1),
(N'PRD-040',N'744000000040',N'Filtro transmisión',N'Producto de prueba Filtro transmisión',N'Transmisión',N'Aisin',N'UNIDAD',18000,29000,13,0,5,150,N'A-4-10',10,N'REPUESTO',1),
(N'PRD-041',N'744000000041',N'Escobilla carbón alternador',N'Producto de prueba Escobilla carbón alternador',N'Electricidad',N'Bosch',N'UNIDAD',8000,13000,13,0,5,150,N'A-5-1',1,N'REPUESTO',1),
(N'PRD-042',N'744000000042',N'Regulador alternador',N'Producto de prueba Regulador alternador',N'Electricidad',N'Bosch',N'UNIDAD',28000,42000,13,0,5,150,N'A-5-2',2,N'REPUESTO',1),
(N'PRD-043',N'744000000043',N'Motor de arranque reconstruido',N'Producto de prueba Motor de arranque reconstruido',N'Electricidad',N'Denso',N'UNIDAD',65000,95000,13,0,5,150,N'A-5-3',3,N'REPUESTO',1),
(N'PRD-044',N'744000000044',N'Alternador reconstruido',N'Producto de prueba Alternador reconstruido',N'Electricidad',N'Denso',N'UNIDAD',78000,115000,13,0,5,150,N'A-5-4',4,N'REPUESTO',1),
(N'PRD-045',N'744000000045',N'Gato hidráulico 2T',N'Producto de prueba Gato hidráulico 2T',N'Herramientas',N'Truper',N'UNIDAD',28000,39000,13,0,5,150,N'A-5-5',5,N'HERRAMIENTA',1),
(N'PRD-046',N'744000000046',N'Llave cruz',N'Producto de prueba Llave cruz',N'Herramientas',N'Truper',N'UNIDAD',6500,9500,13,0,5,150,N'A-5-6',6,N'HERRAMIENTA',1),
(N'PRD-047',N'744000000047',N'Juego de dados 40 piezas',N'Producto de prueba Juego de dados 40 piezas',N'Herramientas',N'Stanley',N'UNIDAD',32000,45000,13,0,5,150,N'A-5-7',7,N'HERRAMIENTA',1),
(N'PRD-048',N'744000000048',N'Compresor portátil 12V',N'Producto de prueba Compresor portátil 12V',N'Accesorios',N'Black+Decker',N'UNIDAD',24000,35000,13,0,5,150,N'A-5-8',8,N'ACCESORIO',1),
(N'PRD-049',N'744000000049',N'Cargador batería 12V',N'Producto de prueba Cargador batería 12V',N'Herramientas',N'Schumacher',N'UNIDAD',38000,55000,13,0,5,150,N'A-5-9',9,N'HERRAMIENTA',1),
(N'PRD-050',N'744000000050',N'Triángulo reflectivo',N'Producto de prueba Triángulo reflectivo',N'Accesorios',N'Genérico',N'UNIDAD',4500,7000,13,0,5,150,N'A-5-10',10,N'ACCESORIO',1);
INSERT ProductoProveedores(ProductoId,ProveedorId,CodigoProveedor,CostoReferencia)
SELECT ProductoId,ProveedorPrincipalId,CONCAT(N'PV-',RIGHT(N'000'+CONVERT(NVARCHAR(3),ProductoId),3)),PrecioCompra FROM Productos;

INSERT ProductoCompatibilidadVehiculo(ProductoId,MarcaId,ModeloId,AnioDesde,AnioHasta,Observaciones)
SELECT p.ProductoId,((p.ProductoId-1)%10)+1,NULL,2010,2026,N'Compatibilidad general de demostración por marca.'
FROM Productos p WHERE p.TipoProducto=N'REPUESTO';

/* ================= COMPRAS E INVENTARIO INICIAL =================
   Cada producto recibe una compra real. Los productos 46-50 se compran
   en menor cantidad para que existan ejemplos de alerta por stock mínimo.
*/
DECLARE @p INT=1,@prov INT,@comp INT,@qty DECIMAL(18,2),@cost DECIMAL(18,2),@tax DECIMAL(9,4),@total DECIMAL(18,2);
WHILE @p<=50
BEGIN
    SET @prov=((@p-1)%10)+1;
    SET @qty=CASE WHEN @p>=46 THEN 7 ELSE 100 END;
    SELECT @cost=PrecioCompra,@tax=PorcentajeImpuesto FROM Productos WHERE ProductoId=@p;
    SET @total=@qty*@cost*(1+@tax/100.0);
    INSERT Compras(ProveedorId,NumeroFacturaProveedor,Fecha,Subtotal,Impuestos,Descuentos,Total,FormaPago,Estado,SaldoPendiente,UsuarioId)
    VALUES(@prov,CONCAT(N'FAC-PROV-',RIGHT(N'000'+CONVERT(NVARCHAR(3),@p),3)),DATEADD(DAY,-180+@p,GETDATE()),@qty*@cost,@qty*@cost*@tax/100.0,0,@total,
           CASE WHEN @p%3=0 THEN N'CREDITO' ELSE N'CONTADO' END,
           CASE WHEN @p%3=0 THEN N'PARCIALMENTE PAGADA' ELSE N'PAGADA' END,
           CASE WHEN @p%3=0 THEN @total/2 ELSE 0 END,5);
    SET @comp=SCOPE_IDENTITY();
    INSERT CompraDetalles(CompraId,ProductoId,Cantidad,CostoUnitario,ImpuestoPorcentaje,Descuento,TotalLinea)
    VALUES(@comp,@p,@qty,@cost,@tax,0,@total);
    INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,FechaHora,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior,Observaciones)
    VALUES(@p,@qty,N'COMPRA',DATEADD(DAY,-180+@p,GETDATE()),5,CONCAT(N'COM-',@comp),0,@qty,N'Ingreso de inventario por compra confirmada.');
    UPDATE Productos SET ExistenciaActual=@qty WHERE ProductoId=@p;
    IF @p%3=0
      INSERT CompraPagos(CompraId,Monto,FormaPago,Referencia,FechaHora,UsuarioId)
      VALUES(@comp,@total/2,N'TRANSFERENCIA',CONCAT(N'TRF-COMP-',@comp),DATEADD(DAY,-179+@p,GETDATE()),5);
    ELSE
      INSERT CompraPagos(CompraId,Monto,FormaPago,Referencia,FechaHora,UsuarioId)
      VALUES(@comp,@total,N'EFECTIVO',NULL,DATEADD(DAY,-180+@p,GETDATE()),5);
    SET @p+=1;
END

/* ================= CITAS ================= */
INSERT AreasTrabajo(Nombre,Descripcion,Activa) VALUES
(N'Bahía 1',N'Área de mantenimiento general',1),(N'Bahía 2',N'Área de mecánica general',1),(N'Bahía 3',N'Área de diagnóstico',1),(N'Bahía 4',N'Área de frenos y suspensión',1),(N'Bahía 5',N'Área de electricidad automotriz',1),(N'Bahía 6',N'Área de trabajos pesados',1);
DECLARE @ci INT=1,@veh INT,@cli INT,@mec INT,@cita INT,@area INT;
WHILE @ci<=60
BEGIN
 SET @veh=((@ci-1)%75)+1;
 SELECT @cli=ClienteId FROM Vehiculos WHERE VehiculoId=@veh;
 SET @mec=CASE ((@ci-1)%6) WHEN 0 THEN 3 WHEN 1 THEN 4 WHEN 2 THEN 10 WHEN 3 THEN 11 WHEN 4 THEN 12 ELSE 13 END;
 SET @area=((@ci-1)%6)+1;
 DECLARE @servCita INT=((@ci-1)%15)+1,@durCita INT;
 SELECT @durCita=TiempoEstimadoMinutos FROM Servicios WHERE ServicioId=@servCita;
 INSERT Citas(ClienteId,VehiculoId,ServicioId,EmpleadoId,AreaTrabajo,AreaTrabajoId,FechaHoraInicio,DuracionEstimadaMinutos,Estado,Observaciones,CreadaPorUsuarioId)
 VALUES(@cli,@veh,@servCita,@mec,CONCAT(N'Bahía ',@area),@area,
        DATEADD(HOUR,8,DATEADD(DAY,@ci-30,CAST(CAST(GETDATE() AS DATE) AS DATETIME2))),@durCita,
        CASE WHEN @ci<30 THEN N'ATENDIDA' WHEN @ci<50 THEN N'CONFIRMADA' ELSE N'PROGRAMADA' END,
        N'Cita de demostración vinculada al cliente y su vehículo.',2);
 SET @cita=SCOPE_IDENTITY();
 INSERT CitaServicios(CitaId,ServicioId) VALUES(@cita,@servCita);
 INSERT CitaMecanicos(CitaId,EmpleadoId) VALUES(@cita,@mec);
 SET @ci+=1;
END

/* ========== 100 RECEPCIONES -> DIAGNÓSTICOS -> COTIZACIONES -> ÓRDENES ==========
   Cada orden conserva el mismo cliente y vehículo de la recepción.
   Cada diagnóstico recomienda un servicio y un repuesto.
*/
DECLARE @i INT=1,@recep INT,@diag INT,@cot INT,@ord INT,@serv INT,@prod INT,@cliente INT,@mecanico INT;
DECLARE @fecha DATETIME2,@km INT,@sprec DECIMAL(18,2),@stime INT,@pprec DECIMAL(18,2),@pcost DECIMAL(18,2),@ptax DECIMAL(9,4),@stockAntes DECIMAL(18,2);
DECLARE @mano DECIMAL(18,2),@sub DECIMAL(18,2),@imp DECIMAL(18,2),@tot DECIMAL(18,2);
WHILE @i<=100
BEGIN
    SET @veh=((@i-1)%75)+1;
    SELECT @cliente=ClienteId,@km=KilometrajeActual+(@i*40) FROM Vehiculos WHERE VehiculoId=@veh;
    SET @serv=((@i-1)%15)+1;
    SET @prod=((@i-1)%50)+1;
    SET @mecanico=CASE ((@i-1)%6) WHEN 0 THEN 3 WHEN 1 THEN 4 WHEN 2 THEN 10 WHEN 3 THEN 11 WHEN 4 THEN 12 ELSE 13 END;
    SET @fecha=DATEADD(DAY,-(120-@i),DATEADD(HOUR,8,CAST(CAST(GETDATE() AS DATE) AS DATETIME2)));

    INSERT Recepciones(ClienteId,VehiculoId,FechaHoraIngreso,KilometrajeIngreso,NivelCombustible,MotivoVisita,ProblemaCliente,AccesoriosObjetos,DanosVisibles,EmpleadoRecibeId,FechaEstimadaEntrega,Observaciones,Estado)
    VALUES(@cliente,@veh,@fecha,@km,CASE @i%5 WHEN 0 THEN N'LLENO' WHEN 1 THEN N'POCO' WHEN 2 THEN N'INTERMEDIO' WHEN 3 THEN N'SOBRE LA MITAD' ELSE N'NULO' END,
           N'Revisión y reparación solicitada por el cliente.',
           CONCAT(N'Cliente reporta condición mecánica asociada al servicio #',@serv,N'.'),
           N'Llave, documento del vehículo y alfombras.',CASE WHEN @i%4=0 THEN N'Rayón leve previamente existente.' ELSE N'Sin daños visibles relevantes.' END,
           CASE WHEN @i%2=0 THEN 2 ELSE 9 END,NULL,N'Recepción generada como dato de prueba coherente.',N'RECIBIDA');
    SET @recep=SCOPE_IDENTITY();
    INSERT HistorialKilometraje(VehiculoId,Kilometraje,FechaHora,Origen,RegistroReferenciaId) VALUES(@veh,@km,@fecha,N'RECEPCION',@recep);

    SELECT @sprec=PrecioBase,@stime=TiempoEstimadoMinutos FROM Servicios WHERE ServicioId=@serv;
    SELECT @pprec=PrecioVenta,@pcost=PrecioCompra,@ptax=PorcentajeImpuesto FROM Productos WHERE ProductoId=@prod;
    SET @mano=CAST((@stime/60.0)*15000 AS DECIMAL(18,2));

    INSERT Diagnosticos(RecepcionId,ProblemasEncontrados,PruebasRealizadas,PosiblesCausas,Recomendaciones,ManoObraEstimada,TiempoEstimadoMinutos,CostoEstimado,MecanicoResponsableId,FechaHoraDiagnostico,Estado,AprobadoPorUsuarioId,FechaAprobacion)
    VALUES(@recep,CONCAT(N'Se detectó necesidad del servicio ',(SELECT Nombre FROM Servicios WHERE ServicioId=@serv),N'.'),
           N'Inspección visual, prueba funcional y verificación técnica.',
           N'Desgaste por uso normal y mantenimiento requerido.',
           N'Realizar el servicio recomendado y sustituir el repuesto indicado.',
           @mano,@stime,@sprec+@pprec+@mano,@mecanico,DATEADD(HOUR,2,@fecha),N'FINALIZADO',NULL,NULL);
    SET @diag=SCOPE_IDENTITY();
    INSERT DiagnosticoMecanicos(DiagnosticoId,EmpleadoId,Observacion) VALUES(@diag,@mecanico,N'Mecánico asignado al diagnóstico.');
    INSERT DiagnosticoServicios(DiagnosticoId,ServicioId,Cantidad,PrecioEstimado,TiempoEstimadoMinutos,Recomendado) VALUES(@diag,@serv,1,@sprec,@stime,1);
    INSERT DiagnosticoProductos(DiagnosticoId,ProductoId,Cantidad,PrecioUnitarioEstimado) VALUES(@diag,@prod,1,@pprec);

    SET @sub=@sprec+@pprec+@mano;
    SET @imp=(@sprec+@pprec)*13/100.0;
    SET @tot=@sub+@imp;
    INSERT Cotizaciones(DiagnosticoId,FechaEmision,FechaVencimiento,HorasManoObra,PrecioHoraManoObra,Subtotal,Impuestos,Descuento,TotalEstimado,Condiciones,Observaciones,Estado,AprobacionTipo,UsuarioDecisionId,FechaHoraDecision,UsuarioConversionId,FechaHoraConversion)
    VALUES(@diag,DATEADD(HOUR,3,@fecha),DATEADD(DAY,15,CAST(@fecha AS DATE)),@stime/60.0,15000,@sub,@imp,0,@tot,N'Cotización válida por 15 días.',N'Valores calculados desde diagnóstico.',N'CONVERTIDA',CASE WHEN @i%10=0 THEN N'PARCIAL' ELSE N'TOTAL' END,8,DATEADD(HOUR,4,@fecha),8,DATEADD(HOUR,4,@fecha));
    SET @cot=SCOPE_IDENTITY();
    INSERT CotizacionServicios(CotizacionId,ServicioId,Cantidad,PrecioUnitario,ImpuestoPorcentaje,Descuento,Aprobado,TiempoEstimadoMinutos) VALUES(@cot,@serv,1,@sprec,13,0,1,@stime);
    INSERT CotizacionProductos(CotizacionId,ProductoId,Cantidad,PrecioUnitario,ImpuestoPorcentaje,Descuento,Aprobado) VALUES(@cot,@prod,1,@pprec,13,0,1);

    INSERT OrdenesTrabajo(CotizacionId,ClienteId,VehiculoId,FechaApertura,FechaEstimadaEntrega,FechaFinalizacion,Prioridad,Estado,Observaciones,UsuarioCreadorId)
    VALUES(@cot,@cliente,@veh,DATEADD(HOUR,4,@fecha),DATEADD(MINUTE,@stime+120,DATEADD(HOUR,4,@fecha)),
           CASE WHEN @i<=75 THEN DATEADD(MINUTE,@stime+60,DATEADD(HOUR,4,@fecha)) ELSE NULL END,
           CASE WHEN @i%12=0 THEN N'ALTA' WHEN @i%5=0 THEN N'BAJA' ELSE N'MEDIA' END,
           CASE WHEN @i<=40 THEN N'ENTREGADA' WHEN @i<=60 THEN N'FACTURADA' WHEN @i<=75 THEN N'FINALIZADA' WHEN @i<=90 THEN N'EN PROCESO' WHEN @i<=95 THEN N'EN ESPERA DE REPUESTOS' ELSE N'APROBADA' END,
           N'Orden generada desde cotización aprobada.',8);
    SET @ord=SCOPE_IDENTITY();
    INSERT OrdenServicios(OrdenTrabajoId,ServicioId,Cantidad,PrecioAplicado,ImpuestoPorcentaje,DescuentoAplicado,TiempoEstimadoMinutos,Estado)
    VALUES(@ord,@serv,1,@sprec,13,0,@stime,CASE WHEN @i<=75 THEN N'FINALIZADO' ELSE N'PENDIENTE' END);
    INSERT OrdenProductos(OrdenTrabajoId,ProductoId,CantidadAutorizada,CantidadUtilizada,CostoAplicado,PrecioAplicado,ImpuestoPorcentaje,DescuentoAplicado)
    VALUES(@ord,@prod,1,1,@pcost,@pprec,13,0);

    SELECT @stockAntes=ExistenciaActual FROM Productos WHERE ProductoId=@prod;
    UPDATE Productos SET ExistenciaActual=ExistenciaActual-1 WHERE ProductoId=@prod;
    INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,FechaHora,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior,Observaciones)
    VALUES(@prod,1,N'USO ORDEN',DATEADD(HOUR,5,@fecha),@mecanico,CONCAT(N'OT-',@ord),@stockAntes,@stockAntes-1,N'Repuesto consumido por la orden de trabajo.');

    INSERT OrdenEmpleados(OrdenTrabajoId,EmpleadoId,ActividadRealizada,FechaInicio,FechaFinalizacion,HorasTrabajadas,CostoHora,Observaciones,EstadoActividad)
    VALUES(@ord,@mecanico,CONCAT(N'Ejecución de ',(SELECT Nombre FROM Servicios WHERE ServicioId=@serv)),
           DATEADD(HOUR,4,@fecha),CASE WHEN @i<=75 THEN DATEADD(MINUTE,@stime,DATEADD(HOUR,4,@fecha)) ELSE NULL END,
           CASE WHEN @i<=75 THEN CAST(@stime/60.0 AS DECIMAL(9,2)) ELSE 0 END,15000,N'Actividad asignada según especialidad.',CASE WHEN @i<=75 THEN N'FINALIZADA' ELSE N'ASIGNADA' END);

    INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,FechaHora,Observacion)
    VALUES(@ord,NULL,N'REGISTRADA',8,DATEADD(HOUR,4,@fecha),N'Orden creada desde cotización.');
    INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,FechaHora,Observacion)
    VALUES(@ord,N'REGISTRADA',N'APROBADA',8,DATEADD(MINUTE,15,DATEADD(HOUR,4,@fecha)),N'Orden aprobada.');
    IF @i<=95
      INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,FechaHora,Observacion)
      VALUES(@ord,N'APROBADA',CASE WHEN @i BETWEEN 91 AND 95 THEN N'EN ESPERA DE REPUESTOS' ELSE N'EN PROCESO' END,@mecanico,DATEADD(MINUTE,30,DATEADD(HOUR,4,@fecha)),N'Inicio del trabajo.');
    IF @i<=75
      INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,FechaHora,Observacion)
      VALUES(@ord,N'EN PROCESO',N'FINALIZADA',@mecanico,DATEADD(MINUTE,@stime+60,DATEADD(HOUR,4,@fecha)),N'Trabajo finalizado.');

    SET @i+=1;
END

/* ================= 60 FACTURAS DE ÓRDENES ================= */
DECLARE @oi INT=1,@fact INT,@osub DECIMAL(18,2),@oimp DECIMAL(18,2),@odesc DECIMAL(18,2),@otot DECIMAL(18,2),@oclient INT,@ofecha DATETIME2;
WHILE @oi<=60
BEGIN
 SELECT @oclient=ClienteId,@ofecha=DATEADD(HOUR,8,FechaApertura) FROM OrdenesTrabajo WHERE OrdenTrabajoId=@oi;
 SELECT @osub=ISNULL(SUM(Cantidad*PrecioAplicado-DescuentoAplicado),0),@oimp=ISNULL(SUM((Cantidad*PrecioAplicado-DescuentoAplicado)*ImpuestoPorcentaje/100.0),0),@odesc=ISNULL(SUM(DescuentoAplicado),0) FROM OrdenServicios WHERE OrdenTrabajoId=@oi;
 SELECT @osub=@osub+ISNULL(SUM(CantidadUtilizada*PrecioAplicado-DescuentoAplicado),0),@oimp=@oimp+ISNULL(SUM((CantidadUtilizada*PrecioAplicado-DescuentoAplicado)*ImpuestoPorcentaje/100.0),0),@odesc=@odesc+ISNULL(SUM(DescuentoAplicado),0) FROM OrdenProductos WHERE OrdenTrabajoId=@oi;
 SELECT @osub=@osub+ISNULL(SUM(HorasTrabajadas*CostoHora),0) FROM OrdenEmpleados WHERE OrdenTrabajoId=@oi;
 SET @otot=@osub+@oimp;
 INSERT Facturas(ClienteId,OrdenTrabajoId,FechaHora,Subtotal,Impuestos,Descuentos,Total,SaldoPendiente,Estado,FormaPagoDescripcion,UsuarioEmisorId)
 VALUES(@oclient,@oi,@ofecha,@osub,@oimp,@odesc,@otot,@otot,N'PENDIENTE',N'POR DEFINIR',7);
 SET @fact=SCOPE_IDENTITY();

 INSERT FacturaDetalles(FacturaId,TipoDetalle,ServicioId,Descripcion,Cantidad,PrecioUnitario,Impuesto,Descuento,TotalLinea)
 SELECT @fact,N'SERVICIO',os.ServicioId,s.Nombre,os.Cantidad,os.PrecioAplicado,(os.Cantidad*os.PrecioAplicado-os.DescuentoAplicado)*os.ImpuestoPorcentaje/100.0,os.DescuentoAplicado,(os.Cantidad*os.PrecioAplicado-os.DescuentoAplicado)*(1+os.ImpuestoPorcentaje/100.0)
 FROM OrdenServicios os JOIN Servicios s ON s.ServicioId=os.ServicioId WHERE os.OrdenTrabajoId=@oi;
 INSERT FacturaDetalles(FacturaId,TipoDetalle,ProductoId,Descripcion,Cantidad,PrecioUnitario,CostoUnitarioHistorico,Impuesto,Descuento,TotalLinea)
 SELECT @fact,N'PRODUCTO',op.ProductoId,p.Nombre,op.CantidadUtilizada,op.PrecioAplicado,op.CostoAplicado,(op.CantidadUtilizada*op.PrecioAplicado-op.DescuentoAplicado)*op.ImpuestoPorcentaje/100.0,op.DescuentoAplicado,(op.CantidadUtilizada*op.PrecioAplicado-op.DescuentoAplicado)*(1+op.ImpuestoPorcentaje/100.0)
 FROM OrdenProductos op JOIN Productos p ON p.ProductoId=op.ProductoId WHERE op.OrdenTrabajoId=@oi;
 INSERT FacturaDetalles(FacturaId,TipoDetalle,Descripcion,Cantidad,PrecioUnitario,Impuesto,Descuento,TotalLinea)
 SELECT @fact,N'MANO DE OBRA',CONCAT(N'Mano de obra - ',e.NombreCompleto),oe.HorasTrabajadas,oe.CostoHora,0,0,oe.HorasTrabajadas*oe.CostoHora
 FROM OrdenEmpleados oe JOIN Empleados e ON e.EmpleadoId=oe.EmpleadoId WHERE oe.OrdenTrabajoId=@oi;

 INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,FechaHora,Observacion)
 VALUES(@oi,N'FINALIZADA',N'FACTURADA',7,@ofecha,N'Factura generada desde la orden finalizada.');

 IF @oi<=40
 BEGIN
   INSERT Pagos(FacturaId,Monto,FormaPagoId,NumeroReferencia,FechaHora,UsuarioId,Observaciones)
   VALUES(@fact,@otot,CASE WHEN @oi%4=0 THEN 4 WHEN @oi%3=0 THEN 3 WHEN @oi%2=0 THEN 2 ELSE 1 END,CONCAT(N'PAGO-OT-',@oi),DATEADD(HOUR,1,@ofecha),7,N'Pago completo de orden.');
   UPDATE Facturas SET SaldoPendiente=0,Estado=N'PAGADA',FormaPagoDescripcion=N'PAGO COMPLETO' WHERE FacturaId=@fact;
   INSERT EntregasVehiculo(OrdenTrabajoId,KilometrajeSalida,FechaHoraEntrega,PersonaRecibe,ObservacionesFinales,RecomendacionesMantenimiento,ProximaFechaServicio,EstadoPago,AceptacionCliente,UsuarioEntregaId)
   SELECT @oi,r.KilometrajeIngreso+50,DATEADD(HOUR,2,@ofecha),c.NombreRazonSocial,N'Vehículo entregado después de verificar los trabajos.',N'Realizar mantenimiento preventivo según recomendación.',DATEADD(MONTH,6,CAST(@ofecha AS DATE)),N'PAGADA',N'Aceptación registrada por el cliente.',2
   FROM OrdenesTrabajo o
   JOIN Clientes c ON c.ClienteId=o.ClienteId
   JOIN Cotizaciones co ON co.CotizacionId=o.CotizacionId
   JOIN Diagnosticos d ON d.DiagnosticoId=co.DiagnosticoId
   JOIN Recepciones r ON r.RecepcionId=d.RecepcionId
   WHERE o.OrdenTrabajoId=@oi;
   INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,FechaHora,Observacion) VALUES(@oi,N'FACTURADA',N'ENTREGADA',2,DATEADD(HOUR,2,@ofecha),N'Vehículo entregado al cliente.');
 END
 ELSE IF @oi<=50
 BEGIN
   INSERT Pagos(FacturaId,Monto,FormaPagoId,NumeroReferencia,FechaHora,UsuarioId,Observaciones) VALUES(@fact,@otot/2,3,CONCAT(N'TRF-OT-',@oi),DATEADD(HOUR,1,@ofecha),7,N'Abono del 50%.');
   UPDATE Facturas SET SaldoPendiente=@otot/2,Estado=N'PARCIALMENTE PAGADA',FormaPagoDescripcion=N'TRANSFERENCIA' WHERE FacturaId=@fact;
 END
 ELSE UPDATE Facturas SET FormaPagoDescripcion=N'PENDIENTE' WHERE FacturaId=@fact;

 IF @oi<=40
   INSERT Garantias(OrdenTrabajoId,ProductoId,ServicioId,TipoCobertura,FechaInicio,FechaVencimiento,Condiciones,Estado,Observaciones)
   SELECT @oi,op.ProductoId,os.ServicioId,N'SERVICIO Y REPUESTO',CAST(@ofecha AS DATE),DATEADD(DAY,90,CAST(@ofecha AS DATE)),N'Cubre defectos atribuibles al servicio y al repuesto instalado.',N'ACTIVA',N'Garantía generada para orden entregada.'
   FROM OrdenProductos op JOIN OrdenServicios os ON os.OrdenTrabajoId=op.OrdenTrabajoId WHERE op.OrdenTrabajoId=@oi;

 SET @oi+=1;
END

/* ================= 100 VENTAS + 100 FACTURAS ================= */
DECLARE @sv INT=1,@vprod INT,@vcliente INT,@vendedor INT,@cajero INT,@vprice DECIMAL(18,2),@vcost DECIMAL(18,2),@vtax DECIMAL(9,4),@vstock DECIMAL(18,2),@venta INT,@vfact INT,@vsubtotal DECIMAL(18,2),@vimp DECIMAL(18,2),@vtotal DECIMAL(18,2),@vfecha DATETIME2;
WHILE @sv<=100
BEGIN
 SET @vprod=((@sv-1)%50)+1;
 SET @vcliente=((@sv-1)%50)+1;
 SET @vendedor=CASE WHEN @sv%2=0 THEN 6 ELSE 15 END;
 SET @cajero=7;
 SELECT @vprice=PrecioVenta,@vcost=PrecioCompra,@vtax=PorcentajeImpuesto,@vstock=ExistenciaActual FROM Productos WHERE ProductoId=@vprod;
 SET @vfecha=DATEADD(DAY,-(100-@sv),DATEADD(HOUR,14,CAST(CAST(GETDATE() AS DATE) AS DATETIME2)));
 SET @vsubtotal=@vprice;
 SET @vimp=@vsubtotal*@vtax/100.0;
 SET @vtotal=@vsubtotal+@vimp;

 INSERT Ventas(ClienteId,VendedorId,CajeroId,FechaHora,Subtotal,Impuestos,Descuentos,Total,FormaPago,Estado,UsuarioId)
 VALUES(@vcliente,@vendedor,@cajero,@vfecha,@vsubtotal,@vimp,0,@vtotal,CASE WHEN @sv%4=0 THEN N'SINPE MOVIL' WHEN @sv%3=0 THEN N'TARJETA' ELSE N'EFECTIVO' END,N'CONFIRMADA',6);
 SET @venta=SCOPE_IDENTITY();
 INSERT VentaDetalles(VentaId,ProductoId,Cantidad,PrecioUnitario,CostoUnitarioHistorico,ImpuestoPorcentaje,Descuento,TotalLinea)
 VALUES(@venta,@vprod,1,@vprice,@vcost,@vtax,0,@vtotal);
 UPDATE Productos SET ExistenciaActual=ExistenciaActual-1 WHERE ProductoId=@vprod;
 INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,FechaHora,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior,Observaciones)
 VALUES(@vprod,1,N'VENTA',@vfecha,6,CONCAT(N'VEN-',@venta),@vstock,@vstock-1,N'Salida de inventario por venta directa.');

 INSERT Facturas(ClienteId,VentaId,FechaHora,Subtotal,Impuestos,Descuentos,Total,SaldoPendiente,Estado,FormaPagoDescripcion,UsuarioEmisorId)
 VALUES(@vcliente,@venta,@vfecha,@vsubtotal,@vimp,0,@vtotal,@vtotal,N'PENDIENTE',(SELECT FormaPago FROM Ventas WHERE VentaId=@venta),7);
 SET @vfact=SCOPE_IDENTITY();
 INSERT FacturaDetalles(FacturaId,TipoDetalle,ProductoId,Descripcion,Cantidad,PrecioUnitario,CostoUnitarioHistorico,Impuesto,Descuento,TotalLinea)
 SELECT @vfact,N'PRODUCTO',p.ProductoId,p.Nombre,1,@vprice,@vcost,@vimp,0,@vtotal FROM Productos p WHERE p.ProductoId=@vprod;

 IF @sv<=70
 BEGIN
   INSERT Pagos(FacturaId,Monto,FormaPagoId,NumeroReferencia,FechaHora,UsuarioId,Observaciones)
   VALUES(@vfact,@vtotal,CASE WHEN @sv%4=0 THEN 4 WHEN @sv%3=0 THEN 2 ELSE 1 END,CASE WHEN @sv%3=0 OR @sv%4=0 THEN CONCAT(N'REF-VEN-',@sv) ELSE NULL END,DATEADD(MINUTE,5,@vfecha),7,N'Pago completo de venta.');
   UPDATE Facturas SET SaldoPendiente=0,Estado=N'PAGADA' WHERE FacturaId=@vfact;
 END
 ELSE IF @sv<=85
 BEGIN
   INSERT Pagos(FacturaId,Monto,FormaPagoId,NumeroReferencia,FechaHora,UsuarioId,Observaciones)
   VALUES(@vfact,@vtotal/2,3,CONCAT(N'ABONO-VEN-',@sv),DATEADD(MINUTE,5,@vfecha),7,N'Pago parcial de venta.');
   UPDATE Facturas SET SaldoPendiente=@vtotal/2,Estado=N'PARCIALMENTE PAGADA' WHERE FacturaId=@vfact;
 END

 IF @sv<=20
   INSERT Garantias(VentaId,ProductoId,TipoCobertura,FechaInicio,FechaVencimiento,Condiciones,Estado,Observaciones)
   VALUES(@venta,@vprod,N'PRODUCTO',CAST(@vfecha AS DATE),DATEADD(DAY,30,CAST(@vfecha AS DATE)),N'Garantía por defecto de fabricación.',N'ACTIVA',N'Garantía de venta directa.');

 SET @sv+=1;
END


/* Normalizar las referencias de todos los pagos de prueba al patrón
   que utiliza actualmente TallerPro: PAG-00000001, PAG-00000002, ... */
UPDATE dbo.Pagos
SET NumeroReferencia = CONCAT(
    N'PAG-',
    RIGHT(N'00000000' + CONVERT(NVARCHAR(20), PagoId), 8)
);

/* Sincronizar existencia física de bodega con la existencia global actual. */
INSERT ExistenciasBodega(BodegaId,ProductoId,Existencia)
SELECT 1,ProductoId,ExistenciaActual FROM Productos;

/* Algunas notificaciones y auditoría para demostrar los módulos. */
INSERT Auditoria(UsuarioId,DireccionIP,Modulo,Accion,TipoOperacion,RegistroId,ValoresNuevos,Descripcion)
VALUES
(1,N'127.0.0.1',N'SEGURIDAD',N'CARGA_DATOS_PRUEBA',N'INSERT',NULL,N'{"origen":"script inicial"}',N'Carga coherente de datos de demostración.'),
(8,N'127.0.0.1',N'ORDENES',N'APROBACION_MASIVA_DEMO',N'UPDATE',N'1-100',NULL,N'Órdenes de prueba relacionadas con diagnósticos y cotizaciones.'),
(5,N'127.0.0.1',N'INVENTARIO',N'CARGA_INICIAL',N'INSERT',N'1-50',NULL,N'Inventario inicial respaldado por compras.');

EXEC dbo.sp_GenerarNotificacionesSistema @UsuarioId=1;

/* Validaciones de coherencia. Si alguna falla, se revierte TODO el script. */
IF (SELECT COUNT(*) FROM Clientes)<50 THROW 51101,'Faltan clientes.',1;
IF (SELECT COUNT(*) FROM Vehiculos)<75 THROW 51102,'Faltan vehículos.',1;
IF (SELECT COUNT(*) FROM Empleados)<15 THROW 51103,'Faltan empleados.',1;
IF (SELECT COUNT(*) FROM Usuarios)<10 THROW 51104,'Faltan usuarios.',1;
IF (SELECT COUNT(*) FROM Roles)<7 THROW 51105,'Faltan roles.',1;
IF (SELECT COUNT(*) FROM Permisos)<30 THROW 51106,'Faltan permisos.',1;
IF (SELECT COUNT(*) FROM Productos)<50 THROW 51107,'Faltan productos.',1;
IF (SELECT COUNT(*) FROM Servicios)<15 THROW 51108,'Faltan servicios.',1;
IF (SELECT COUNT(*) FROM Proveedores)<10 THROW 51109,'Faltan proveedores.',1;
IF (SELECT COUNT(*) FROM OrdenesTrabajo)<100 THROW 51110,'Faltan órdenes.',1;
IF (SELECT COUNT(*) FROM MovimientosInventario)<150 THROW 51111,'Faltan movimientos.',1;
IF (SELECT COUNT(*) FROM Ventas)<100 THROW 51112,'Faltan ventas.',1;
IF (SELECT COUNT(*) FROM Facturas)<100 THROW 51113,'Faltan facturas.',1;

IF EXISTS(
 SELECT 1 FROM Vehiculos v JOIN Clientes c ON c.ClienteId=v.ClienteId
 WHERE v.ClienteId<>c.ClienteId
) THROW 51120,'Inconsistencia vehículo-cliente.',1;

IF EXISTS(
 SELECT 1 FROM OrdenesTrabajo o JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
 WHERE o.ClienteId<>v.ClienteId
) THROW 51121,'Existe una orden cuyo cliente no es dueño del vehículo.',1;

IF EXISTS(
 SELECT 1 FROM Facturas f JOIN Ventas v ON v.VentaId=f.VentaId
 WHERE f.VentaId IS NOT NULL AND ISNULL(f.ClienteId,-1)<>ISNULL(v.ClienteId,-1)
) THROW 51122,'Existe factura de venta con cliente inconsistente.',1;

IF EXISTS(
 SELECT 1 FROM Facturas f JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=f.OrdenTrabajoId
 WHERE f.OrdenTrabajoId IS NOT NULL AND f.ClienteId<>o.ClienteId
) THROW 51123,'Existe factura de orden con cliente inconsistente.',1;

IF EXISTS(SELECT 1 FROM Productos WHERE ExistenciaActual<0)
 THROW 51124,'La carga dejó existencias negativas.',1;

IF EXISTS(
    SELECT 1
    FROM Garantias g
    WHERE NOT EXISTS(
        SELECT 1
        FROM Facturas f
        WHERE f.Estado=N'PAGADA'
          AND f.SaldoPendiente=0
          AND (
                (g.OrdenTrabajoId IS NOT NULL AND f.OrdenTrabajoId=g.OrdenTrabajoId)
             OR (g.VentaId IS NOT NULL AND f.VentaId=g.VentaId)
          )
    )
)
 THROW 51125,'Existe una garantía asociada a una operación sin factura completamente pagada.',1;

IF EXISTS(
    SELECT 1
    FROM Diagnosticos d
    JOIN Cotizaciones c ON c.DiagnosticoId=d.DiagnosticoId
    WHERE d.Estado<>N'FINALIZADO'
)
 THROW 51126,'Existe una cotización generada desde un diagnóstico que no está FINALIZADO.',1;

COMMIT TRANSACTION;
PRINT 'DATOS DE PRUEBA CARGADOS CORRECTAMENTE.';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 PRINT CONCAT('ERROR DURANTE LA CARGA: ',ERROR_MESSAGE());
 THROW;
END CATCH;

/* ================= RESUMEN PARA VERIFICACIÓN ================= */
SELECT N'Clientes' Entidad,COUNT(*) Cantidad FROM Clientes
UNION ALL SELECT N'Vehículos',COUNT(*) FROM Vehiculos
UNION ALL SELECT N'Empleados',COUNT(*) FROM Empleados
UNION ALL SELECT N'Usuarios',COUNT(*) FROM Usuarios
UNION ALL SELECT N'Roles',COUNT(*) FROM Roles
UNION ALL SELECT N'Permisos',COUNT(*) FROM Permisos
UNION ALL SELECT N'Productos',COUNT(*) FROM Productos
UNION ALL SELECT N'Servicios',COUNT(*) FROM Servicios
UNION ALL SELECT N'Proveedores',COUNT(*) FROM Proveedores
UNION ALL SELECT N'Órdenes de trabajo',COUNT(*) FROM OrdenesTrabajo
UNION ALL SELECT N'Movimientos inventario',COUNT(*) FROM MovimientosInventario
UNION ALL SELECT N'Ventas',COUNT(*) FROM Ventas
UNION ALL SELECT N'Facturas',COUNT(*) FROM Facturas;

/* Ejemplo de trazabilidad: cliente -> vehículos. */
SELECT TOP 25 c.ClienteId,c.NombreRazonSocial,v.VehiculoId,v.Placa,mv.Nombre Modelo,m.Nombre Marca
FROM Clientes c JOIN Vehiculos v ON v.ClienteId=c.ClienteId
JOIN ModelosVehiculo mv ON mv.ModeloId=v.ModeloId JOIN MarcasVehiculo m ON m.MarcaId=mv.MarcaId
ORDER BY c.ClienteId,v.VehiculoId;

/* Ejemplo de trazabilidad completa de una orden facturada. */
SELECT TOP 20 c.NombreRazonSocial,v.Placa,r.NumeroRecepcion,d.NumeroDiagnostico,co.NumeroCotizacion,o.NumeroOrden,f.NumeroFactura,f.Total,f.Estado
FROM OrdenesTrabajo o
JOIN Clientes c ON c.ClienteId=o.ClienteId
JOIN Vehiculos v ON v.VehiculoId=o.VehiculoId
JOIN Cotizaciones co ON co.CotizacionId=o.CotizacionId
JOIN Diagnosticos d ON d.DiagnosticoId=co.DiagnosticoId
JOIN Recepciones r ON r.RecepcionId=d.RecepcionId
LEFT JOIN Facturas f ON f.OrdenTrabajoId=o.OrdenTrabajoId
ORDER BY o.OrdenTrabajoId;

/* Ejemplo de trazabilidad venta -> factura -> pago. */
SELECT TOP 20 v.NumeroVenta,c.NombreRazonSocial,f.NumeroFactura,f.Total,f.SaldoPendiente,f.Estado,
       ISNULL(SUM(p.Monto),0) Pagado
FROM Ventas v
LEFT JOIN Clientes c ON c.ClienteId=v.ClienteId
JOIN Facturas f ON f.VentaId=v.VentaId
LEFT JOIN Pagos p ON p.FacturaId=f.FacturaId AND p.Anulado=0
GROUP BY v.NumeroVenta,c.NombreRazonSocial,f.NumeroFactura,f.Total,f.SaldoPendiente,f.Estado,v.VentaId
ORDER BY v.VentaId;
