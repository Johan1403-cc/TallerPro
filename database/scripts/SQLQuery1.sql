-- ============================================================
-- TALLER MECANICO - Script simplificado (SQL Server / T-SQL)
-- ============================================================

CREATE DATABASE taller_mecanico;
GO

USE taller_mecanico;
GO

-- ============================================================
-- CLIENTES Y EMPLEADOS
-- ============================================================

CREATE TABLE CLIENTES (
    id_cliente     INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL,
    telefono       VARCHAR(20),
    email          VARCHAR(120)
);
GO

CREATE TABLE EMPLEADOS (
    id_empleado    INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL,
    cargo          VARCHAR(60)
);
GO

-- ============================================================
-- VEHICULOS
-- ============================================================

CREATE TABLE VEHICULOS (
    id_vehiculo    INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente     INT NOT NULL,
    placa          VARCHAR(15) NOT NULL,
    marca          VARCHAR(60),
    modelo         VARCHAR(60),
    CONSTRAINT FK_vehiculos_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente)
);
GO

-- ============================================================
-- CATALOGOS DE REPUESTOS Y PROVEEDORES
-- ============================================================

CREATE TABLE CATEGORIAS_REPUESTOS (
    id_categoria   INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(80) NOT NULL
);
GO

CREATE TABLE PROVEEDORES (
    id_proveedor       INT IDENTITY(1,1) PRIMARY KEY,
    nombre_empresa     VARCHAR(150) NOT NULL
);
GO

CREATE TABLE REPUESTOS (
    id_repuesto        INT IDENTITY(1,1) PRIMARY KEY,
    id_categoria       INT,
    id_proveedor       INT,
    nombre             VARCHAR(150) NOT NULL,
    stock_actual       DECIMAL(10,2) NOT NULL DEFAULT 0,
    precio_venta       DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_repuestos_categoria FOREIGN KEY (id_categoria) REFERENCES CATEGORIAS_REPUESTOS(id_categoria),
    CONSTRAINT FK_repuestos_proveedor FOREIGN KEY (id_proveedor) REFERENCES PROVEEDORES(id_proveedor)
);
GO

-- ============================================================
-- SERVICIOS
-- ============================================================

CREATE TABLE SERVICIOS (
    id_servicio    INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(120) NOT NULL,
    precio_base    DECIMAL(10,2) NOT NULL
);
GO

-- ============================================================
-- ORDENES DE TRABAJO
-- ============================================================

CREATE TABLE ORDENES_TRABAJO (
    id_orden         INT IDENTITY(1,1) PRIMARY KEY,
    id_vehiculo      INT NOT NULL,
    id_empleado      INT,
    estado           VARCHAR(20) NOT NULL DEFAULT 'REGISTRADA',
    fecha_ingreso    DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_orden_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES VEHICULOS(id_vehiculo),
    CONSTRAINT FK_orden_empleado FOREIGN KEY (id_empleado) REFERENCES EMPLEADOS(id_empleado)
);
GO

CREATE TABLE DETALLE_ORDEN_SERVICIOS (
    id_detalle     INT IDENTITY(1,1) PRIMARY KEY,
    id_orden       INT NOT NULL,
    id_servicio    INT NOT NULL,
    cantidad       DECIMAL(10,2) NOT NULL DEFAULT 1,
    subtotal       DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_dos_orden FOREIGN KEY (id_orden) REFERENCES ORDENES_TRABAJO(id_orden),
    CONSTRAINT FK_dos_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIOS(id_servicio)
);
GO

CREATE TABLE DETALLE_ORDEN_REPUESTOS (
    id_detalle     INT IDENTITY(1,1) PRIMARY KEY,
    id_orden       INT NOT NULL,
    id_repuesto    INT NOT NULL,
    cantidad       DECIMAL(10,2) NOT NULL,
    subtotal       DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_dor_orden FOREIGN KEY (id_orden) REFERENCES ORDENES_TRABAJO(id_orden),
    CONSTRAINT FK_dor_repuesto FOREIGN KEY (id_repuesto) REFERENCES REPUESTOS(id_repuesto)
);
GO

-- ============================================================
-- VENTAS
-- ============================================================

CREATE TABLE VENTAS (
    id_venta       INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente     INT,
    id_empleado    INT NOT NULL,
    fecha          DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_venta_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente),
    CONSTRAINT FK_venta_empleado FOREIGN KEY (id_empleado) REFERENCES EMPLEADOS(id_empleado)
);
GO

CREATE TABLE DETALLE_VENTA (
    id_detalle     INT IDENTITY(1,1) PRIMARY KEY,
    id_venta       INT NOT NULL,
    id_repuesto    INT NOT NULL,
    cantidad       DECIMAL(10,2) NOT NULL,
    subtotal       DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_dv_venta FOREIGN KEY (id_venta) REFERENCES VENTAS(id_venta),
    CONSTRAINT FK_dv_repuesto FOREIGN KEY (id_repuesto) REFERENCES REPUESTOS(id_repuesto)
);
GO

-- ============================================================
-- PAGOS
-- ============================================================

CREATE TABLE PAGOS (
    id_pago        INT IDENTITY(1,1) PRIMARY KEY,
    id_orden       INT NULL,
    id_venta       INT NULL,
    monto          DECIMAL(10,2) NOT NULL,
    fecha          DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_pago_orden FOREIGN KEY (id_orden) REFERENCES ORDENES_TRABAJO(id_orden),
    CONSTRAINT FK_pago_venta FOREIGN KEY (id_venta) REFERENCES VENTAS(id_venta)
);
GO