-- ============================================================
-- TALLER MECANICO - Script complementario (SQL Server / T-SQL)
-- Este script se ejecuta DESPUES de SQLQuery1.sql (script original)
-- Agrega todo lo que falta segun el enunciado del proyecto:
-- seguridad, catalogos de vehiculos, citas, recepcion, diagnostico,
-- cotizaciones, compras, inventario, facturacion, pagos redisenados,
-- garantias, notificaciones, auditoria, configuracion e indices.
-- ============================================================

USE taller_mecanico;
GO

-- ============================================================
-- 1. SEGURIDAD: USUARIOS, ROLES, PERMISOS
-- ============================================================

CREATE TABLE ROLES (
    id_rol          INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(60) NOT NULL UNIQUE,
    descripcion     VARCHAR(200),
    activo          BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE PERMISOS (
    id_permiso      INT IDENTITY(1,1) PRIMARY KEY,
    codigo          VARCHAR(60) NOT NULL UNIQUE,   -- ej: CONSULTAR, REGISTRAR, MODIFICAR, ELIMINAR, APROBAR_DIAGNOSTICO, etc.
    nombre          VARCHAR(120) NOT NULL,
    descripcion     VARCHAR(200),
    modulo          VARCHAR(60)                     -- modulo al que aplica el permiso
);
GO

CREATE TABLE ROL_PERMISO (
    id_rol          INT NOT NULL,
    id_permiso      INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT FK_rolpermiso_rol FOREIGN KEY (id_rol) REFERENCES ROLES(id_rol),
    CONSTRAINT FK_rolpermiso_permiso FOREIGN KEY (id_permiso) REFERENCES PERMISOS(id_permiso)
);
GO

CREATE TABLE USUARIOS (
    id_usuario          INT IDENTITY(1,1) PRIMARY KEY,
    nombre_usuario      VARCHAR(60) NOT NULL UNIQUE,
    email               VARCHAR(120) NOT NULL UNIQUE,
    password_hash       VARBINARY(256) NOT NULL,
    password_salt       VARBINARY(128) NOT NULL,
    id_cliente          INT NULL,                   -- opcional: usuario tipo cliente (portal)
    activo              BIT NOT NULL DEFAULT 1,
    fecha_creacion      DATETIME NOT NULL DEFAULT GETDATE(),
    ultimo_acceso       DATETIME NULL,
    intentos_fallidos   INT NOT NULL DEFAULT 0,
    bloqueado_hasta     DATETIME NULL,
    CONSTRAINT FK_usuario_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente)
);
GO

CREATE TABLE USUARIO_ROL (
    id_usuario      INT NOT NULL,
    id_rol          INT NOT NULL,
    PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT FK_usuariorol_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario),
    CONSTRAINT FK_usuariorol_rol FOREIGN KEY (id_rol) REFERENCES ROLES(id_rol)
);
GO

-- ============================================================
-- 2. CATALOGOS DE VEHICULOS
-- ============================================================

CREATE TABLE MARCAS_VEHICULO (
    id_marca        INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(60) NOT NULL UNIQUE,
    activo          BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE MODELOS_VEHICULO (
    id_modelo       INT IDENTITY(1,1) PRIMARY KEY,
    id_marca        INT NOT NULL,
    nombre          VARCHAR(60) NOT NULL,
    activo          BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_modelo_marca FOREIGN KEY (id_marca) REFERENCES MARCAS_VEHICULO(id_marca)
);
GO

CREATE TABLE TIPOS_VEHICULO (
    id_tipo_vehiculo   INT IDENTITY(1,1) PRIMARY KEY,
    nombre             VARCHAR(60) NOT NULL UNIQUE,  -- sedan, pickup, moto, camion, etc.
    activo             BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE TIPOS_COMBUSTIBLE (
    id_tipo_combustible INT IDENTITY(1,1) PRIMARY KEY,
    nombre              VARCHAR(40) NOT NULL UNIQUE, -- gasolina, diesel, electrico, hibrido
    activo              BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE CATEGORIAS_VEHICULO (
    id_categoria_vehiculo INT IDENTITY(1,1) PRIMARY KEY,
    nombre                 VARCHAR(60) NOT NULL UNIQUE,
    activo                 BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE CATEGORIAS_SERVICIO (
    id_categoria_servicio INT IDENTITY(1,1) PRIMARY KEY,
    nombre                 VARCHAR(80) NOT NULL UNIQUE,
    activo                 BIT NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- 3. AMPLIAR CLIENTES
-- ============================================================

ALTER TABLE CLIENTES ADD
    identificacion  VARCHAR(30) NULL,
    tipo_cliente    VARCHAR(20) NOT NULL DEFAULT 'FISICO', -- FISICO / JURIDICO
    direccion       VARCHAR(200) NULL,
    activo          BIT NOT NULL DEFAULT 1;
GO

ALTER TABLE CLIENTES ADD CONSTRAINT UQ_clientes_identificacion UNIQUE (identificacion);
GO

-- ============================================================
-- 4. AMPLIAR VEHICULOS (normalizar marca/modelo con catalogos)
-- ============================================================

ALTER TABLE VEHICULOS DROP COLUMN marca, modelo;
GO

ALTER TABLE VEHICULOS ADD
    vin                     VARCHAR(30) NULL,
    id_marca                INT NULL,
    id_modelo               INT NULL,
    anio                    INT NULL,
    id_tipo_vehiculo        INT NULL,
    id_tipo_combustible     INT NULL,
    id_categoria_vehiculo   INT NULL,
    color                   VARCHAR(30) NULL,
    cilindraje              VARCHAR(20) NULL,
    kilometraje             INT NULL,
    fecha_ingreso           DATETIME NULL,
    observaciones           VARCHAR(400) NULL,
    activo                  BIT NOT NULL DEFAULT 1;
GO

ALTER TABLE VEHICULOS ADD
    CONSTRAINT FK_vehiculo_marca FOREIGN KEY (id_marca) REFERENCES MARCAS_VEHICULO(id_marca),
    CONSTRAINT FK_vehiculo_modelo FOREIGN KEY (id_modelo) REFERENCES MODELOS_VEHICULO(id_modelo),
    CONSTRAINT FK_vehiculo_tipo FOREIGN KEY (id_tipo_vehiculo) REFERENCES TIPOS_VEHICULO(id_tipo_vehiculo),
    CONSTRAINT FK_vehiculo_combustible FOREIGN KEY (id_tipo_combustible) REFERENCES TIPOS_COMBUSTIBLE(id_tipo_combustible),
    CONSTRAINT FK_vehiculo_categoria FOREIGN KEY (id_categoria_vehiculo) REFERENCES CATEGORIAS_VEHICULO(id_categoria_vehiculo);
GO

ALTER TABLE VEHICULOS ADD CONSTRAINT UQ_vehiculos_placa UNIQUE (placa);
GO

-- Compatibilidad repuesto - vehiculo (marca/modelo/anio)
CREATE TABLE REPUESTOS_VEHICULOS_COMPATIBLES (
    id_compatibilidad  INT IDENTITY(1,1) PRIMARY KEY,
    id_repuesto        INT NOT NULL,
    id_marca           INT NOT NULL,
    id_modelo          INT NULL,
    anio_desde         INT NULL,
    anio_hasta         INT NULL,
    CONSTRAINT FK_compat_repuesto FOREIGN KEY (id_repuesto) REFERENCES REPUESTOS(id_repuesto),
    CONSTRAINT FK_compat_marca FOREIGN KEY (id_marca) REFERENCES MARCAS_VEHICULO(id_marca),
    CONSTRAINT FK_compat_modelo FOREIGN KEY (id_modelo) REFERENCES MODELOS_VEHICULO(id_modelo)
);
GO

-- ============================================================
-- 5. AMPLIAR EMPLEADOS
-- ============================================================

ALTER TABLE EMPLEADOS ADD
    identificacion      VARCHAR(30) NULL,
    telefono            VARCHAR(20) NULL,
    email               VARCHAR(120) NULL,
    direccion           VARCHAR(200) NULL,
    fecha_contratacion  DATE NULL,
    especialidad        VARCHAR(100) NULL,
    estado_laboral      VARCHAR(20) NOT NULL DEFAULT 'ACTIVO', -- ACTIVO / INACTIVO / VACACIONES / etc.
    id_usuario          INT NULL,
    CONSTRAINT FK_empleado_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario);
GO

ALTER TABLE EMPLEADOS ADD CONSTRAINT UQ_empleados_identificacion UNIQUE (identificacion);
GO

-- ============================================================
-- 6. AMPLIAR PROVEEDORES
-- ============================================================

ALTER TABLE PROVEEDORES ADD
    identificacion          VARCHAR(30) NULL,
    telefono                VARCHAR(20) NULL,
    email                   VARCHAR(120) NULL,
    direccion               VARCHAR(200) NULL,
    contacto_principal      VARCHAR(120) NULL,
    condiciones_pago        VARCHAR(100) NULL,
    estado                  VARCHAR(20) NOT NULL DEFAULT 'ACTIVO';
GO

-- ============================================================
-- 7. AMPLIAR SERVICIOS
-- ============================================================

ALTER TABLE SERVICIOS ADD
    codigo                  VARCHAR(30) NULL,
    id_categoria_servicio   INT NULL,
    tiempo_estimado_min     INT NULL,
    estado                  VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    porcentaje_impuesto     DECIMAL(5,2) NOT NULL DEFAULT 13.00,
    CONSTRAINT FK_servicio_categoria FOREIGN KEY (id_categoria_servicio) REFERENCES CATEGORIAS_SERVICIO(id_categoria_servicio);
GO

ALTER TABLE SERVICIOS ADD CONSTRAINT UQ_servicios_codigo UNIQUE (codigo);
GO

-- ============================================================
-- 8. AMPLIAR REPUESTOS
-- ============================================================

ALTER TABLE REPUESTOS ADD
    codigo_interno       VARCHAR(30) NULL,
    codigo_barras        VARCHAR(40) NULL,
    marca                VARCHAR(60) NULL,
    unidad_medida        VARCHAR(20) NULL,             -- unidad, litro, caja, etc.
    precio_compra        DECIMAL(10,2) NOT NULL DEFAULT 0,
    porcentaje_impuesto  DECIMAL(5,2) NOT NULL DEFAULT 13.00,
    existencia_minima    DECIMAL(10,2) NOT NULL DEFAULT 0,
    existencia_maxima    DECIMAL(10,2) NOT NULL DEFAULT 0,
    ubicacion_bodega     VARCHAR(60) NULL,
    estado               VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    tipo_producto        VARCHAR(20) NOT NULL DEFAULT 'REPUESTO'; -- REPUESTO / HERRAMIENTA / ACCESORIO / LUBRICANTE / OTRO
GO

ALTER TABLE REPUESTOS ADD CONSTRAINT UQ_repuestos_codigo_interno UNIQUE (codigo_interno);
GO
ALTER TABLE REPUESTOS ADD CONSTRAINT UQ_repuestos_codigo_barras UNIQUE (codigo_barras);
GO

-- ============================================================
-- 9. AGENDA Y CITAS
-- ============================================================

CREATE TABLE CITAS (
    id_cita             INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente          INT NOT NULL,
    id_vehiculo         INT NOT NULL,
    id_servicio         INT NULL,
    id_empleado         INT NULL,           -- mecanico o area asignada
    fecha_hora          DATETIME NOT NULL,
    duracion_estimada_min INT NOT NULL DEFAULT 60,
    estado              VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA', -- PROGRAMADA/CONFIRMADA/ATENDIDA/CANCELADA/REPROGRAMADA/AUSENTE
    observaciones       VARCHAR(300) NULL,
    CONSTRAINT FK_cita_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente),
    CONSTRAINT FK_cita_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES VEHICULOS(id_vehiculo),
    CONSTRAINT FK_cita_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIOS(id_servicio),
    CONSTRAINT FK_cita_empleado FOREIGN KEY (id_empleado) REFERENCES EMPLEADOS(id_empleado)
);
GO

-- ============================================================
-- 10. RECEPCION DE VEHICULOS
-- ============================================================

CREATE TABLE RECEPCIONES (
    id_recepcion            INT IDENTITY(1,1) PRIMARY KEY,
    numero_consecutivo      INT NOT NULL,  -- consecutivo visible al cliente (generado por la aplicacion o un trigger)
    id_cliente              INT NOT NULL,
    id_vehiculo             INT NOT NULL,
    id_empleado_recibe      INT NULL,
    fecha_hora_ingreso      DATETIME NOT NULL DEFAULT GETDATE(),
    kilometraje_actual      INT NULL,
    nivel_combustible       VARCHAR(20) NULL,       -- vacio, 1/4, 1/2, 3/4, lleno
    motivo_visita           VARCHAR(200) NULL,
    descripcion_problema    VARCHAR(500) NULL,
    accesorios_entregados   VARCHAR(300) NULL,
    danos_visibles          VARCHAR(300) NULL,
    fecha_estimada_entrega  DATETIME NULL,
    observaciones           VARCHAR(400) NULL,
    CONSTRAINT FK_recepcion_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente),
    CONSTRAINT FK_recepcion_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES VEHICULOS(id_vehiculo),
    CONSTRAINT FK_recepcion_empleado FOREIGN KEY (id_empleado_recibe) REFERENCES EMPLEADOS(id_empleado)
);
GO

ALTER TABLE RECEPCIONES ADD CONSTRAINT UQ_recepciones_consecutivo UNIQUE (numero_consecutivo);
GO

CREATE TABLE RECEPCION_FOTOS (
    id_foto         INT IDENTITY(1,1) PRIMARY KEY,
    id_recepcion    INT NOT NULL,
    url_foto        VARCHAR(300) NOT NULL,
    descripcion     VARCHAR(150) NULL,
    CONSTRAINT FK_foto_recepcion FOREIGN KEY (id_recepcion) REFERENCES RECEPCIONES(id_recepcion)
);
GO

-- ============================================================
-- 11. DIAGNOSTICO MECANICO
-- ============================================================

CREATE TABLE DIAGNOSTICOS (
    id_diagnostico       INT IDENTITY(1,1) PRIMARY KEY,
    id_recepcion         INT NOT NULL,
    id_empleado          INT NOT NULL,          -- mecanico responsable
    problemas_encontrados VARCHAR(1000) NULL,
    pruebas_realizadas   VARCHAR(1000) NULL,
    posibles_causas      VARCHAR(1000) NULL,
    recomendaciones      VARCHAR(1000) NULL,
    mano_obra_estimada   DECIMAL(10,2) NULL,
    tiempo_estimado_horas DECIMAL(6,2) NULL,
    costo_estimado       DECIMAL(10,2) NULL,
    estado               VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE/EN_REVISION/FINALIZADO/APROBADO/RECHAZADO
    fecha_hora           DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_diagnostico_recepcion FOREIGN KEY (id_recepcion) REFERENCES RECEPCIONES(id_recepcion),
    CONSTRAINT FK_diagnostico_empleado FOREIGN KEY (id_empleado) REFERENCES EMPLEADOS(id_empleado)
);
GO

CREATE TABLE DIAGNOSTICO_SERVICIOS (
    id_diagnostico  INT NOT NULL,
    id_servicio     INT NOT NULL,
    PRIMARY KEY (id_diagnostico, id_servicio),
    CONSTRAINT FK_ds_diagnostico FOREIGN KEY (id_diagnostico) REFERENCES DIAGNOSTICOS(id_diagnostico),
    CONSTRAINT FK_ds_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIOS(id_servicio)
);
GO

CREATE TABLE DIAGNOSTICO_REPUESTOS (
    id_diagnostico  INT NOT NULL,
    id_repuesto     INT NOT NULL,
    cantidad_estimada DECIMAL(10,2) NOT NULL DEFAULT 1,
    PRIMARY KEY (id_diagnostico, id_repuesto),
    CONSTRAINT FK_dr_diagnostico FOREIGN KEY (id_diagnostico) REFERENCES DIAGNOSTICOS(id_diagnostico),
    CONSTRAINT FK_dr_repuesto FOREIGN KEY (id_repuesto) REFERENCES REPUESTOS(id_repuesto)
);
GO

-- ============================================================
-- 12. COTIZACIONES
-- ============================================================

CREATE TABLE COTIZACIONES (
    id_cotizacion       INT IDENTITY(1,1) PRIMARY KEY,
    id_diagnostico      INT NOT NULL,
    id_cliente          INT NOT NULL,
    id_vehiculo         INT NOT NULL,
    fecha_emision       DATETIME NOT NULL DEFAULT GETDATE(),
    fecha_vencimiento   DATETIME NULL,
    subtotal            DECIMAL(10,2) NOT NULL DEFAULT 0,
    impuestos           DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuentos           DECIMAL(10,2) NOT NULL DEFAULT 0,
    total               DECIMAL(10,2) NOT NULL DEFAULT 0,
    condiciones          VARCHAR(500) NULL,
    estado               VARCHAR(20) NOT NULL DEFAULT 'ENVIADA', -- ENVIADA/APROBADA/APROBADA_PARCIAL/RECHAZADA/MODIFICADA/CONVERTIDA
    id_usuario_decision   INT NULL,
    fecha_decision        DATETIME NULL,
    CONSTRAINT FK_cotizacion_diagnostico FOREIGN KEY (id_diagnostico) REFERENCES DIAGNOSTICOS(id_diagnostico),
    CONSTRAINT FK_cotizacion_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente),
    CONSTRAINT FK_cotizacion_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES VEHICULOS(id_vehiculo),
    CONSTRAINT FK_cotizacion_usuario FOREIGN KEY (id_usuario_decision) REFERENCES USUARIOS(id_usuario)
);
GO

CREATE TABLE COTIZACION_SERVICIOS (
    id_detalle      INT IDENTITY(1,1) PRIMARY KEY,
    id_cotizacion   INT NOT NULL,
    id_servicio     INT NOT NULL,
    horas_mano_obra DECIMAL(6,2) NOT NULL DEFAULT 0,
    precio_hora     DECIMAL(10,2) NOT NULL DEFAULT 0,
    subtotal        DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_cs_cotizacion FOREIGN KEY (id_cotizacion) REFERENCES COTIZACIONES(id_cotizacion),
    CONSTRAINT FK_cs_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIOS(id_servicio)
);
GO

CREATE TABLE COTIZACION_REPUESTOS (
    id_detalle      INT IDENTITY(1,1) PRIMARY KEY,
    id_cotizacion   INT NOT NULL,
    id_repuesto     INT NOT NULL,
    cantidad        DECIMAL(10,2) NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    subtotal        DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_cr_cotizacion FOREIGN KEY (id_cotizacion) REFERENCES COTIZACIONES(id_cotizacion),
    CONSTRAINT FK_cr_repuesto FOREIGN KEY (id_repuesto) REFERENCES REPUESTOS(id_repuesto)
);
GO

-- ============================================================
-- 13. AMPLIAR ORDENES DE TRABAJO
-- ============================================================

ALTER TABLE ORDENES_TRABAJO ADD
    id_cotizacion           INT NULL,
    prioridad               VARCHAR(20) NOT NULL DEFAULT 'NORMAL', -- BAJA/NORMAL/ALTA/URGENTE
    fecha_estimada_entrega  DATETIME NULL,
    observaciones           VARCHAR(400) NULL,
    CONSTRAINT FK_orden_cotizacion FOREIGN KEY (id_cotizacion) REFERENCES COTIZACIONES(id_cotizacion);
GO

CREATE TABLE HISTORIAL_ESTADO_ORDEN (
    id_historial    INT IDENTITY(1,1) PRIMARY KEY,
    id_orden        INT NOT NULL,
    estado_anterior VARCHAR(20) NULL,
    estado_nuevo    VARCHAR(20) NOT NULL,
    id_usuario      INT NOT NULL,
    fecha_hora      DATETIME NOT NULL DEFAULT GETDATE(),
    observacion     VARCHAR(300) NULL,
    CONSTRAINT FK_hist_orden FOREIGN KEY (id_orden) REFERENCES ORDENES_TRABAJO(id_orden),
    CONSTRAINT FK_hist_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario)
);
GO

CREATE TABLE ORDEN_EMPLEADOS (
    id_orden_empleado  INT IDENTITY(1,1) PRIMARY KEY,
    id_orden            INT NOT NULL,
    id_empleado          INT NOT NULL,
    actividad             VARCHAR(200) NULL,
    fecha_inicio          DATETIME NULL,
    fecha_fin             DATETIME NULL,
    horas_trabajadas      DECIMAL(6,2) NULL,
    costo_hora            DECIMAL(10,2) NULL,
    estado_actividad      VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    observaciones          VARCHAR(300) NULL,
    CONSTRAINT FK_oe_orden FOREIGN KEY (id_orden) REFERENCES ORDENES_TRABAJO(id_orden),
    CONSTRAINT FK_oe_empleado FOREIGN KEY (id_empleado) REFERENCES EMPLEADOS(id_empleado)
);
GO

-- ============================================================
-- 14. COMPRAS
-- ============================================================

CREATE TABLE COMPRAS (
    id_compra                  INT IDENTITY(1,1) PRIMARY KEY,
    id_proveedor                INT NOT NULL,
    numero_factura_proveedor    VARCHAR(40) NULL,
    fecha                        DATETIME NOT NULL DEFAULT GETDATE(),
    subtotal                     DECIMAL(10,2) NOT NULL DEFAULT 0,
    impuestos                    DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuentos                   DECIMAL(10,2) NOT NULL DEFAULT 0,
    total                        DECIMAL(10,2) NOT NULL DEFAULT 0,
    forma_pago                   VARCHAR(20) NOT NULL DEFAULT 'CONTADO', -- CONTADO/CREDITO/PARCIAL
    estado                       VARCHAR(20) NOT NULL DEFAULT 'REGISTRADA',
    id_usuario                   INT NOT NULL,
    CONSTRAINT FK_compra_proveedor FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor),
    CONSTRAINT FK_compra_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario)
);
GO

CREATE TABLE DETALLE_COMPRA (
    id_detalle      INT IDENTITY(1,1) PRIMARY KEY,
    id_compra       INT NOT NULL,
    id_repuesto     INT NOT NULL,
    cantidad        DECIMAL(10,2) NOT NULL,
    costo_unitario  DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_dc_compra FOREIGN KEY (id_compra) REFERENCES COMPRAS(id_compra),
    CONSTRAINT FK_dc_repuesto FOREIGN KEY (id_repuesto) REFERENCES REPUESTOS(id_repuesto)
);
GO

-- ============================================================
-- 15. MOVIMIENTOS DE INVENTARIO
-- ============================================================

CREATE TABLE MOVIMIENTOS_INVENTARIO (
    id_movimiento       INT IDENTITY(1,1) PRIMARY KEY,
    id_repuesto          INT NOT NULL,
    tipo_movimiento       VARCHAR(30) NOT NULL, -- COMPRA/VENTA/USO_ORDEN/DEVOLUCION_CLIENTE/DEVOLUCION_PROVEEDOR/AJUSTE_POSITIVO/AJUSTE_NEGATIVO/DANADO/TRASLADO
    cantidad              DECIMAL(10,2) NOT NULL,
    fecha_hora            DATETIME NOT NULL DEFAULT GETDATE(),
    id_usuario            INT NOT NULL,
    documento_referencia  VARCHAR(60) NULL,      -- ej: numero de orden, venta o compra relacionada
    existencia_anterior   DECIMAL(10,2) NOT NULL,
    existencia_posterior  DECIMAL(10,2) NOT NULL,
    observaciones         VARCHAR(300) NULL,
    CONSTRAINT FK_mov_repuesto FOREIGN KEY (id_repuesto) REFERENCES REPUESTOS(id_repuesto),
    CONSTRAINT FK_mov_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario)
);
GO

-- ============================================================
-- 16. AMPLIAR VENTAS Y DETALLE_VENTA
-- ============================================================

ALTER TABLE VENTAS ADD
    id_vendedor     INT NULL,
    id_cajero       INT NULL,
    subtotal        DECIMAL(10,2) NOT NULL DEFAULT 0,
    impuestos       DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuentos      DECIMAL(10,2) NOT NULL DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL DEFAULT 0,
    forma_pago      VARCHAR(20) NOT NULL DEFAULT 'EFECTIVO',
    estado          VARCHAR(20) NOT NULL DEFAULT 'CONFIRMADA', -- CONFIRMADA/ANULADA/DEVUELTA
    CONSTRAINT FK_venta_vendedor FOREIGN KEY (id_vendedor) REFERENCES EMPLEADOS(id_empleado),
    CONSTRAINT FK_venta_cajero FOREIGN KEY (id_cajero) REFERENCES EMPLEADOS(id_empleado);
GO

ALTER TABLE DETALLE_VENTA ADD
    precio_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuento       DECIMAL(10,2) NOT NULL DEFAULT 0;
GO

-- ============================================================
-- 17. FACTURACION
-- ============================================================

CREATE TABLE FACTURAS (
    id_factura          INT IDENTITY(1,1) PRIMARY KEY,
    numero_consecutivo  INT NOT NULL,              -- generado por la aplicacion o un trigger
    tipo_factura         VARCHAR(20) NOT NULL,     -- ORDEN/VENTA/SERVICIO/MIXTA
    id_orden             INT NULL,
    id_venta             INT NULL,
    id_cliente            INT NULL,
    fecha_hora             DATETIME NOT NULL DEFAULT GETDATE(),
    subtotal               DECIMAL(10,2) NOT NULL DEFAULT 0,
    impuestos              DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuentos             DECIMAL(10,2) NOT NULL DEFAULT 0,
    total                   DECIMAL(10,2) NOT NULL DEFAULT 0,
    forma_pago              VARCHAR(20) NOT NULL DEFAULT 'EFECTIVO',
    estado                  VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE/PAGADA/PARCIAL/ANULADA/REEMBOLSADA
    id_usuario_emite         INT NOT NULL,
    CONSTRAINT FK_factura_orden FOREIGN KEY (id_orden) REFERENCES ORDENES_TRABAJO(id_orden),
    CONSTRAINT FK_factura_venta FOREIGN KEY (id_venta) REFERENCES VENTAS(id_venta),
    CONSTRAINT FK_factura_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente),
    CONSTRAINT FK_factura_usuario FOREIGN KEY (id_usuario_emite) REFERENCES USUARIOS(id_usuario)
);
GO

ALTER TABLE FACTURAS ADD CONSTRAINT UQ_facturas_consecutivo UNIQUE (numero_consecutivo);
GO

-- ============================================================
-- 18. REDISENAR PAGOS (ahora se relacionan con FACTURAS)
-- ============================================================

ALTER TABLE PAGOS DROP CONSTRAINT FK_pago_orden;
GO
ALTER TABLE PAGOS DROP CONSTRAINT FK_pago_venta;
GO
ALTER TABLE PAGOS DROP COLUMN id_orden, id_venta;
GO

ALTER TABLE PAGOS ADD
    id_factura          INT NOT NULL,
    forma_pago           VARCHAR(20) NOT NULL DEFAULT 'EFECTIVO', -- EFECTIVO/TARJETA/TRANSFERENCIA/SINPE/CREDITO/COMBINADO
    numero_referencia    VARCHAR(60) NULL,
    id_usuario_recibe    INT NOT NULL,
    observaciones         VARCHAR(300) NULL,
    CONSTRAINT FK_pago_factura FOREIGN KEY (id_factura) REFERENCES FACTURAS(id_factura),
    CONSTRAINT FK_pago_usuario FOREIGN KEY (id_usuario_recibe) REFERENCES USUARIOS(id_usuario);
GO

-- ============================================================
-- 19. GARANTIAS
-- ============================================================

CREATE TABLE GARANTIAS (
    id_garantia         INT IDENTITY(1,1) PRIMARY KEY,
    tipo_garantia         VARCHAR(20) NOT NULL,  -- SERVICIO/MANO_OBRA/REPUESTO/PRODUCTO
    id_orden               INT NULL,
    id_venta               INT NULL,
    descripcion_cubierto   VARCHAR(300) NULL,
    fecha_inicio           DATE NOT NULL,
    fecha_vencimiento      DATE NOT NULL,
    condiciones            VARCHAR(500) NULL,
    estado                 VARCHAR(20) NOT NULL DEFAULT 'VIGENTE', -- VIGENTE/VENCIDA/RECLAMADA/ANULADA
    observaciones           VARCHAR(300) NULL,
    CONSTRAINT FK_garantia_orden FOREIGN KEY (id_orden) REFERENCES ORDENES_TRABAJO(id_orden),
    CONSTRAINT FK_garantia_venta FOREIGN KEY (id_venta) REFERENCES VENTAS(id_venta)
);
GO

CREATE TABLE GARANTIA_RECLAMOS (
    id_reclamo      INT IDENTITY(1,1) PRIMARY KEY,
    id_garantia      INT NOT NULL,
    fecha_reclamo     DATETIME NOT NULL DEFAULT GETDATE(),
    descripcion        VARCHAR(500) NULL,
    resolucion          VARCHAR(500) NULL,
    estado               VARCHAR(20) NOT NULL DEFAULT 'ABIERTO', -- ABIERTO/EN_PROCESO/RESUELTO/RECHAZADO
    CONSTRAINT FK_reclamo_garantia FOREIGN KEY (id_garantia) REFERENCES GARANTIAS(id_garantia)
);
GO

-- ============================================================
-- 20. NOTIFICACIONES
-- ============================================================

CREATE TABLE NOTIFICACIONES (
    id_notificacion     INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario_destino    INT NOT NULL,
    tipo                    VARCHAR(40) NOT NULL, -- COTIZACION_PENDIENTE/VEHICULO_LISTO/EXISTENCIA_MINIMA/CITA_PROXIMA/etc.
    mensaje                  VARCHAR(300) NOT NULL,
    id_registro_relacionado   INT NULL,
    leida                     BIT NOT NULL DEFAULT 0,
    fecha_hora                DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_notificacion_usuario FOREIGN KEY (id_usuario_destino) REFERENCES USUARIOS(id_usuario)
);
GO

-- ============================================================
-- 21. BITACORA DE AUDITORIA
-- ============================================================

CREATE TABLE BITACORA_AUDITORIA (
    id_bitacora          INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario             INT NULL,
    fecha_hora               DATETIME NOT NULL DEFAULT GETDATE(),
    direccion_ip              VARCHAR(45) NULL,
    modulo                     VARCHAR(60) NOT NULL,
    accion                      VARCHAR(60) NOT NULL,   -- LOGIN/LOGOUT/CREAR/MODIFICAR/ELIMINAR/ANULAR/etc.
    tipo_operacion               VARCHAR(20) NOT NULL,  -- CONSULTA/INSERCION/ACTUALIZACION/ELIMINACION
    id_registro_afectado          INT NULL,
    valores_anteriores             VARCHAR(MAX) NULL,
    valores_nuevos                  VARCHAR(MAX) NULL,
    descripcion                      VARCHAR(400) NULL,
    CONSTRAINT FK_bitacora_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIOS(id_usuario)
);
GO

-- ============================================================
-- 22. CONFIGURACION GENERAL (clave-valor)
-- ============================================================

CREATE TABLE CONFIGURACION_GENERAL (
    clave           VARCHAR(60) NOT NULL PRIMARY KEY,
    valor           VARCHAR(300) NULL,
    descripcion     VARCHAR(200) NULL
);
GO

INSERT INTO CONFIGURACION_GENERAL (clave, valor, descripcion) VALUES
    ('NOMBRE_TALLER', 'Taller Mecanico', 'Nombre comercial del taller'),
    ('IDENTIFICACION_JURIDICA', '', 'Cedula juridica del taller'),
    ('DIRECCION', '', 'Direccion fisica del taller'),
    ('TELEFONO', '', 'Telefono principal'),
    ('EMAIL', '', 'Correo de contacto'),
    ('MONEDA', 'CRC', 'Moneda utilizada en el sistema'),
    ('PORCENTAJE_IMPUESTO_DEFAULT', '13.00', 'Porcentaje de impuesto por defecto'),
    ('LIMITE_DESCUENTO_SIN_AUTORIZACION', '10.00', 'Porcentaje maximo de descuento sin autorizacion'),
    ('PLAZO_GARANTIA_DIAS_DEFAULT', '90', 'Dias de garantia por defecto'),
    ('EXISTENCIA_MINIMA_DEFAULT', '5', 'Existencia minima por defecto para nuevos productos');
GO

-- ============================================================
-- 23. INDICES ADICIONALES (busquedas frecuentes)
-- ============================================================

CREATE INDEX IX_clientes_nombre ON CLIENTES(nombre);
CREATE INDEX IX_clientes_identificacion ON CLIENTES(identificacion);
CREATE INDEX IX_vehiculos_placa ON VEHICULOS(placa);
CREATE INDEX IX_vehiculos_vin ON VEHICULOS(vin);
CREATE INDEX IX_repuestos_nombre ON REPUESTOS(nombre);
CREATE INDEX IX_repuestos_codigo_interno ON REPUESTOS(codigo_interno);
CREATE INDEX IX_ordenes_estado ON ORDENES_TRABAJO(estado);
CREATE INDEX IX_ordenes_fecha ON ORDENES_TRABAJO(fecha_ingreso);
CREATE INDEX IX_facturas_estado ON FACTURAS(estado);
CREATE INDEX IX_facturas_cliente ON FACTURAS(id_cliente);
CREATE INDEX IX_citas_fecha ON CITAS(fecha_hora);
CREATE INDEX IX_movimientos_repuesto ON MOVIMIENTOS_INVENTARIO(id_repuesto);
CREATE INDEX IX_bitacora_usuario_fecha ON BITACORA_AUDITORIA(id_usuario, fecha_hora);
GO

-- ============================================================
-- FIN DEL SCRIPT COMPLEMENTARIO
-- Pendiente en scripts aparte:
--   - Datos de prueba (seed data) segun cantidades minimas pedidas
--   - Procedimientos almacenados / funciones / vistas
--   - Triggers o logica de aplicacion para actualizar inventario,
--     historial de estados y bitacora automaticamente
-- ============================================================
