/* ============================================================
   TallerProDB - SCRIPT FINAL CONSOLIDADO DE CREACION
   SQL Server 2019+ / SQL Server 2022 / Azure SQL (omitir CREATE DATABASE en Azure)
   Esquema normalizado, claves, restricciones, índices, vistas y transacciones.
   NO contiene datos de prueba. Ejecute luego 02_TallerPro_INSERCION_DATOS.sql.
   ============================================================ */
IF DB_ID(N'TallerProDB') IS NULL
BEGIN
    CREATE DATABASE TallerProDB;
END
GO
USE TallerProDB;
GO

/* ========================= SEGURIDAD ========================= */
CREATE TABLE Roles(
    RolId INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL UNIQUE,
    Descripcion NVARCHAR(300) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Roles_Activo DEFAULT 1,
    CreadoEn DATETIME2 NOT NULL CONSTRAINT DF_Roles_Fecha DEFAULT SYSDATETIME()
);
GO
CREATE TABLE Permisos(
    PermisoId INT IDENTITY(1,1) PRIMARY KEY,
    Codigo VARCHAR(100) NOT NULL UNIQUE,
    Nombre NVARCHAR(120) NOT NULL,
    Modulo NVARCHAR(80) NOT NULL,
    Descripcion NVARCHAR(300) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Permisos_Activo DEFAULT 1
);
GO
CREATE TABLE RolPermisos(
    RolId INT NOT NULL,
    PermisoId INT NOT NULL,
    CONSTRAINT PK_RolPermisos PRIMARY KEY(RolId,PermisoId),
    CONSTRAINT FK_RolPermisos_Rol FOREIGN KEY(RolId) REFERENCES Roles(RolId),
    CONSTRAINT FK_RolPermisos_Permiso FOREIGN KEY(PermisoId) REFERENCES Permisos(PermisoId)
);
GO
CREATE TABLE Usuarios(
    UsuarioId INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario NVARCHAR(80) NOT NULL UNIQUE,
    Correo NVARCHAR(160) NOT NULL UNIQUE,
    PasswordSalt VARCHAR(64) NOT NULL,
    PasswordHash VARCHAR(128) NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT 1,
    DebeCambiarPassword BIT NOT NULL CONSTRAINT DF_Usuarios_Cambiar DEFAULT 0,
    IntentosFallidos INT NOT NULL CONSTRAINT DF_Usuarios_Intentos DEFAULT 0,
    BloqueadoHasta DATETIME2 NULL,
    UltimoAcceso DATETIME2 NULL,
    CreadoEn DATETIME2 NOT NULL CONSTRAINT DF_Usuarios_Creado DEFAULT SYSDATETIME(),
    ModificadoEn DATETIME2 NULL,
    CONSTRAINT CK_Usuarios_Intentos CHECK(IntentosFallidos>=0)
);
GO
CREATE INDEX IX_Usuarios_Correo ON Usuarios(Correo);
CREATE INDEX IX_Usuarios_Nombre ON Usuarios(NombreUsuario);
GO
CREATE TABLE UsuarioRoles(
    UsuarioId INT NOT NULL,
    RolId INT NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_UsuarioRoles_Activo DEFAULT 1,
    AsignadoEn DATETIME2 NOT NULL CONSTRAINT DF_UsuarioRoles_Fecha DEFAULT SYSDATETIME(),
    CONSTRAINT PK_UsuarioRoles PRIMARY KEY(UsuarioId,RolId),
    CONSTRAINT FK_UsuarioRoles_Usuario FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT FK_UsuarioRoles_Rol FOREIGN KEY(RolId) REFERENCES Roles(RolId)
);
GO
CREATE TABLE SesionesUsuario(
    SesionId BIGINT IDENTITY(1,1) PRIMARY KEY,
    UsuarioId INT NOT NULL,
    TokenHash CHAR(64) NOT NULL UNIQUE,
    CsrfToken VARCHAR(64) NOT NULL,
    CreadaEn DATETIME2 NOT NULL,
    ExpiraEn DATETIME2 NOT NULL,
    DireccionIP NVARCHAR(64) NULL,
    UserAgent NVARCHAR(500) NULL,
    Revocada BIT NOT NULL CONSTRAINT DF_Sesiones_Revocada DEFAULT 0,
    CONSTRAINT FK_Sesiones_Usuario FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId)
);
GO
CREATE INDEX IX_Sesiones_Usuario_Expira ON SesionesUsuario(UsuarioId,ExpiraEn);
GO

/* ======================= EMPLEADOS =========================== */
CREATE TABLE Empleados(
    EmpleadoId INT IDENTITY(1,1) PRIMARY KEY,
    Identificacion NVARCHAR(30) NOT NULL UNIQUE,
    NombreCompleto NVARCHAR(180) NOT NULL,
    Telefono NVARCHAR(30) NULL,
    Correo NVARCHAR(160) NULL,
    Direccion NVARCHAR(400) NULL,
    FechaContratacion DATE NOT NULL,
    Especialidad NVARCHAR(160) NULL,
    EstadoLaboral NVARCHAR(30) NOT NULL CONSTRAINT DF_Empleado_Estado DEFAULT N'ACTIVO',
    UsuarioId INT NULL UNIQUE,
    CreadoEn DATETIME2 NOT NULL CONSTRAINT DF_Empleado_Creado DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Empleados_Usuario FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Empleado_Estado CHECK(EstadoLaboral IN(N'ACTIVO',N'INACTIVO',N'VACACIONES',N'SUSPENDIDO',N'RETIRADO'))
);
GO
CREATE INDEX IX_Empleados_Nombre ON Empleados(NombreCompleto);
CREATE INDEX IX_Empleados_Correo ON Empleados(Correo);
GO

/* ======================= CLIENTES ============================ */
CREATE TABLE Clientes(
    ClienteId INT IDENTITY(1,1) PRIMARY KEY,
    TipoCliente NVARCHAR(20) NOT NULL,
    NombreRazonSocial NVARCHAR(200) NOT NULL,
    Identificacion NVARCHAR(40) NOT NULL UNIQUE,
    Telefono NVARCHAR(30) NULL,
    Correo NVARCHAR(160) NULL,
    Direccion NVARCHAR(500) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Clientes_Activo DEFAULT 1,
    CreadoEn DATETIME2 NOT NULL CONSTRAINT DF_Clientes_Creado DEFAULT SYSDATETIME(),
    ModificadoEn DATETIME2 NULL,
    CONSTRAINT CK_Cliente_Tipo CHECK(TipoCliente IN(N'FISICO',N'JURIDICO'))
);
GO
CREATE INDEX IX_Clientes_Nombre ON Clientes(NombreRazonSocial);
CREATE INDEX IX_Clientes_Telefono ON Clientes(Telefono);
CREATE INDEX IX_Clientes_Correo ON Clientes(Correo);
GO

/* ================== CATALOGOS DE VEHICULOS ================== */
CREATE TABLE MarcasVehiculo(MarcaId INT IDENTITY PRIMARY KEY,Nombre NVARCHAR(100) NOT NULL UNIQUE,Activo BIT NOT NULL DEFAULT 1);
CREATE TABLE ModelosVehiculo(ModeloId INT IDENTITY PRIMARY KEY,MarcaId INT NOT NULL,Nombre NVARCHAR(120) NOT NULL,Activo BIT NOT NULL DEFAULT 1,CONSTRAINT UQ_Modelo_Marca UNIQUE(MarcaId,Nombre),CONSTRAINT FK_Modelo_Marca FOREIGN KEY(MarcaId) REFERENCES MarcasVehiculo(MarcaId));
CREATE TABLE TiposVehiculo(TipoVehiculoId INT IDENTITY PRIMARY KEY,Nombre NVARCHAR(100) NOT NULL UNIQUE,Activo BIT NOT NULL DEFAULT 1);
CREATE TABLE TiposCombustible(TipoCombustibleId INT IDENTITY PRIMARY KEY,Nombre NVARCHAR(100) NOT NULL UNIQUE,Activo BIT NOT NULL DEFAULT 1);
CREATE TABLE CategoriasVehiculo(CategoriaVehiculoId INT IDENTITY PRIMARY KEY,Nombre NVARCHAR(100) NOT NULL UNIQUE,Activo BIT NOT NULL DEFAULT 1);
GO
CREATE TABLE Vehiculos(
    VehiculoId INT IDENTITY(1,1) PRIMARY KEY,
    ClienteId INT NOT NULL,
    Placa NVARCHAR(20) NOT NULL UNIQUE,
    VIN NVARCHAR(40) NOT NULL UNIQUE,
    ModeloId INT NOT NULL,
    TipoVehiculoId INT NOT NULL,
    TipoCombustibleId INT NOT NULL,
    CategoriaVehiculoId INT NULL,
    Anio SMALLINT NOT NULL,
    Color NVARCHAR(60) NULL,
    CilindrajeCC INT NULL,
    KilometrajeActual INT NOT NULL CONSTRAINT DF_Vehiculos_Km DEFAULT 0,
    FechaIngreso DATE NOT NULL CONSTRAINT DF_Vehiculos_Fecha DEFAULT CAST(GETDATE() AS DATE),
    Observaciones NVARCHAR(1000) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Vehiculos_Activo DEFAULT 1,
    CONSTRAINT FK_Vehiculos_Cliente FOREIGN KEY(ClienteId) REFERENCES Clientes(ClienteId),
    CONSTRAINT FK_Vehiculos_Modelo FOREIGN KEY(ModeloId) REFERENCES ModelosVehiculo(ModeloId),
    CONSTRAINT FK_Vehiculos_Tipo FOREIGN KEY(TipoVehiculoId) REFERENCES TiposVehiculo(TipoVehiculoId),
    CONSTRAINT FK_Vehiculos_Comb FOREIGN KEY(TipoCombustibleId) REFERENCES TiposCombustible(TipoCombustibleId),
    CONSTRAINT FK_Vehiculos_Cat FOREIGN KEY(CategoriaVehiculoId) REFERENCES CategoriasVehiculo(CategoriaVehiculoId),
    CONSTRAINT CK_Vehiculos_Anio CHECK(Anio BETWEEN 1900 AND 2200),
    CONSTRAINT CK_Vehiculos_Km CHECK(KilometrajeActual>=0)
);
GO
CREATE INDEX IX_Vehiculos_Cliente ON Vehiculos(ClienteId);
CREATE INDEX IX_Vehiculos_Placa ON Vehiculos(Placa);
CREATE INDEX IX_Vehiculos_VIN ON Vehiculos(VIN);
GO
CREATE TABLE HistorialKilometraje(
    HistorialKilometrajeId BIGINT IDENTITY PRIMARY KEY,
    VehiculoId INT NOT NULL,
    Kilometraje INT NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Origen NVARCHAR(50) NOT NULL,
    RegistroReferenciaId INT NULL,
    CONSTRAINT FK_HistorialKm_Vehiculo FOREIGN KEY(VehiculoId) REFERENCES Vehiculos(VehiculoId),
    CONSTRAINT CK_HistorialKm CHECK(Kilometraje>=0)
);
GO

/* ======================= SERVICIOS =========================== */
CREATE TABLE Servicios(
    ServicioId INT IDENTITY PRIMARY KEY,
    Codigo NVARCHAR(30) NOT NULL UNIQUE,
    Nombre NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(1000) NULL,
    Categoria NVARCHAR(100) NULL,
    PrecioBase DECIMAL(18,2) NOT NULL,
    TiempoEstimadoMinutos INT NOT NULL,
    PorcentajeImpuesto DECIMAL(9,4) NOT NULL DEFAULT 13,
    Activo BIT NOT NULL DEFAULT 1,
    CreadoEn DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Servicio_Precio CHECK(PrecioBase>=0),
    CONSTRAINT CK_Servicio_Tiempo CHECK(TiempoEstimadoMinutos>=0),
    CONSTRAINT CK_Servicio_Impuesto CHECK(PorcentajeImpuesto BETWEEN 0 AND 100)
);
GO
CREATE INDEX IX_Servicios_Nombre ON Servicios(Nombre);
GO

/* ====================== PROVEEDORES ========================== */
CREATE TABLE Proveedores(
    ProveedorId INT IDENTITY PRIMARY KEY,
    TipoIdentificacion NVARCHAR(30) NULL,
    Identificacion NVARCHAR(40) NOT NULL UNIQUE,
    NombreRazonSocial NVARCHAR(200) NOT NULL,
    Telefono NVARCHAR(30) NULL,
    Correo NVARCHAR(160) NULL,
    Direccion NVARCHAR(500) NULL,
    ContactoPrincipal NVARCHAR(160) NULL,
    CondicionesPago NVARCHAR(300) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CreadoEn DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE INDEX IX_Proveedor_Nombre ON Proveedores(NombreRazonSocial);
CREATE TABLE ProveedorContactos(
    ProveedorContactoId INT IDENTITY PRIMARY KEY,
    ProveedorId INT NOT NULL,
    Nombre NVARCHAR(160) NOT NULL,
    Telefono NVARCHAR(30) NULL,
    Correo NVARCHAR(160) NULL,
    Cargo NVARCHAR(100) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_ProveedorContacto FOREIGN KEY(ProveedorId) REFERENCES Proveedores(ProveedorId)
);
GO

/* ================= PRODUCTOS / REPUESTOS ==================== */
CREATE TABLE Productos(
    ProductoId INT IDENTITY PRIMARY KEY,
    CodigoInterno NVARCHAR(40) NOT NULL UNIQUE,
    CodigoBarras NVARCHAR(80) NULL UNIQUE,
    Nombre NVARCHAR(180) NOT NULL,
    Descripcion NVARCHAR(1000) NULL,
    Categoria NVARCHAR(100) NULL,
    Marca NVARCHAR(100) NULL,
    UnidadMedida NVARCHAR(40) NOT NULL DEFAULT N'UNIDAD',
    PrecioCompra DECIMAL(18,2) NOT NULL DEFAULT 0,
    PrecioVenta DECIMAL(18,2) NOT NULL DEFAULT 0,
    PorcentajeImpuesto DECIMAL(9,4) NOT NULL DEFAULT 13,
    ExistenciaActual DECIMAL(18,2) NOT NULL DEFAULT 0,
    ExistenciaMinima DECIMAL(18,2) NOT NULL DEFAULT 0,
    ExistenciaMaxima DECIMAL(18,2) NULL,
    Ubicacion NVARCHAR(120) NULL,
    ProveedorPrincipalId INT NULL,
    TipoProducto NVARCHAR(30) NOT NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Producto_Proveedor FOREIGN KEY(ProveedorPrincipalId) REFERENCES Proveedores(ProveedorId),
    CONSTRAINT CK_Producto_Precios CHECK(PrecioCompra>=0 AND PrecioVenta>=0),
    CONSTRAINT CK_Producto_Impuesto CHECK(PorcentajeImpuesto BETWEEN 0 AND 100),
    CONSTRAINT CK_Producto_Existencias CHECK(ExistenciaMinima>=0 AND (ExistenciaMaxima IS NULL OR ExistenciaMaxima>=ExistenciaMinima)),
    CONSTRAINT CK_Producto_Tipo CHECK(TipoProducto IN(N'REPUESTO',N'HERRAMIENTA',N'ACCESORIO',N'LUBRICANTE',N'OTRO'))
);
GO
CREATE INDEX IX_Producto_Nombre ON Productos(Nombre);
CREATE INDEX IX_Producto_Categoria ON Productos(Categoria);
CREATE INDEX IX_Producto_Stock ON Productos(ExistenciaActual,ExistenciaMinima);
GO
CREATE TABLE ProductoProveedores(
    ProductoId INT NOT NULL,
    ProveedorId INT NOT NULL,
    CodigoProveedor NVARCHAR(80) NULL,
    CostoReferencia DECIMAL(18,2) NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ProductoProveedor PRIMARY KEY(ProductoId,ProveedorId),
    CONSTRAINT FK_PP_Producto FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId),
    CONSTRAINT FK_PP_Proveedor FOREIGN KEY(ProveedorId) REFERENCES Proveedores(ProveedorId)
);
GO
CREATE TABLE ProductoCompatibilidadVehiculo(
    ProductoCompatibilidadId INT IDENTITY PRIMARY KEY,
    ProductoId INT NOT NULL,
    MarcaId INT NOT NULL,
    ModeloId INT NULL,
    AnioDesde SMALLINT NULL,
    AnioHasta SMALLINT NULL,
    Observaciones NVARCHAR(300) NULL,
    CONSTRAINT FK_Compat_Producto FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId),
    CONSTRAINT FK_Compat_Marca FOREIGN KEY(MarcaId) REFERENCES MarcasVehiculo(MarcaId),
    CONSTRAINT FK_Compat_Modelo FOREIGN KEY(ModeloId) REFERENCES ModelosVehiculo(ModeloId),
    CONSTRAINT CK_Compat_Anio CHECK(AnioDesde IS NULL OR AnioHasta IS NULL OR AnioHasta>=AnioDesde)
);
GO

/* ========================= BODEGAS =========================== */
CREATE TABLE Bodegas(
    BodegaId INT IDENTITY PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL UNIQUE,
    Ubicacion NVARCHAR(250) NULL,
    Activa BIT NOT NULL DEFAULT 1
);
GO
CREATE TABLE ExistenciasBodega(
    BodegaId INT NOT NULL,
    ProductoId INT NOT NULL,
    Existencia DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT PK_ExistenciasBodega PRIMARY KEY(BodegaId,ProductoId),
    CONSTRAINT FK_EB_Bodega FOREIGN KEY(BodegaId) REFERENCES Bodegas(BodegaId),
    CONSTRAINT FK_EB_Producto FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId)
);
GO

/* ========================= CITAS ============================= */
CREATE TABLE AreasTrabajo(
    AreaTrabajoId INT IDENTITY PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL UNIQUE,
    Descripcion NVARCHAR(300) NULL,
    Activa BIT NOT NULL DEFAULT 1
);
GO
CREATE TABLE Citas(
    CitaId INT IDENTITY PRIMARY KEY,
    ClienteId INT NOT NULL,
    VehiculoId INT NOT NULL,
    ServicioId INT NULL,
    EmpleadoId INT NULL,
    AreaTrabajo NVARCHAR(100) NULL,
    AreaTrabajoId INT NULL,
    FechaHoraInicio DATETIME2 NOT NULL,
    DuracionEstimadaMinutos INT NOT NULL DEFAULT 60,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'PROGRAMADA',
    Observaciones NVARCHAR(1000) NULL,
    CreadaPorUsuarioId INT NULL,
    CreadoEn DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Cita_Cliente FOREIGN KEY(ClienteId) REFERENCES Clientes(ClienteId),
    CONSTRAINT FK_Cita_Vehiculo FOREIGN KEY(VehiculoId) REFERENCES Vehiculos(VehiculoId),
    CONSTRAINT FK_Cita_Servicio FOREIGN KEY(ServicioId) REFERENCES Servicios(ServicioId),
    CONSTRAINT FK_Cita_Empleado FOREIGN KEY(EmpleadoId) REFERENCES Empleados(EmpleadoId),
    CONSTRAINT FK_Cita_Area FOREIGN KEY(AreaTrabajoId) REFERENCES AreasTrabajo(AreaTrabajoId),
    CONSTRAINT FK_Cita_Usuario FOREIGN KEY(CreadaPorUsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Cita_Estado CHECK(Estado IN(N'PROGRAMADA',N'CONFIRMADA',N'ATENDIDA',N'CANCELADA',N'REPROGRAMADA',N'CLIENTE AUSENTE')),
    CONSTRAINT CK_Cita_Duracion CHECK(DuracionEstimadaMinutos>0)
);
GO
CREATE INDEX IX_Citas_Fecha_Empleado ON Citas(FechaHoraInicio,EmpleadoId,Estado);
GO
CREATE TABLE CitaServicios(
    CitaId INT NOT NULL,
    ServicioId INT NOT NULL,
    PRIMARY KEY(CitaId,ServicioId),
    FOREIGN KEY(CitaId) REFERENCES Citas(CitaId) ON DELETE CASCADE,
    FOREIGN KEY(ServicioId) REFERENCES Servicios(ServicioId)
);
CREATE TABLE CitaMecanicos(
    CitaId INT NOT NULL,
    EmpleadoId INT NOT NULL,
    PRIMARY KEY(CitaId,EmpleadoId),
    FOREIGN KEY(CitaId) REFERENCES Citas(CitaId) ON DELETE CASCADE,
    FOREIGN KEY(EmpleadoId) REFERENCES Empleados(EmpleadoId)
);
GO

/* ======================= RECEPCION =========================== */
CREATE SEQUENCE SeqRecepcion AS BIGINT START WITH 1 INCREMENT BY 1;
GO
CREATE TABLE Recepciones(
    RecepcionId INT IDENTITY PRIMARY KEY,
    NumeroRecepcion AS (CONCAT('REC-',RIGHT('00000000'+CONVERT(VARCHAR(8),RecepcionId),8))) PERSISTED UNIQUE,
    ClienteId INT NOT NULL,
    VehiculoId INT NOT NULL,
    FechaHoraIngreso DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    KilometrajeIngreso INT NOT NULL,
    NivelCombustible NVARCHAR(30) NOT NULL,
    MotivoVisita NVARCHAR(500) NOT NULL,
    ProblemaCliente NVARCHAR(1500) NULL,
    AccesoriosObjetos NVARCHAR(1000) NULL,
    DanosVisibles NVARCHAR(1500) NULL,
    EmpleadoRecibeId INT NOT NULL,
    FechaEstimadaEntrega DATETIME2 NULL,
    Observaciones NVARCHAR(1500) NULL,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'RECIBIDA',
    CONSTRAINT FK_Recepcion_Cliente FOREIGN KEY(ClienteId) REFERENCES Clientes(ClienteId),
    CONSTRAINT FK_Recepcion_Vehiculo FOREIGN KEY(VehiculoId) REFERENCES Vehiculos(VehiculoId),
    CONSTRAINT FK_Recepcion_Empleado FOREIGN KEY(EmpleadoRecibeId) REFERENCES Empleados(EmpleadoId),
    CONSTRAINT CK_Recepcion_Km CHECK(KilometrajeIngreso>=0),
    CONSTRAINT CK_Recepcion_Comb CHECK(NivelCombustible IN(N'NULO',N'POCO',N'INTERMEDIO',N'SOBRE LA MITAD',N'LLENO'))
);
GO
CREATE INDEX IX_Recepcion_Vehiculo_Fecha ON Recepciones(VehiculoId,FechaHoraIngreso DESC);
CREATE TABLE RecepcionFotografias(
    FotografiaId INT IDENTITY PRIMARY KEY,
    RecepcionId INT NOT NULL,
    NombreArchivo NVARCHAR(250) NOT NULL,
    RutaArchivo NVARCHAR(500) NOT NULL,
    ContenidoBase64 NVARCHAR(MAX) NULL,
    Descripcion NVARCHAR(300) NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Foto_Recepcion FOREIGN KEY(RecepcionId) REFERENCES Recepciones(RecepcionId)
);
GO

/* ======================= DIAGNOSTICO ========================= */
CREATE TABLE Diagnosticos(
    DiagnosticoId INT IDENTITY PRIMARY KEY,
    NumeroDiagnostico AS (CONCAT('DIA-',RIGHT('00000000'+CONVERT(VARCHAR(8),DiagnosticoId),8))) PERSISTED UNIQUE,
    RecepcionId INT NOT NULL,
    ProblemasEncontrados NVARCHAR(2000) NULL,
    PruebasRealizadas NVARCHAR(2000) NULL,
    PosiblesCausas NVARCHAR(2000) NULL,
    Recomendaciones NVARCHAR(2000) NULL,
    ManoObraEstimada DECIMAL(18,2) NOT NULL DEFAULT 0,
    TiempoEstimadoMinutos INT NOT NULL DEFAULT 0,
    CostoEstimado DECIMAL(18,2) NOT NULL DEFAULT 0,
    MecanicoResponsableId INT NOT NULL,
    FechaHoraDiagnostico DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Estado NVARCHAR(30) NOT NULL DEFAULT N'PENDIENTE',
    AprobadoPorUsuarioId INT NULL,
    FechaAprobacion DATETIME2 NULL,
    CONSTRAINT FK_Diag_Recepcion FOREIGN KEY(RecepcionId) REFERENCES Recepciones(RecepcionId),
    CONSTRAINT FK_Diag_Mecanico FOREIGN KEY(MecanicoResponsableId) REFERENCES Empleados(EmpleadoId),
    CONSTRAINT FK_Diag_Aprobador FOREIGN KEY(AprobadoPorUsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Diag_Estado CHECK(Estado IN(N'PENDIENTE',N'EN REVISION',N'FINALIZADO',N'APROBADO',N'RECHAZADO POR EL CLIENTE'))
);
GO
CREATE TABLE DiagnosticoMecanicos(
    DiagnosticoId INT NOT NULL,
    EmpleadoId INT NOT NULL,
    Observacion NVARCHAR(500) NULL,
    CONSTRAINT PK_DiagMecanicos PRIMARY KEY(DiagnosticoId,EmpleadoId),
    CONSTRAINT FK_DM_Diag FOREIGN KEY(DiagnosticoId) REFERENCES Diagnosticos(DiagnosticoId),
    CONSTRAINT FK_DM_Emp FOREIGN KEY(EmpleadoId) REFERENCES Empleados(EmpleadoId)
);
CREATE TABLE DiagnosticoServicios(
    DiagnosticoServicioId INT IDENTITY PRIMARY KEY,
    DiagnosticoId INT NOT NULL,
    ServicioId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL DEFAULT 1,
    PrecioEstimado DECIMAL(18,2) NOT NULL,
    TiempoEstimadoMinutos INT NOT NULL,
    Recomendado BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_DS_Diag FOREIGN KEY(DiagnosticoId) REFERENCES Diagnosticos(DiagnosticoId),
    CONSTRAINT FK_DS_Serv FOREIGN KEY(ServicioId) REFERENCES Servicios(ServicioId)
);
CREATE TABLE DiagnosticoProductos(
    DiagnosticoProductoId INT IDENTITY PRIMARY KEY,
    DiagnosticoId INT NOT NULL,
    ProductoId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    PrecioUnitarioEstimado DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_DP_Diag FOREIGN KEY(DiagnosticoId) REFERENCES Diagnosticos(DiagnosticoId),
    CONSTRAINT FK_DP_Prod FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId)
);
GO

/* ======================= COTIZACIONES ======================== */
CREATE TABLE Cotizaciones(
    CotizacionId INT IDENTITY PRIMARY KEY,
    NumeroCotizacion AS (CONCAT('COT-',RIGHT('00000000'+CONVERT(VARCHAR(8),CotizacionId),8))) PERSISTED UNIQUE,
    DiagnosticoId INT NOT NULL,
    FechaEmision DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FechaVencimiento DATE NOT NULL,
    HorasManoObra DECIMAL(9,2) NOT NULL DEFAULT 0,
    PrecioHoraManoObra DECIMAL(18,2) NOT NULL DEFAULT 0,
    Subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    Impuestos DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuento DECIMAL(18,2) NOT NULL DEFAULT 0,
    DescuentoPorcentaje DECIMAL(9,4) NOT NULL DEFAULT 0,
    TotalEstimado DECIMAL(18,2) NOT NULL DEFAULT 0,
    Condiciones NVARCHAR(1000) NULL,
    Observaciones NVARCHAR(1000) NULL,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'BORRADOR',
    AprobacionTipo NVARCHAR(20) NULL,
    UsuarioDecisionId INT NULL,
    FechaHoraDecision DATETIME2 NULL,
    UsuarioConversionId INT NULL,
    FechaHoraConversion DATETIME2 NULL,
    CONSTRAINT FK_Cot_Diag FOREIGN KEY(DiagnosticoId) REFERENCES Diagnosticos(DiagnosticoId),
    CONSTRAINT FK_Cot_Decision FOREIGN KEY(UsuarioDecisionId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT FK_Cot_Conversion FOREIGN KEY(UsuarioConversionId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Cot_Estado CHECK(Estado IN(N'BORRADOR',N'ENVIADA',N'APROBADA',N'APROBADA PARCIAL',N'RECHAZADA',N'MODIFICADA',N'CONVERTIDA'))
);
GO
CREATE TABLE CotizacionServicios(
    CotizacionServicioId INT IDENTITY PRIMARY KEY,
    CotizacionId INT NOT NULL,
    ServicioId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL DEFAULT 1,
    PrecioUnitario DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL DEFAULT 0,
    Descuento DECIMAL(18,2) NOT NULL DEFAULT 0,
    Aprobado BIT NULL,
    TiempoEstimadoMinutos INT NOT NULL DEFAULT 0,
    CONSTRAINT FK_CS_Cot FOREIGN KEY(CotizacionId) REFERENCES Cotizaciones(CotizacionId),
    CONSTRAINT FK_CS_Serv FOREIGN KEY(ServicioId) REFERENCES Servicios(ServicioId)
);
CREATE TABLE CotizacionProductos(
    CotizacionProductoId INT IDENTITY PRIMARY KEY,
    CotizacionId INT NOT NULL,
    ProductoId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    PrecioUnitario DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL DEFAULT 0,
    Descuento DECIMAL(18,2) NOT NULL DEFAULT 0,
    Aprobado BIT NULL,
    CONSTRAINT FK_CP_Cot FOREIGN KEY(CotizacionId) REFERENCES Cotizaciones(CotizacionId),
    CONSTRAINT FK_CP_Prod FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId)
);
GO

/* ==================== ORDENES DE TRABAJO ==================== */
CREATE TABLE OrdenesTrabajo(
    OrdenTrabajoId INT IDENTITY PRIMARY KEY,
    NumeroOrden AS (CONCAT('OT-',RIGHT('00000000'+CONVERT(VARCHAR(8),OrdenTrabajoId),8))) PERSISTED UNIQUE,
    CotizacionId INT NULL UNIQUE,
    ClienteId INT NOT NULL,
    VehiculoId INT NOT NULL,
    FechaApertura DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FechaEstimadaEntrega DATETIME2 NULL,
    FechaFinalizacion DATETIME2 NULL,
    Prioridad NVARCHAR(20) NOT NULL DEFAULT N'MEDIA',
    Estado NVARCHAR(40) NOT NULL DEFAULT N'REGISTRADA',
    Observaciones NVARCHAR(1500) NULL,
    UsuarioCreadorId INT NULL,
    CONSTRAINT FK_OT_Cot FOREIGN KEY(CotizacionId) REFERENCES Cotizaciones(CotizacionId),
    CONSTRAINT FK_OT_Cliente FOREIGN KEY(ClienteId) REFERENCES Clientes(ClienteId),
    CONSTRAINT FK_OT_Vehiculo FOREIGN KEY(VehiculoId) REFERENCES Vehiculos(VehiculoId),
    CONSTRAINT FK_OT_Usuario FOREIGN KEY(UsuarioCreadorId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_OT_Prioridad CHECK(Prioridad IN(N'BAJA',N'MEDIA',N'ALTA')),
    CONSTRAINT CK_OT_Estado CHECK(Estado IN(N'REGISTRADA',N'PENDIENTE DE APROBACION',N'APROBADA',N'EN PROCESO',N'EN ESPERA DE REPUESTOS',N'SUSPENDIDA',N'FINALIZADA',N'FACTURADA',N'ENTREGADA',N'CANCELADA'))
);
GO
CREATE INDEX IX_OT_Estado_Fecha ON OrdenesTrabajo(Estado,FechaApertura);
CREATE INDEX IX_OT_Vehiculo ON OrdenesTrabajo(VehiculoId,FechaApertura DESC);
GO
CREATE TABLE OrdenHistorialEstados(
    HistorialEstadoId BIGINT IDENTITY PRIMARY KEY,
    OrdenTrabajoId INT NOT NULL,
    EstadoAnterior NVARCHAR(40) NULL,
    EstadoNuevo NVARCHAR(40) NOT NULL,
    UsuarioId INT NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Observacion NVARCHAR(500) NULL,
    CONSTRAINT FK_OHE_OT FOREIGN KEY(OrdenTrabajoId) REFERENCES OrdenesTrabajo(OrdenTrabajoId),
    CONSTRAINT FK_OHE_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId)
);
CREATE TABLE OrdenServicios(
    OrdenServicioId INT IDENTITY PRIMARY KEY,
    OrdenTrabajoId INT NOT NULL,
    ServicioId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL DEFAULT 1,
    PrecioAplicado DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL DEFAULT 0,
    DescuentoAplicado DECIMAL(18,2) NOT NULL DEFAULT 0,
    TiempoEstimadoMinutos INT NOT NULL DEFAULT 0,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'PENDIENTE',
    CONSTRAINT FK_OS_OT FOREIGN KEY(OrdenTrabajoId) REFERENCES OrdenesTrabajo(OrdenTrabajoId),
    CONSTRAINT FK_OS_Serv FOREIGN KEY(ServicioId) REFERENCES Servicios(ServicioId)
);
CREATE TABLE OrdenProductos(
    OrdenProductoId INT IDENTITY PRIMARY KEY,
    OrdenTrabajoId INT NOT NULL,
    ProductoId INT NOT NULL,
    CantidadAutorizada DECIMAL(18,2) NOT NULL,
    CantidadUtilizada DECIMAL(18,2) NOT NULL DEFAULT 0,
    CostoAplicado DECIMAL(18,2) NOT NULL,
    PrecioAplicado DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL DEFAULT 0,
    DescuentoAplicado DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT FK_OP_OT FOREIGN KEY(OrdenTrabajoId) REFERENCES OrdenesTrabajo(OrdenTrabajoId),
    CONSTRAINT FK_OP_Prod FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId),
    CONSTRAINT CK_OP_Cant CHECK(CantidadAutorizada>=0 AND CantidadUtilizada>=0 AND CantidadUtilizada<=CantidadAutorizada)
);
CREATE TABLE OrdenEmpleados(
    OrdenEmpleadoId INT IDENTITY PRIMARY KEY,
    OrdenTrabajoId INT NOT NULL,
    EmpleadoId INT NOT NULL,
    ActividadRealizada NVARCHAR(1000) NOT NULL,
    FechaInicio DATETIME2 NOT NULL,
    FechaFinalizacion DATETIME2 NULL,
    HorasTrabajadas DECIMAL(9,2) NOT NULL DEFAULT 0,
    CostoHora DECIMAL(18,2) NOT NULL DEFAULT 0,
    Observaciones NVARCHAR(1000) NULL,
    EstadoActividad NVARCHAR(30) NOT NULL DEFAULT N'ASIGNADA',
    CONSTRAINT FK_OE_OT FOREIGN KEY(OrdenTrabajoId) REFERENCES OrdenesTrabajo(OrdenTrabajoId),
    CONSTRAINT FK_OE_Emp FOREIGN KEY(EmpleadoId) REFERENCES Empleados(EmpleadoId),
    CONSTRAINT CK_OE_Horas CHECK(HorasTrabajadas>=0)
);
GO

/* ======================= INVENTARIO ========================== */
CREATE TABLE MovimientosInventario(
    MovimientoInventarioId BIGINT IDENTITY PRIMARY KEY,
    ProductoId INT NOT NULL,
    BodegaOrigenId INT NULL,
    BodegaDestinoId INT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    TipoMovimiento NVARCHAR(40) NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UsuarioId INT NOT NULL,
    DocumentoReferencia NVARCHAR(100) NULL,
    ExistenciaAnterior DECIMAL(18,2) NOT NULL,
    ExistenciaPosterior DECIMAL(18,2) NOT NULL,
    Observaciones NVARCHAR(1000) NULL,
    AutorizadoNegativo BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_MI_Producto FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId),
    CONSTRAINT FK_MI_BodOri FOREIGN KEY(BodegaOrigenId) REFERENCES Bodegas(BodegaId),
    CONSTRAINT FK_MI_BodDes FOREIGN KEY(BodegaDestinoId) REFERENCES Bodegas(BodegaId),
    CONSTRAINT FK_MI_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_MI_Cantidad CHECK(Cantidad>0),
    CONSTRAINT CK_MI_Tipo CHECK(TipoMovimiento IN(N'COMPRA',N'VENTA',N'USO ORDEN',N'DEVOLUCION CLIENTE',N'DEVOLUCION PROVEEDOR',N'AJUSTE POSITIVO',N'AJUSTE NEGATIVO',N'PRODUCTO DANADO',N'TRASLADO'))
);
GO
CREATE INDEX IX_MI_Producto_Fecha ON MovimientosInventario(ProductoId,FechaHora DESC);
GO

/* ========================== COMPRAS ========================== */
CREATE TABLE Compras(
    CompraId INT IDENTITY PRIMARY KEY,
    NumeroCompra AS (CONCAT('COM-',RIGHT('00000000'+CONVERT(VARCHAR(8),CompraId),8))) PERSISTED UNIQUE,
    ProveedorId INT NOT NULL,
    NumeroFacturaProveedor NVARCHAR(80) NOT NULL,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    Impuestos DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuentos DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total DECIMAL(18,2) NOT NULL DEFAULT 0,
    FormaPago NVARCHAR(50) NOT NULL,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'BORRADOR',
    SaldoPendiente DECIMAL(18,2) NOT NULL DEFAULT 0,
    UsuarioId INT NOT NULL,
    CONSTRAINT FK_Compra_Prov FOREIGN KEY(ProveedorId) REFERENCES Proveedores(ProveedorId),
    CONSTRAINT FK_Compra_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT UQ_Compra_FacturaProveedor UNIQUE(ProveedorId,NumeroFacturaProveedor),
    CONSTRAINT CK_Compra_Estado CHECK(Estado IN(N'BORRADOR',N'CONFIRMADA',N'PARCIALMENTE PAGADA',N'PAGADA',N'ANULADA'))
);
CREATE TABLE CompraDetalles(
    CompraDetalleId INT IDENTITY PRIMARY KEY,
    CompraId INT NOT NULL,
    ProductoId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    CostoUnitario DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL DEFAULT 0,
    Descuento DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalLinea DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_CD_Compra FOREIGN KEY(CompraId) REFERENCES Compras(CompraId),
    CONSTRAINT FK_CD_Prod FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId)
);
CREATE TABLE CompraPagos(
    CompraPagoId INT IDENTITY PRIMARY KEY,
    CompraId INT NOT NULL,
    Monto DECIMAL(18,2) NOT NULL,
    FormaPago NVARCHAR(50) NOT NULL,
    Referencia NVARCHAR(120) NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UsuarioId INT NOT NULL,
    CONSTRAINT FK_CPago_Compra FOREIGN KEY(CompraId) REFERENCES Compras(CompraId),
    CONSTRAINT FK_CPago_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId)
);
GO

/* =========================== VENTAS ========================== */
CREATE TABLE Ventas(
    VentaId INT IDENTITY PRIMARY KEY,
    NumeroVenta AS (CONCAT('VEN-',RIGHT('00000000'+CONVERT(VARCHAR(8),VentaId),8))) PERSISTED UNIQUE,
    ClienteId INT NULL,
    VendedorId INT NULL,
    CajeroId INT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    Impuestos DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuentos DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total DECIMAL(18,2) NOT NULL DEFAULT 0,
    FormaPago NVARCHAR(50) NOT NULL,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'BORRADOR',
    UsuarioId INT NOT NULL,
    CONSTRAINT FK_Venta_Cliente FOREIGN KEY(ClienteId) REFERENCES Clientes(ClienteId),
    CONSTRAINT FK_Venta_Vendedor FOREIGN KEY(VendedorId) REFERENCES Empleados(EmpleadoId),
    CONSTRAINT FK_Venta_Cajero FOREIGN KEY(CajeroId) REFERENCES Empleados(EmpleadoId),
    CONSTRAINT FK_Venta_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Venta_Estado CHECK(Estado IN(N'BORRADOR',N'CONFIRMADA',N'ANULADA',N'DEVUELTA PARCIAL',N'DEVUELTA'))
);
CREATE TABLE VentaDetalles(
    VentaDetalleId INT IDENTITY PRIMARY KEY,
    VentaId INT NOT NULL,
    ProductoId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    PrecioUnitario DECIMAL(18,2) NOT NULL,
    CostoUnitarioHistorico DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL DEFAULT 0,
    Descuento DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalLinea DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_VD_Venta FOREIGN KEY(VentaId) REFERENCES Ventas(VentaId),
    CONSTRAINT FK_VD_Prod FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId)
);
CREATE TABLE VentaDevoluciones(
    DevolucionId INT IDENTITY PRIMARY KEY,
    VentaId INT NOT NULL,
    VentaDetalleId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    Motivo NVARCHAR(500) NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UsuarioId INT NOT NULL,
    CONSTRAINT FK_Dev_Venta FOREIGN KEY(VentaId) REFERENCES Ventas(VentaId),
    CONSTRAINT FK_Dev_Det FOREIGN KEY(VentaDetalleId) REFERENCES VentaDetalles(VentaDetalleId),
    CONSTRAINT FK_Dev_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId)
);
GO

/* ========================= FACTURACION ======================= */
CREATE TABLE FormasPago(
    FormaPagoId INT IDENTITY PRIMARY KEY,
    Nombre NVARCHAR(50) NOT NULL UNIQUE,
    RequiereReferencia BIT NOT NULL DEFAULT 0,
    Activa BIT NOT NULL DEFAULT 1
);
GO
CREATE TABLE Facturas(
    FacturaId INT IDENTITY PRIMARY KEY,
    NumeroFactura AS (CONCAT('FAC-',RIGHT('00000000'+CONVERT(VARCHAR(8),FacturaId),8))) PERSISTED UNIQUE,
    ClienteId INT NULL,
    OrdenTrabajoId INT NULL,
    VentaId INT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Subtotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    Impuestos DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuentos DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total DECIMAL(18,2) NOT NULL DEFAULT 0,
    SaldoPendiente DECIMAL(18,2) NOT NULL DEFAULT 0,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'PENDIENTE',
    FormaPagoDescripcion NVARCHAR(120) NULL,
    UsuarioEmisorId INT NOT NULL,
    FechaAnulacion DATETIME2 NULL,
    UsuarioAnulacionId INT NULL,
    MotivoAnulacion NVARCHAR(500) NULL,
    CONSTRAINT FK_Fact_Cliente FOREIGN KEY(ClienteId) REFERENCES Clientes(ClienteId),
    CONSTRAINT FK_Fact_OT FOREIGN KEY(OrdenTrabajoId) REFERENCES OrdenesTrabajo(OrdenTrabajoId),
    CONSTRAINT FK_Fact_Venta FOREIGN KEY(VentaId) REFERENCES Ventas(VentaId),
    CONSTRAINT FK_Fact_Emisor FOREIGN KEY(UsuarioEmisorId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT FK_Fact_Anula FOREIGN KEY(UsuarioAnulacionId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Fact_Estado CHECK(Estado IN(N'PENDIENTE',N'PAGADA',N'PARCIALMENTE PAGADA',N'ANULADA',N'REEMBOLSADA'))
);
GO
CREATE UNIQUE INDEX UX_Factura_Venta ON Facturas(VentaId) WHERE VentaId IS NOT NULL;
CREATE UNIQUE INDEX UX_Factura_Orden ON Facturas(OrdenTrabajoId) WHERE OrdenTrabajoId IS NOT NULL;
CREATE INDEX IX_Factura_Estado_Fecha ON Facturas(Estado,FechaHora);
GO
CREATE TABLE FacturaDetalles(
    FacturaDetalleId INT IDENTITY PRIMARY KEY,
    FacturaId INT NOT NULL,
    TipoDetalle NVARCHAR(30) NOT NULL,
    ProductoId INT NULL,
    ServicioId INT NULL,
    Descripcion NVARCHAR(300) NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    PrecioUnitario DECIMAL(18,2) NOT NULL,
    CostoUnitarioHistorico DECIMAL(18,2) NULL,
    Impuesto DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuento DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalLinea DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_FD_Fact FOREIGN KEY(FacturaId) REFERENCES Facturas(FacturaId),
    CONSTRAINT FK_FD_Prod FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId),
    CONSTRAINT FK_FD_Serv FOREIGN KEY(ServicioId) REFERENCES Servicios(ServicioId),
    CONSTRAINT CK_FD_Tipo CHECK(TipoDetalle IN(N'PRODUCTO',N'SERVICIO',N'MANO DE OBRA',N'OTRO'))
);
CREATE TABLE Pagos(
    PagoId INT IDENTITY PRIMARY KEY,
    FacturaId INT NOT NULL,
    Monto DECIMAL(18,2) NOT NULL,
    FormaPagoId INT NOT NULL,
    NumeroReferencia NVARCHAR(120) NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UsuarioId INT NOT NULL,
    Observaciones NVARCHAR(500) NULL,
    Anulado BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Pago_Fact FOREIGN KEY(FacturaId) REFERENCES Facturas(FacturaId),
    CONSTRAINT FK_Pago_Forma FOREIGN KEY(FormaPagoId) REFERENCES FormasPago(FormaPagoId),
    CONSTRAINT FK_Pago_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Pago_Monto CHECK(Monto>0)
);
GO
CREATE INDEX IX_Pagos_Factura ON Pagos(FacturaId,FechaHora);
GO

/* ====================== ENTREGA VEHICULO ===================== */
CREATE TABLE EntregasVehiculo(
    EntregaId INT IDENTITY PRIMARY KEY,
    OrdenTrabajoId INT NOT NULL UNIQUE,
    KilometrajeSalida INT NOT NULL,
    FechaHoraEntrega DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    PersonaRecibe NVARCHAR(180) NOT NULL,
    ObservacionesFinales NVARCHAR(1200) NULL,
    RecomendacionesMantenimiento NVARCHAR(1200) NULL,
    ProximaFechaServicio DATE NULL,
    EstadoPago NVARCHAR(40) NOT NULL,
    AceptacionCliente NVARCHAR(500) NULL,
    UsuarioEntregaId INT NOT NULL,
    AutorizacionEspecial BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Entrega_OT FOREIGN KEY(OrdenTrabajoId) REFERENCES OrdenesTrabajo(OrdenTrabajoId),
    CONSTRAINT FK_Entrega_User FOREIGN KEY(UsuarioEntregaId) REFERENCES Usuarios(UsuarioId),
    CONSTRAINT CK_Entrega_Km CHECK(KilometrajeSalida>=0)
);
GO

/* ========================== GARANTIAS ======================== */
CREATE TABLE Garantias(
    GarantiaId INT IDENTITY PRIMARY KEY,
    OrdenTrabajoId INT NULL,
    VentaId INT NULL,
    ProductoId INT NULL,
    ServicioId INT NULL,
    TipoCobertura NVARCHAR(40) NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaVencimiento DATE NOT NULL,
    Condiciones NVARCHAR(1500) NULL,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'ACTIVA',
    Observaciones NVARCHAR(1000) NULL,
    CONSTRAINT FK_Gar_OT FOREIGN KEY(OrdenTrabajoId) REFERENCES OrdenesTrabajo(OrdenTrabajoId),
    CONSTRAINT FK_Gar_Venta FOREIGN KEY(VentaId) REFERENCES Ventas(VentaId),
    CONSTRAINT FK_Gar_Prod FOREIGN KEY(ProductoId) REFERENCES Productos(ProductoId),
    CONSTRAINT FK_Gar_Serv FOREIGN KEY(ServicioId) REFERENCES Servicios(ServicioId),
    CONSTRAINT CK_Gar_Fechas CHECK(FechaVencimiento>=FechaInicio),
    CONSTRAINT CK_Gar_Estado CHECK(Estado IN(N'ACTIVA',N'INACTIVA',N'VENCIDA',N'ANULADA',N'EN RECLAMO')),
    CONSTRAINT CK_Gar_TipoCobertura CHECK(TipoCobertura IN(N'PRODUCTO',N'SERVICIO Y REPUESTO'))
);
CREATE TABLE GarantiaReclamos(
    ReclamoId INT IDENTITY PRIMARY KEY,
    GarantiaId INT NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Descripcion NVARCHAR(1500) NOT NULL,
    Estado NVARCHAR(30) NOT NULL DEFAULT N'ABIERTO',
    Resolucion NVARCHAR(1500) NULL,
    FechaResolucion DATETIME2 NULL,
    UsuarioId INT NOT NULL,
    CONSTRAINT FK_GR_Garantia FOREIGN KEY(GarantiaId) REFERENCES Garantias(GarantiaId),
    CONSTRAINT FK_GR_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId)
);
GO

/* ======================= NOTIFICACIONES ====================== */
CREATE TABLE Notificaciones(
    NotificacionId BIGINT IDENTITY PRIMARY KEY,
    UsuarioId INT NULL,
    Tipo NVARCHAR(60) NOT NULL,
    Titulo NVARCHAR(180) NOT NULL,
    Mensaje NVARCHAR(1000) NOT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Leida BIT NOT NULL DEFAULT 0,
    ModuloReferencia NVARCHAR(80) NULL,
    RegistroReferenciaId INT NULL,
    Prioridad NVARCHAR(20) NOT NULL DEFAULT N'NORMAL',
    CONSTRAINT FK_Notif_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId)
);
GO
CREATE INDEX IX_Notificaciones_User ON Notificaciones(UsuarioId,Leida,FechaHora DESC);
GO

/* ===================== CONFIGURACION GENERAL ================= */
CREATE TABLE ConfiguracionGeneral(
    ConfiguracionId INT IDENTITY PRIMARY KEY,
    NombreTaller NVARCHAR(180) NOT NULL,
    IdentificacionJuridica NVARCHAR(40) NOT NULL,
    Direccion NVARCHAR(500) NOT NULL,
    Telefono NVARCHAR(30) NULL,
    Correo NVARCHAR(160) NULL,
    LogotipoUrl NVARCHAR(500) NULL,
    PorcentajeImpuestoGeneral DECIMAL(9,4) NOT NULL DEFAULT 13,
    Moneda NVARCHAR(10) NOT NULL DEFAULT N'CRC',
    FormatoRecepcion NVARCHAR(30) NOT NULL DEFAULT N'REC-{00000000}',
    FormatoCotizacion NVARCHAR(30) NOT NULL DEFAULT N'COT-{00000000}',
    FormatoOrden NVARCHAR(30) NOT NULL DEFAULT N'OT-{00000000}',
    FormatoVenta NVARCHAR(30) NOT NULL DEFAULT N'VEN-{00000000}',
    FormatoFactura NVARCHAR(30) NOT NULL DEFAULT N'FAC-{00000000}',
    LimiteDescuento DECIMAL(9,4) NOT NULL DEFAULT 10,
    HorarioAtencion NVARCHAR(300) NULL,
    PlazoGarantiaDias INT NOT NULL DEFAULT 30,
    ExistenciaMinimaPredeterminada DECIMAL(18,2) NOT NULL DEFAULT 5,
    ActualizadoEn DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Config_Imp CHECK(PorcentajeImpuestoGeneral BETWEEN 0 AND 100),
    CONSTRAINT CK_Config_Desc CHECK(LimiteDescuento BETWEEN 0 AND 100)
);
GO
CREATE TABLE EstadosConfigurables(
    EstadoConfigurableId INT IDENTITY PRIMARY KEY,
    Proceso NVARCHAR(80) NOT NULL,
    Codigo NVARCHAR(50) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    OrdenVisual INT NOT NULL DEFAULT 0,
    Activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT UQ_Estados_Proceso UNIQUE(Proceso,Codigo)
);
GO

/* ========================== AUDITORIA ======================== */
CREATE TABLE Auditoria(
    AuditoriaId BIGINT IDENTITY PRIMARY KEY,
    UsuarioId INT NULL,
    FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    DireccionIP NVARCHAR(64) NULL,
    Modulo NVARCHAR(80) NOT NULL,
    Accion NVARCHAR(120) NOT NULL,
    TipoOperacion NVARCHAR(30) NOT NULL,
    RegistroId NVARCHAR(80) NULL,
    ValoresAnteriores NVARCHAR(MAX) NULL,
    ValoresNuevos NVARCHAR(MAX) NULL,
    Descripcion NVARCHAR(1000) NULL,
    CONSTRAINT FK_Auditoria_User FOREIGN KEY(UsuarioId) REFERENCES Usuarios(UsuarioId)
);
GO
CREATE INDEX IX_Auditoria_Fecha ON Auditoria(FechaHora DESC);
CREATE INDEX IX_Auditoria_Modulo ON Auditoria(Modulo,FechaHora DESC);
GO

/* ==================== TIPOS PARA TRANSACCIONES =============== */
CREATE TYPE dbo.CompraDetalleType AS TABLE(
    ProductoId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    CostoUnitario DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL,
    Descuento DECIMAL(18,2) NOT NULL
);
GO
CREATE TYPE dbo.VentaDetalleType AS TABLE(
    ProductoId INT NOT NULL,
    Cantidad DECIMAL(18,2) NOT NULL,
    PrecioUnitario DECIMAL(18,2) NOT NULL,
    ImpuestoPorcentaje DECIMAL(9,4) NOT NULL,
    Descuento DECIMAL(18,2) NOT NULL
);
GO

/* ================= PROCEDIMIENTO: COMPRA ===================== */
CREATE OR ALTER PROCEDURE dbo.sp_ConfirmarCompra
 @ProveedorId INT,@NumeroFacturaProveedor NVARCHAR(80),@FormaPago NVARCHAR(50),@UsuarioId INT,@Detalles dbo.CompraDetalleType READONLY
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM @Detalles) THROW 50001,'La compra no contiene productos.',1;
 BEGIN TRAN;
 BEGIN TRY
   DECLARE @CompraId INT,@Subtotal DECIMAL(18,2),@Imp DECIMAL(18,2),@Desc DECIMAL(18,2),@Total DECIMAL(18,2);
   SELECT @Subtotal=SUM(Cantidad*CostoUnitario),@Imp=SUM((Cantidad*CostoUnitario-Descuento)*(ImpuestoPorcentaje/100.0)),@Desc=SUM(Descuento) FROM @Detalles;
   SET @Total=ISNULL(@Subtotal,0)-ISNULL(@Desc,0)+ISNULL(@Imp,0);
   INSERT Compras(ProveedorId,NumeroFacturaProveedor,Subtotal,Impuestos,Descuentos,Total,FormaPago,Estado,SaldoPendiente,UsuarioId)
   VALUES(@ProveedorId,@NumeroFacturaProveedor,@Subtotal,@Imp,@Desc,@Total,@FormaPago,N'CONFIRMADA',CASE WHEN @FormaPago=N'CONTADO' THEN 0 ELSE @Total END,@UsuarioId);
   SET @CompraId=SCOPE_IDENTITY();
   INSERT CompraDetalles(CompraId,ProductoId,Cantidad,CostoUnitario,ImpuestoPorcentaje,Descuento,TotalLinea)
   SELECT @CompraId,ProductoId,Cantidad,CostoUnitario,ImpuestoPorcentaje,Descuento,(Cantidad*CostoUnitario-Descuento)*(1+ImpuestoPorcentaje/100.0) FROM @Detalles;
   DECLARE @Pid INT,@Cant DECIMAL(18,2),@Costo DECIMAL(18,2),@Antes DECIMAL(18,2);
   DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT ProductoId,Cantidad,CostoUnitario FROM @Detalles;
   OPEN c; FETCH NEXT FROM c INTO @Pid,@Cant,@Costo;
   WHILE @@FETCH_STATUS=0 BEGIN
      SELECT @Antes=ExistenciaActual FROM Productos WITH(UPDLOCK,HOLDLOCK) WHERE ProductoId=@Pid;
      IF @Antes IS NULL THROW 50002,'Producto de compra no existe.',1;
      UPDATE Productos SET ExistenciaActual=ExistenciaActual+@Cant,PrecioCompra=@Costo WHERE ProductoId=@Pid;
      INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior)
      VALUES(@Pid,@Cant,N'COMPRA',@UsuarioId,CONCAT(N'COM-',@CompraId),@Antes,@Antes+@Cant);
      FETCH NEXT FROM c INTO @Pid,@Cant,@Costo;
   END
   CLOSE c; DEALLOCATE c;
   COMMIT;
   SELECT @CompraId CompraId,@Total Total;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ================= PROCEDIMIENTO: VENTA ====================== */
CREATE OR ALTER PROCEDURE dbo.sp_ConfirmarVenta
 @ClienteId INT=NULL,@VendedorId INT=NULL,@CajeroId INT=NULL,@FormaPago NVARCHAR(50),@UsuarioId INT,@PermitirNegativo BIT=0,@Detalles dbo.VentaDetalleType READONLY
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM @Detalles) THROW 50010,'La venta no contiene productos.',1;
 BEGIN TRAN;
 BEGIN TRY
   DECLARE @VentaId INT,@FacturaId INT,@Subtotal DECIMAL(18,2),@Imp DECIMAL(18,2),@Desc DECIMAL(18,2),@Total DECIMAL(18,2);
   IF @PermitirNegativo=0 AND EXISTS(SELECT 1 FROM @Detalles d JOIN Productos p ON p.ProductoId=d.ProductoId WHERE d.Cantidad>p.ExistenciaActual) THROW 50011,'Existencia insuficiente para uno o más productos.',1;
   SELECT @Subtotal=SUM(Cantidad*PrecioUnitario),@Imp=SUM((Cantidad*PrecioUnitario-Descuento)*(ImpuestoPorcentaje/100.0)),@Desc=SUM(Descuento) FROM @Detalles;
   SET @Total=ISNULL(@Subtotal,0)-ISNULL(@Desc,0)+ISNULL(@Imp,0);
   INSERT Ventas(ClienteId,VendedorId,CajeroId,Subtotal,Impuestos,Descuentos,Total,FormaPago,Estado,UsuarioId) VALUES(@ClienteId,@VendedorId,@CajeroId,@Subtotal,@Imp,@Desc,@Total,@FormaPago,N'CONFIRMADA',@UsuarioId);
   SET @VentaId=SCOPE_IDENTITY();
   INSERT VentaDetalles(VentaId,ProductoId,Cantidad,PrecioUnitario,CostoUnitarioHistorico,ImpuestoPorcentaje,Descuento,TotalLinea)
   SELECT @VentaId,d.ProductoId,d.Cantidad,d.PrecioUnitario,p.PrecioCompra,d.ImpuestoPorcentaje,d.Descuento,(d.Cantidad*d.PrecioUnitario-d.Descuento)*(1+d.ImpuestoPorcentaje/100.0) FROM @Detalles d JOIN Productos p ON p.ProductoId=d.ProductoId;
   DECLARE @Pid INT,@Cant DECIMAL(18,2),@Antes DECIMAL(18,2);
   DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT ProductoId,Cantidad FROM @Detalles;
   OPEN c; FETCH NEXT FROM c INTO @Pid,@Cant;
   WHILE @@FETCH_STATUS=0 BEGIN
      SELECT @Antes=ExistenciaActual FROM Productos WITH(UPDLOCK,HOLDLOCK) WHERE ProductoId=@Pid;
      IF @PermitirNegativo=0 AND @Antes<@Cant THROW 50012,'Existencia cambió durante la venta; operación cancelada.',1;
      UPDATE Productos SET ExistenciaActual=ExistenciaActual-@Cant WHERE ProductoId=@Pid;
      INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior,AutorizadoNegativo) VALUES(@Pid,@Cant,N'VENTA',@UsuarioId,CONCAT(N'VEN-',@VentaId),@Antes,@Antes-@Cant,@PermitirNegativo);
      FETCH NEXT FROM c INTO @Pid,@Cant;
   END
   CLOSE c; DEALLOCATE c;
   INSERT Facturas(ClienteId,VentaId,Subtotal,Impuestos,Descuentos,Total,SaldoPendiente,Estado,FormaPagoDescripcion,UsuarioEmisorId) VALUES(@ClienteId,@VentaId,@Subtotal,@Imp,@Desc,@Total,@Total,N'PENDIENTE',@FormaPago,@UsuarioId);
   SET @FacturaId=SCOPE_IDENTITY();
   INSERT FacturaDetalles(FacturaId,TipoDetalle,ProductoId,Descripcion,Cantidad,PrecioUnitario,CostoUnitarioHistorico,Impuesto,Descuento,TotalLinea)
   SELECT @FacturaId,N'PRODUCTO',d.ProductoId,p.Nombre,d.Cantidad,d.PrecioUnitario,p.PrecioCompra,(d.Cantidad*d.PrecioUnitario-d.Descuento)*(d.ImpuestoPorcentaje/100.0),d.Descuento,(d.Cantidad*d.PrecioUnitario-d.Descuento)*(1+d.ImpuestoPorcentaje/100.0) FROM @Detalles d JOIN Productos p ON p.ProductoId=d.ProductoId;
   COMMIT;
   SELECT @VentaId VentaId,@FacturaId FacturaId,@Total Total;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ================= PROCEDIMIENTO: PAGOS ====================== */
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarPago
 @FacturaId INT,@Monto DECIMAL(18,2),@FormaPagoId INT,@Referencia NVARCHAR(120)=NULL,@UsuarioId INT,@Observaciones NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRAN;
 BEGIN TRY
   DECLARE @Saldo DECIMAL(18,2),@Estado NVARCHAR(30),@PagoId INT;
   SELECT @Saldo=SaldoPendiente,@Estado=Estado FROM Facturas WITH(UPDLOCK,HOLDLOCK) WHERE FacturaId=@FacturaId;
   IF @Saldo IS NULL THROW 50020,'Factura no existe.',1;
   IF @Estado IN(N'ANULADA',N'REEMBOLSADA') THROW 50021,'No se puede pagar una factura anulada o reembolsada.',1;
   IF @Monto<=0 OR @Monto>@Saldo THROW 50022,'Monto de pago inválido.',1;
   INSERT Pagos(FacturaId,Monto,FormaPagoId,NumeroReferencia,UsuarioId,Observaciones) VALUES(@FacturaId,@Monto,@FormaPagoId,@Referencia,@UsuarioId,@Observaciones);
   SET @PagoId=SCOPE_IDENTITY(); SET @Saldo=@Saldo-@Monto;
   UPDATE Facturas SET SaldoPendiente=@Saldo,Estado=CASE WHEN @Saldo=0 THEN N'PAGADA' ELSE N'PARCIALMENTE PAGADA' END WHERE FacturaId=@FacturaId;
   COMMIT; SELECT @PagoId PagoId,@Saldo SaldoPendiente;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ============= PROCEDIMIENTO: CAMBIO ESTADO ORDEN =========== */
CREATE OR ALTER PROCEDURE dbo.sp_CambiarEstadoOrden
 @OrdenTrabajoId INT,@EstadoNuevo NVARCHAR(40),@UsuarioId INT,@Observacion NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRAN;
 BEGIN TRY
   DECLARE @Anterior NVARCHAR(40),@FacturaEstado NVARCHAR(40);
   IF @EstadoNuevo NOT IN(N'REGISTRADA',N'PENDIENTE DE APROBACION',N'APROBADA',N'EN PROCESO',N'EN ESPERA DE REPUESTOS',N'SUSPENDIDA',N'FINALIZADA',N'FACTURADA',N'ENTREGADA',N'CANCELADA') THROW 50029,'Estado de orden inválido.',1;
   SELECT @Anterior=Estado FROM OrdenesTrabajo WITH(UPDLOCK,HOLDLOCK) WHERE OrdenTrabajoId=@OrdenTrabajoId;
   IF @Anterior IS NULL THROW 50030,'Orden no existe.',1;
   IF @Anterior=N'FINALIZADA' AND @EstadoNuevo NOT IN(N'FINALIZADA',N'FACTURADA',N'CANCELADA') THROW 50031,'Una orden finalizada requiere el proceso de facturación o cancelación controlada.',1;
   IF @EstadoNuevo=N'FACTURADA' BEGIN
      SELECT TOP 1 @FacturaEstado=Estado FROM Facturas WHERE OrdenTrabajoId=@OrdenTrabajoId AND Estado<>N'ANULADA' ORDER BY FacturaId DESC;
      IF @FacturaEstado IS NULL THROW 50032,'No se puede marcar Facturada: no existe una factura asociada.',1;
   END
   IF @EstadoNuevo=N'ENTREGADA' BEGIN
      SET @FacturaEstado=NULL;
      SELECT TOP 1 @FacturaEstado=Estado FROM Facturas WHERE OrdenTrabajoId=@OrdenTrabajoId AND Estado<>N'ANULADA' ORDER BY FacturaId DESC;
      IF @FacturaEstado<>N'PAGADA' OR @FacturaEstado IS NULL THROW 50033,'No se puede marcar Entregada: la factura debe estar pagada.',1;
   END
   UPDATE OrdenesTrabajo SET Estado=@EstadoNuevo,FechaFinalizacion=CASE WHEN @EstadoNuevo=N'FINALIZADA' AND FechaFinalizacion IS NULL THEN SYSDATETIME() ELSE FechaFinalizacion END WHERE OrdenTrabajoId=@OrdenTrabajoId;
   IF @Anterior<>@EstadoNuevo INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,Observacion) VALUES(@OrdenTrabajoId,@Anterior,@EstadoNuevo,@UsuarioId,@Observacion);
   COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ======= PROCEDIMIENTO: APROBAR COTIZACION Y CREAR ORDEN ===== */
CREATE OR ALTER PROCEDURE dbo.sp_AprobarCotizacionYCrearOrden
 @CotizacionId INT,@UsuarioId INT,@TipoAprobacion NVARCHAR(20),@ServiciosJson NVARCHAR(MAX)=N'[]',@ProductosJson NVARCHAR(MAX)=N'[]'
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRAN;
 BEGIN TRY
   DECLARE @Diag INT,@Recep INT,@Cliente INT,@Vehiculo INT,@OrdenId INT,@Min INT,@Estado NVARCHAR(30);
   SELECT @Diag=DiagnosticoId,@Estado=Estado FROM Cotizaciones WITH(UPDLOCK,HOLDLOCK) WHERE CotizacionId=@CotizacionId;
   IF @Diag IS NULL THROW 50040,'Cotización no existe.',1;
   IF @Estado<>N'CONVERTIDA' THROW 50042,'La cotización debe estar en estado CONVERTIDA antes de crear una orden de trabajo.',1;
   SELECT @Recep=RecepcionId FROM Diagnosticos WHERE DiagnosticoId=@Diag;
   SELECT @Cliente=ClienteId,@Vehiculo=VehiculoId FROM Recepciones WHERE RecepcionId=@Recep;
   IF EXISTS(SELECT 1 FROM OrdenesTrabajo WHERE CotizacionId=@CotizacionId) THROW 50041,'La cotización ya fue convertida.',1;
   IF @TipoAprobacion=N'TOTAL' BEGIN UPDATE CotizacionServicios SET Aprobado=1 WHERE CotizacionId=@CotizacionId; UPDATE CotizacionProductos SET Aprobado=1 WHERE CotizacionId=@CotizacionId; END
   ELSE BEGIN
      UPDATE CotizacionServicios SET Aprobado=CASE WHEN CotizacionServicioId IN(SELECT TRY_CAST([value] AS INT) FROM OPENJSON(@ServiciosJson)) THEN 1 ELSE 0 END WHERE CotizacionId=@CotizacionId;
      UPDATE CotizacionProductos SET Aprobado=CASE WHEN CotizacionProductoId IN(SELECT TRY_CAST([value] AS INT) FROM OPENJSON(@ProductosJson)) THEN 1 ELSE 0 END WHERE CotizacionId=@CotizacionId;
   END
   SELECT @Min=ISNULL(SUM(TiempoEstimadoMinutos),0) FROM CotizacionServicios WHERE CotizacionId=@CotizacionId AND Aprobado=1;
   INSERT OrdenesTrabajo(CotizacionId,ClienteId,VehiculoId,FechaEstimadaEntrega,Prioridad,Estado,UsuarioCreadorId) VALUES(@CotizacionId,@Cliente,@Vehiculo,DATEADD(MINUTE,@Min,SYSDATETIME()),N'MEDIA',N'APROBADA',@UsuarioId);
   SET @OrdenId=SCOPE_IDENTITY();
   INSERT OrdenServicios(OrdenTrabajoId,ServicioId,Cantidad,PrecioAplicado,ImpuestoPorcentaje,DescuentoAplicado,TiempoEstimadoMinutos) SELECT @OrdenId,ServicioId,Cantidad,PrecioUnitario,ImpuestoPorcentaje,Descuento,TiempoEstimadoMinutos FROM CotizacionServicios WHERE CotizacionId=@CotizacionId AND Aprobado=1;
   INSERT OrdenProductos(OrdenTrabajoId,ProductoId,CantidadAutorizada,CostoAplicado,PrecioAplicado,ImpuestoPorcentaje,DescuentoAplicado) SELECT @OrdenId,cp.ProductoId,cp.Cantidad,p.PrecioCompra,cp.PrecioUnitario,cp.ImpuestoPorcentaje,cp.Descuento FROM CotizacionProductos cp JOIN Productos p ON p.ProductoId=cp.ProductoId WHERE cp.CotizacionId=@CotizacionId AND cp.Aprobado=1;
   UPDATE Cotizaciones SET Estado=N'CONVERTIDA',AprobacionTipo=@TipoAprobacion,UsuarioDecisionId=@UsuarioId,FechaHoraDecision=SYSDATETIME(),UsuarioConversionId=@UsuarioId,FechaHoraConversion=SYSDATETIME() WHERE CotizacionId=@CotizacionId;
   INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,Observacion) VALUES(@OrdenId,NULL,N'APROBADA',@UsuarioId,N'Orden creada automáticamente desde cotización aprobada.');
   UPDATE Recepciones SET FechaEstimadaEntrega=DATEADD(MINUTE,@Min,SYSDATETIME()) WHERE RecepcionId=@Recep;
   COMMIT; SELECT @OrdenId OrdenTrabajoId;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ============== PROCEDIMIENTO: USO REPUESTO EN ORDEN ========= */
CREATE OR ALTER PROCEDURE dbo.sp_ConsumirRepuestoOrden @OrdenProductoId INT,@Cantidad DECIMAL(18,2),@UsuarioId INT,@PermitirNegativo BIT=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 BEGIN TRAN;
 BEGIN TRY
   DECLARE @Prod INT,@Orden INT,@Aut DECIMAL(18,2),@Usada DECIMAL(18,2),@Stock DECIMAL(18,2);
   SELECT @Prod=ProductoId,@Orden=OrdenTrabajoId,@Aut=CantidadAutorizada,@Usada=CantidadUtilizada FROM OrdenProductos WITH(UPDLOCK,HOLDLOCK) WHERE OrdenProductoId=@OrdenProductoId;
   IF @Prod IS NULL THROW 50050,'Repuesto de orden no existe.',1;
   IF @Usada+@Cantidad>@Aut THROW 50051,'La cantidad supera lo autorizado en la orden.',1;
   SELECT @Stock=ExistenciaActual FROM Productos WITH(UPDLOCK,HOLDLOCK) WHERE ProductoId=@Prod;
   IF @PermitirNegativo=0 AND @Cantidad>@Stock THROW 50052,'Existencia insuficiente.',1;
   UPDATE Productos SET ExistenciaActual=ExistenciaActual-@Cantidad WHERE ProductoId=@Prod;
   UPDATE OrdenProductos SET CantidadUtilizada=CantidadUtilizada+@Cantidad WHERE OrdenProductoId=@OrdenProductoId;
   INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior,AutorizadoNegativo) VALUES(@Prod,@Cantidad,N'USO ORDEN',@UsuarioId,CONCAT(N'OT-',@Orden),@Stock,@Stock-@Cantidad,@PermitirNegativo);
   COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ============== FUNCIONES / VISTAS PARA REPORTES ============ */
CREATE OR ALTER FUNCTION dbo.fn_SaldoFactura(@FacturaId INT)
RETURNS DECIMAL(18,2)
AS BEGIN DECLARE @s DECIMAL(18,2); SELECT @s=SaldoPendiente FROM Facturas WHERE FacturaId=@FacturaId; RETURN ISNULL(@s,0); END
GO
CREATE OR ALTER VIEW dbo.vw_HistorialVehiculo AS
SELECT v.VehiculoId,v.Placa,v.VIN,c.NombreRazonSocial Cliente,o.OrdenTrabajoId,o.NumeroOrden,o.FechaApertura,o.Estado,s.ServicioId,s.Nombre Servicio,os.PrecioAplicado
FROM Vehiculos v JOIN Clientes c ON c.ClienteId=v.ClienteId LEFT JOIN OrdenesTrabajo o ON o.VehiculoId=v.VehiculoId LEFT JOIN OrdenServicios os ON os.OrdenTrabajoId=o.OrdenTrabajoId LEFT JOIN Servicios s ON s.ServicioId=os.ServicioId;
GO
CREATE OR ALTER VIEW dbo.vw_ProductosStockMinimo AS SELECT ProductoId,CodigoInterno,Nombre,ExistenciaActual,ExistenciaMinima,Ubicacion FROM Productos WHERE Activo=1 AND ExistenciaActual<=ExistenciaMinima;
GO
CREATE OR ALTER VIEW dbo.vw_FacturasPendientes AS SELECT f.FacturaId,f.NumeroFactura,f.FechaHora,f.ClienteId,c.NombreRazonSocial Cliente,f.Total,f.SaldoPendiente,f.Estado FROM Facturas f LEFT JOIN Clientes c ON c.ClienteId=f.ClienteId WHERE f.SaldoPendiente>0 AND f.Estado NOT IN(N'ANULADA',N'REEMBOLSADA');
GO
CREATE OR ALTER VIEW dbo.vw_UtilidadProductos AS SELECT vd.ProductoId,p.Nombre,SUM(vd.Cantidad) Unidades,SUM(vd.TotalLinea) Ingreso,SUM(vd.Cantidad*vd.CostoUnitarioHistorico) Costo,SUM(vd.TotalLinea-vd.Cantidad*vd.CostoUnitarioHistorico) UtilidadEstimada FROM VentaDetalles vd JOIN Ventas v ON v.VentaId=vd.VentaId JOIN Productos p ON p.ProductoId=vd.ProductoId WHERE v.Estado=N'CONFIRMADA' GROUP BY vd.ProductoId,p.Nombre;
GO
CREATE OR ALTER VIEW dbo.vw_UtilidadOrdenTrabajo AS SELECT o.OrdenTrabajoId,o.NumeroOrden,ISNULL((SELECT SUM(os.PrecioAplicado*os.Cantidad-os.DescuentoAplicado) FROM OrdenServicios os WHERE os.OrdenTrabajoId=o.OrdenTrabajoId),0)+ISNULL((SELECT SUM(op.PrecioAplicado*op.CantidadUtilizada-op.DescuentoAplicado) FROM OrdenProductos op WHERE op.OrdenTrabajoId=o.OrdenTrabajoId),0) IngresoEstimado,ISNULL((SELECT SUM(op.CostoAplicado*op.CantidadUtilizada) FROM OrdenProductos op WHERE op.OrdenTrabajoId=o.OrdenTrabajoId),0)+ISNULL((SELECT SUM(oe.CostoHora*oe.HorasTrabajadas) FROM OrdenEmpleados oe WHERE oe.OrdenTrabajoId=o.OrdenTrabajoId),0) CostoEstimado FROM OrdenesTrabajo o;
GO

/* ============ RESTRICCION: CITAS SUPERPUESTAS =============== */
CREATE OR ALTER TRIGGER dbo.trg_Citas_NoSolapar ON dbo.Citas AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
   SELECT 1 FROM inserted i JOIN Citas c ON c.CitaId<>i.CitaId AND c.Estado NOT IN(N'CANCELADA',N'CLIENTE AUSENTE') AND i.Estado NOT IN(N'CANCELADA',N'CLIENTE AUSENTE')
   WHERE ((i.EmpleadoId IS NOT NULL AND c.EmpleadoId=i.EmpleadoId) OR (i.AreaTrabajo IS NOT NULL AND c.AreaTrabajo=i.AreaTrabajo))
   AND i.FechaHoraInicio<DATEADD(MINUTE,c.DuracionEstimadaMinutos,c.FechaHoraInicio)
   AND c.FechaHoraInicio<DATEADD(MINUTE,i.DuracionEstimadaMinutos,i.FechaHoraInicio)
 ) BEGIN ROLLBACK TRANSACTION; THROW 50060,'El mecánico o área ya posee una cita incompatible en ese horario.',1; END
END
GO

/* ========= RESTRICCION: HORAS EMPLEADO VS ORDEN ============= */
CREATE OR ALTER TRIGGER dbo.trg_OrdenEmpleados_Horas ON dbo.OrdenEmpleados AFTER INSERT,UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted i JOIN OrdenesTrabajo o ON o.OrdenTrabajoId=i.OrdenTrabajoId WHERE i.FechaFinalizacion IS NOT NULL AND (i.FechaFinalizacion<i.FechaInicio OR i.HorasTrabajadas>DATEDIFF(MINUTE,i.FechaInicio,i.FechaFinalizacion)/60.0+0.02 OR (o.FechaFinalizacion IS NOT NULL AND i.HorasTrabajadas>DATEDIFF(MINUTE,o.FechaApertura,o.FechaFinalizacion)/60.0+0.02)))
 BEGIN ROLLBACK TRANSACTION; THROW 50061,'Las horas trabajadas no pueden superar la duración real de la actividad.',1; END
END
GO


/* ========== GENERAR COTIZACION DESDE DIAGNOSTICO ============ */
CREATE OR ALTER PROCEDURE dbo.sp_GenerarCotizacionDesdeDiagnostico @DiagnosticoId INT,@UsuarioId INT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRAN;
 BEGIN TRY
  DECLARE @Cot INT,@Sub DECIMAL(18,2),@Imp DECIMAL(18,2),@MO DECIMAL(18,2),@Min INT;
  IF EXISTS(SELECT 1 FROM Cotizaciones WHERE DiagnosticoId=@DiagnosticoId) THROW 50070,'Ya existe una cotización para este diagnóstico.',1;
  IF NOT EXISTS(SELECT 1 FROM Diagnosticos WHERE DiagnosticoId=@DiagnosticoId AND Estado=N'FINALIZADO') THROW 50071,'El diagnóstico debe estar finalizado.',1;
  SELECT @MO=ManoObraEstimada,@Min=TiempoEstimadoMinutos FROM Diagnosticos WHERE DiagnosticoId=@DiagnosticoId;
  INSERT Cotizaciones(DiagnosticoId,FechaVencimiento,HorasManoObra,PrecioHoraManoObra,Estado) VALUES(@DiagnosticoId,DATEADD(DAY,15,CAST(GETDATE() AS DATE)),ISNULL(@Min,0)/60.0,CASE WHEN ISNULL(@Min,0)>0 THEN ISNULL(@MO,0)/(ISNULL(@Min,0)/60.0) ELSE 0 END,N'BORRADOR');
  SET @Cot=SCOPE_IDENTITY();
  INSERT CotizacionServicios(CotizacionId,ServicioId,Cantidad,PrecioUnitario,ImpuestoPorcentaje,TiempoEstimadoMinutos)
    SELECT @Cot,ds.ServicioId,ds.Cantidad,ds.PrecioEstimado,s.PorcentajeImpuesto,ds.TiempoEstimadoMinutos FROM DiagnosticoServicios ds JOIN Servicios s ON s.ServicioId=ds.ServicioId WHERE ds.DiagnosticoId=@DiagnosticoId AND ds.Recomendado=1;
  INSERT CotizacionProductos(CotizacionId,ProductoId,Cantidad,PrecioUnitario,ImpuestoPorcentaje)
    SELECT @Cot,dp.ProductoId,dp.Cantidad,dp.PrecioUnitarioEstimado,p.PorcentajeImpuesto FROM DiagnosticoProductos dp JOIN Productos p ON p.ProductoId=dp.ProductoId WHERE dp.DiagnosticoId=@DiagnosticoId;
  SELECT @Sub=ISNULL((SELECT SUM(Cantidad*PrecioUnitario-Descuento) FROM CotizacionServicios WHERE CotizacionId=@Cot),0)+ISNULL((SELECT SUM(Cantidad*PrecioUnitario-Descuento) FROM CotizacionProductos WHERE CotizacionId=@Cot),0)+ISNULL(@MO,0);
  SELECT @Imp=ISNULL((SELECT SUM((Cantidad*PrecioUnitario-Descuento)*ImpuestoPorcentaje/100.0) FROM CotizacionServicios WHERE CotizacionId=@Cot),0)+ISNULL((SELECT SUM((Cantidad*PrecioUnitario-Descuento)*ImpuestoPorcentaje/100.0) FROM CotizacionProductos WHERE CotizacionId=@Cot),0);
  UPDATE Cotizaciones SET Subtotal=@Sub,Impuestos=@Imp,TotalEstimado=@Sub+@Imp WHERE CotizacionId=@Cot;
  COMMIT; SELECT @Cot CotizacionId,@Sub+@Imp TotalEstimado;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ================= FACTURAR ORDEN FINALIZADA ================= */
CREATE OR ALTER PROCEDURE dbo.sp_FacturarOrden @OrdenTrabajoId INT,@UsuarioId INT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRAN;
 BEGIN TRY
  DECLARE @Cliente INT,@Estado NVARCHAR(40),@Fact INT,@Sub DECIMAL(18,2)=0,@Imp DECIMAL(18,2)=0,@Desc DECIMAL(18,2)=0,@Total DECIMAL(18,2);
  SELECT @Cliente=ClienteId,@Estado=Estado FROM OrdenesTrabajo WITH(UPDLOCK,HOLDLOCK) WHERE OrdenTrabajoId=@OrdenTrabajoId;
  IF @Cliente IS NULL THROW 50080,'Orden no existe.',1;
  IF @Estado<>N'FINALIZADA' THROW 50081,'Solo se pueden facturar órdenes finalizadas.',1;
  IF EXISTS(SELECT 1 FROM Facturas WHERE OrdenTrabajoId=@OrdenTrabajoId) THROW 50082,'La orden ya fue facturada.',1;
  SELECT @Sub=@Sub+ISNULL(SUM(Cantidad*PrecioAplicado-DescuentoAplicado),0),@Imp=@Imp+ISNULL(SUM((Cantidad*PrecioAplicado-DescuentoAplicado)*ImpuestoPorcentaje/100.0),0),@Desc=@Desc+ISNULL(SUM(DescuentoAplicado),0) FROM OrdenServicios WHERE OrdenTrabajoId=@OrdenTrabajoId;
  SELECT @Sub=@Sub+ISNULL(SUM(CantidadUtilizada*PrecioAplicado-DescuentoAplicado),0),@Imp=@Imp+ISNULL(SUM((CantidadUtilizada*PrecioAplicado-DescuentoAplicado)*ImpuestoPorcentaje/100.0),0),@Desc=@Desc+ISNULL(SUM(DescuentoAplicado),0) FROM OrdenProductos WHERE OrdenTrabajoId=@OrdenTrabajoId;
  SELECT @Sub=@Sub+ISNULL(SUM(HorasTrabajadas*CostoHora),0) FROM OrdenEmpleados WHERE OrdenTrabajoId=@OrdenTrabajoId;
  SET @Total=@Sub+@Imp;
  INSERT Facturas(ClienteId,OrdenTrabajoId,Subtotal,Impuestos,Descuentos,Total,SaldoPendiente,Estado,UsuarioEmisorId) VALUES(@Cliente,@OrdenTrabajoId,@Sub,@Imp,@Desc,@Total,@Total,N'PENDIENTE',@UsuarioId);SET @Fact=SCOPE_IDENTITY();
  INSERT FacturaDetalles(FacturaId,TipoDetalle,ServicioId,Descripcion,Cantidad,PrecioUnitario,Impuesto,Descuento,TotalLinea) SELECT @Fact,N'SERVICIO',os.ServicioId,s.Nombre,os.Cantidad,os.PrecioAplicado,(os.Cantidad*os.PrecioAplicado-os.DescuentoAplicado)*os.ImpuestoPorcentaje/100.0,os.DescuentoAplicado,(os.Cantidad*os.PrecioAplicado-os.DescuentoAplicado)*(1+os.ImpuestoPorcentaje/100.0) FROM OrdenServicios os JOIN Servicios s ON s.ServicioId=os.ServicioId WHERE os.OrdenTrabajoId=@OrdenTrabajoId;
  INSERT FacturaDetalles(FacturaId,TipoDetalle,ProductoId,Descripcion,Cantidad,PrecioUnitario,CostoUnitarioHistorico,Impuesto,Descuento,TotalLinea) SELECT @Fact,N'PRODUCTO',op.ProductoId,p.Nombre,op.CantidadUtilizada,op.PrecioAplicado,op.CostoAplicado,(op.CantidadUtilizada*op.PrecioAplicado-op.DescuentoAplicado)*op.ImpuestoPorcentaje/100.0,op.DescuentoAplicado,(op.CantidadUtilizada*op.PrecioAplicado-op.DescuentoAplicado)*(1+op.ImpuestoPorcentaje/100.0) FROM OrdenProductos op JOIN Productos p ON p.ProductoId=op.ProductoId WHERE op.OrdenTrabajoId=@OrdenTrabajoId AND op.CantidadUtilizada>0;
  INSERT FacturaDetalles(FacturaId,TipoDetalle,Descripcion,Cantidad,PrecioUnitario,Impuesto,Descuento,TotalLinea) SELECT @Fact,N'MANO DE OBRA',CONCAT(N'Mano de obra - ',e.NombreCompleto),oe.HorasTrabajadas,oe.CostoHora,0,0,oe.HorasTrabajadas*oe.CostoHora FROM OrdenEmpleados oe JOIN Empleados e ON e.EmpleadoId=oe.EmpleadoId WHERE oe.OrdenTrabajoId=@OrdenTrabajoId AND oe.HorasTrabajadas>0;
  UPDATE OrdenesTrabajo SET Estado=N'FACTURADA' WHERE OrdenTrabajoId=@OrdenTrabajoId;
  INSERT OrdenHistorialEstados(OrdenTrabajoId,EstadoAnterior,EstadoNuevo,UsuarioId,Observacion) VALUES(@OrdenTrabajoId,N'FINALIZADA',N'FACTURADA',@UsuarioId,N'Factura generada desde la orden.');
  COMMIT; SELECT @Fact FacturaId,@Total Total;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO


/* ================= ANULACION CONTROLADA DE VENTA ============ */
CREATE OR ALTER PROCEDURE dbo.sp_AnularVenta @VentaId INT,@UsuarioId INT,@Motivo NVARCHAR(500)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRAN;
 BEGIN TRY
  DECLARE @Estado NVARCHAR(30); SELECT @Estado=Estado FROM Ventas WITH(UPDLOCK,HOLDLOCK) WHERE VentaId=@VentaId;
  IF @Estado IS NULL THROW 50090,'Venta no existe.',1;
  IF @Estado<>N'CONFIRMADA' THROW 50091,'Solo una venta confirmada puede anularse.',1;
  DECLARE @Pid INT,@Cant DECIMAL(18,2),@Antes DECIMAL(18,2);
  DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT ProductoId,Cantidad FROM VentaDetalles WHERE VentaId=@VentaId;
  OPEN c; FETCH NEXT FROM c INTO @Pid,@Cant;
  WHILE @@FETCH_STATUS=0 BEGIN SELECT @Antes=ExistenciaActual FROM Productos WITH(UPDLOCK,HOLDLOCK) WHERE ProductoId=@Pid; UPDATE Productos SET ExistenciaActual=ExistenciaActual+@Cant WHERE ProductoId=@Pid; INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior,Observaciones) VALUES(@Pid,@Cant,N'DEVOLUCION CLIENTE',@UsuarioId,CONCAT(N'ANULA VEN-',@VentaId),@Antes,@Antes+@Cant,@Motivo); FETCH NEXT FROM c INTO @Pid,@Cant; END
  CLOSE c; DEALLOCATE c; UPDATE Ventas SET Estado=N'ANULADA' WHERE VentaId=@VentaId;
  IF EXISTS(SELECT 1 FROM Facturas WHERE VentaId=@VentaId AND Estado=N'PAGADA') THROW 50092,'La factura asociada está pagada; primero debe procesarse el reembolso controlado.',1;
  UPDATE Facturas SET Estado=N'ANULADA',FechaAnulacion=SYSDATETIME(),UsuarioAnulacionId=@UsuarioId,MotivoAnulacion=@Motivo WHERE VentaId=@VentaId AND Estado<>N'PAGADA';
  COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.sp_AnularFactura @FacturaId INT,@UsuarioId INT,@Motivo NVARCHAR(500)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRAN;
 BEGIN TRY
  DECLARE @Estado NVARCHAR(30),@VentaId INT; SELECT @Estado=Estado,@VentaId=VentaId FROM Facturas WITH(UPDLOCK,HOLDLOCK) WHERE FacturaId=@FacturaId;
  IF @Estado IS NULL THROW 50100,'Factura no existe.',1;
  IF @Estado=N'PAGADA' THROW 50101,'Una factura pagada no puede anularse directamente; requiere proceso de reembolso.',1;
  IF @Estado=N'ANULADA' THROW 50102,'La factura ya está anulada.',1;
  IF EXISTS(SELECT 1 FROM Pagos WHERE FacturaId=@FacturaId AND Anulado=0) THROW 50103,'La factura posee pagos registrados; deben reversarse mediante un proceso autorizado.',1;
  UPDATE Facturas SET Estado=N'ANULADA',FechaAnulacion=SYSDATETIME(),UsuarioAnulacionId=@UsuarioId,MotivoAnulacion=@Motivo,SaldoPendiente=0 WHERE FacturaId=@FacturaId;
  COMMIT;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END
GO

/* ==================== NOTIFICACIONES INTERNAS ================ */
CREATE OR ALTER PROCEDURE dbo.sp_GenerarNotificacionesSistema @UsuarioId INT=NULL
AS
BEGIN
 SET NOCOUNT ON;
 DELETE FROM Notificaciones WHERE Leida=0 AND Tipo IN(N'STOCK_MINIMO',N'CITA_PROXIMA',N'FACTURA_PENDIENTE',N'GARANTIA_VENCE',N'ORDEN_ATRASADA',N'COTIZACION_PENDIENTE');
 INSERT Notificaciones(UsuarioId,Tipo,Titulo,Mensaje,ModuloReferencia,RegistroReferenciaId,Prioridad)
 SELECT @UsuarioId,N'STOCK_MINIMO',N'Existencia mínima',CONCAT(N'El producto ',Nombre,N' tiene ',ExistenciaActual,N' unidades.'),N'PRODUCTOS',ProductoId,N'ALTA' FROM Productos WHERE Activo=1 AND ExistenciaActual<=ExistenciaMinima;
 INSERT Notificaciones(UsuarioId,Tipo,Titulo,Mensaje,ModuloReferencia,RegistroReferenciaId,Prioridad)
 SELECT @UsuarioId,N'CITA_PROXIMA',N'Cita próxima',CONCAT(N'Cita programada para ',CONVERT(NVARCHAR(30),FechaHoraInicio,120)),N'CITAS',CitaId,N'NORMAL' FROM Citas WHERE Estado IN(N'PROGRAMADA',N'CONFIRMADA') AND FechaHoraInicio BETWEEN SYSDATETIME() AND DATEADD(DAY,1,SYSDATETIME());
 INSERT Notificaciones(UsuarioId,Tipo,Titulo,Mensaje,ModuloReferencia,RegistroReferenciaId,Prioridad)
 SELECT @UsuarioId,N'FACTURA_PENDIENTE',N'Factura pendiente',CONCAT(NumeroFactura,N' saldo ₡',SaldoPendiente),N'FACTURAS',FacturaId,N'ALTA' FROM Facturas WHERE SaldoPendiente>0 AND Estado IN(N'PENDIENTE',N'PARCIALMENTE PAGADA');
 INSERT Notificaciones(UsuarioId,Tipo,Titulo,Mensaje,ModuloReferencia,RegistroReferenciaId,Prioridad)
 SELECT @UsuarioId,N'GARANTIA_VENCE',N'Garantía próxima a vencer',CONCAT(N'Vence el ',CONVERT(NVARCHAR(10),FechaVencimiento,120)),N'GARANTIAS',GarantiaId,N'NORMAL' FROM Garantias WHERE Estado=N'ACTIVA' AND FechaVencimiento BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY,7,CAST(GETDATE() AS DATE));
 INSERT Notificaciones(UsuarioId,Tipo,Titulo,Mensaje,ModuloReferencia,RegistroReferenciaId,Prioridad)
 SELECT @UsuarioId,N'ORDEN_ATRASADA',N'Orden atrasada',CONCAT(NumeroOrden,N' superó su fecha estimada.'),N'ORDENES',OrdenTrabajoId,N'ALTA' FROM OrdenesTrabajo WHERE FechaEstimadaEntrega<SYSDATETIME() AND Estado NOT IN(N'FINALIZADA',N'FACTURADA',N'ENTREGADA',N'CANCELADA');
 INSERT Notificaciones(UsuarioId,Tipo,Titulo,Mensaje,ModuloReferencia,RegistroReferenciaId,Prioridad)
 SELECT @UsuarioId,N'COTIZACION_PENDIENTE',N'Cotización pendiente',CONCAT(NumeroCotizacion,N' está pendiente de decisión.'),N'COTIZACIONES',CotizacionId,N'NORMAL' FROM Cotizaciones WHERE Estado IN(N'BORRADOR',N'ENVIADA');
END
GO
PRINT 'TallerProDB creada correctamente. Ejecute luego el script de datos de prueba.';
GO

/* ================= TALLERPRO V14: FACTURACIÓN MANUAL ================= */
/* Las ventas nuevas se confirman y descuentan inventario, pero se facturan
   posteriormente desde el módulo de Facturación. */
GO
CREATE OR ALTER PROCEDURE dbo.sp_ConfirmarVenta
 @ClienteId INT=NULL,@VendedorId INT=NULL,@CajeroId INT=NULL,@FormaPago NVARCHAR(50),@UsuarioId INT,@PermitirNegativo BIT=0,@Detalles dbo.VentaDetalleType READONLY
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF NOT EXISTS(SELECT 1 FROM @Detalles) THROW 50010,'La venta no contiene productos.',1;
 BEGIN TRAN;
 BEGIN TRY
   DECLARE @VentaId INT,@Subtotal DECIMAL(18,2),@Imp DECIMAL(18,2),@Desc DECIMAL(18,2),@Total DECIMAL(18,2);
   IF @PermitirNegativo=0 AND EXISTS(SELECT 1 FROM @Detalles d JOIN Productos p ON p.ProductoId=d.ProductoId WHERE d.Cantidad>p.ExistenciaActual) THROW 50011,'Existencia insuficiente para uno o más productos.',1;
   SELECT @Subtotal=SUM(Cantidad*PrecioUnitario),@Imp=SUM((Cantidad*PrecioUnitario-Descuento)*(ImpuestoPorcentaje/100.0)),@Desc=SUM(Descuento) FROM @Detalles;
   SET @Total=ISNULL(@Subtotal,0)-ISNULL(@Desc,0)+ISNULL(@Imp,0);
   INSERT Ventas(ClienteId,VendedorId,CajeroId,Subtotal,Impuestos,Descuentos,Total,FormaPago,Estado,UsuarioId) VALUES(@ClienteId,@VendedorId,@CajeroId,@Subtotal,@Imp,@Desc,@Total,@FormaPago,N'CONFIRMADA',@UsuarioId);
   SET @VentaId=SCOPE_IDENTITY();
   INSERT VentaDetalles(VentaId,ProductoId,Cantidad,PrecioUnitario,CostoUnitarioHistorico,ImpuestoPorcentaje,Descuento,TotalLinea)
   SELECT @VentaId,d.ProductoId,d.Cantidad,d.PrecioUnitario,p.PrecioCompra,d.ImpuestoPorcentaje,d.Descuento,(d.Cantidad*d.PrecioUnitario-d.Descuento)*(1+d.ImpuestoPorcentaje/100.0) FROM @Detalles d JOIN Productos p ON p.ProductoId=d.ProductoId;
   DECLARE @Pid INT,@Cant DECIMAL(18,2),@Antes DECIMAL(18,2);
   DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT ProductoId,Cantidad FROM @Detalles;
   OPEN c; FETCH NEXT FROM c INTO @Pid,@Cant;
   WHILE @@FETCH_STATUS=0 BEGIN
      SELECT @Antes=ExistenciaActual FROM Productos WITH(UPDLOCK,HOLDLOCK) WHERE ProductoId=@Pid;
      IF @PermitirNegativo=0 AND @Antes<@Cant THROW 50012,'Existencia cambió durante la venta; operación cancelada.',1;
      UPDATE Productos SET ExistenciaActual=ExistenciaActual-@Cant WHERE ProductoId=@Pid;
      INSERT MovimientosInventario(ProductoId,Cantidad,TipoMovimiento,UsuarioId,DocumentoReferencia,ExistenciaAnterior,ExistenciaPosterior,AutorizadoNegativo) VALUES(@Pid,@Cant,N'VENTA',@UsuarioId,CONCAT(N'VEN-',@VentaId),@Antes,@Antes-@Cant,@PermitirNegativo);
      FETCH NEXT FROM c INTO @Pid,@Cant;
   END;
   CLOSE c; DEALLOCATE c;
   COMMIT; SELECT @VentaId VentaId,@Total Total;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_FacturarVenta @VentaId INT,@UsuarioId INT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON; BEGIN TRAN;
 BEGIN TRY
   DECLARE @ClienteId INT,@Estado NVARCHAR(30),@FormaPago NVARCHAR(50),@Subtotal DECIMAL(18,2),@Impuestos DECIMAL(18,2),@Descuentos DECIMAL(18,2),@Total DECIMAL(18,2),@FacturaId INT;
   SELECT @ClienteId=ClienteId,@Estado=Estado,@FormaPago=FormaPago,@Subtotal=Subtotal,@Impuestos=Impuestos,@Descuentos=Descuentos,@Total=Total FROM Ventas WITH(UPDLOCK,HOLDLOCK) WHERE VentaId=@VentaId;
   IF @Estado IS NULL THROW 50210,'La venta no existe.',1;
   IF @Estado<>N'CONFIRMADA' THROW 50211,'Solo se pueden facturar ventas confirmadas.',1;
   IF EXISTS(SELECT 1 FROM Facturas WHERE VentaId=@VentaId) THROW 50212,'La venta ya tiene una factura activa.',1;
   INSERT Facturas(ClienteId,VentaId,Subtotal,Impuestos,Descuentos,Total,SaldoPendiente,Estado,FormaPagoDescripcion,UsuarioEmisorId) VALUES(@ClienteId,@VentaId,@Subtotal,@Impuestos,@Descuentos,@Total,@Total,N'PENDIENTE',@FormaPago,@UsuarioId);
   SET @FacturaId=SCOPE_IDENTITY();
   INSERT FacturaDetalles(FacturaId,TipoDetalle,ProductoId,Descripcion,Cantidad,PrecioUnitario,CostoUnitarioHistorico,Impuesto,Descuento,TotalLinea)
   SELECT @FacturaId,N'PRODUCTO',vd.ProductoId,p.Nombre,vd.Cantidad,vd.PrecioUnitario,vd.CostoUnitarioHistorico,(vd.Cantidad*vd.PrecioUnitario-vd.Descuento)*(vd.ImpuestoPorcentaje/100.0),vd.Descuento,vd.TotalLinea FROM VentaDetalles vd JOIN Productos p ON p.ProductoId=vd.ProductoId WHERE vd.VentaId=@VentaId;
   COMMIT; SELECT @FacturaId FacturaId,@Total Total;
 END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH
END;
GO


/* ============================================================
   TALLERPRO FINAL - PAGOS PARCIALES, COMPLETOS Y COMBINADOS
   ============================================================ */
/* Procedimiento nuevo para uno o varios medios de pago */
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarPagosFactura
    @FacturaId INT,
    @PagosJson NVARCHAR(MAX),
    @UsuarioId INT,
    @Observaciones NVARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;
    BEGIN TRY
        DECLARE @Saldo DECIMAL(18,2),
                @Estado NVARCHAR(30),
                @TotalPago DECIMAL(18,2);

        SELECT @Saldo=SaldoPendiente,@Estado=Estado
        FROM dbo.Facturas WITH(UPDLOCK,HOLDLOCK)
        WHERE FacturaId=@FacturaId;

        IF @Saldo IS NULL
            THROW 50120,'Factura no existe.',1;

        IF @Estado IN(N'ANULADA',N'REEMBOLSADA',N'PAGADA')
            THROW 50121,'La factura no admite nuevos pagos.',1;

        DECLARE @Tmp TABLE(
            FilaId INT IDENTITY PRIMARY KEY,
            FormaPagoId INT NOT NULL,
            Monto DECIMAL(18,2) NOT NULL
        );

        INSERT @Tmp(FormaPagoId,Monto)
        SELECT FormaPagoId,Monto
        FROM OPENJSON(@PagosJson)
        WITH(
            FormaPagoId INT '$.FormaPagoId',
            Monto DECIMAL(18,2) '$.Monto'
        );

        IF NOT EXISTS(SELECT 1 FROM @Tmp)
            THROW 50122,'Debe registrar al menos una forma de pago.',1;

        IF EXISTS(SELECT 1 FROM @Tmp WHERE Monto<=0)
            THROW 50123,'Todos los montos deben ser mayores que cero.',1;

        IF EXISTS(
            SELECT 1
            FROM @Tmp t
            LEFT JOIN dbo.FormasPago fp ON fp.FormaPagoId=t.FormaPagoId AND fp.Activa=1
            WHERE fp.FormaPagoId IS NULL
        )
            THROW 50124,'Una de las formas de pago no existe o está inactiva.',1;

        SELECT @TotalPago=SUM(Monto) FROM @Tmp;

        IF @TotalPago>@Saldo
            THROW 50125,'El pago no puede superar el saldo pendiente.',1;

        DECLARE @FormaPagoId INT,@Monto DECIMAL(18,2),@PagoId INT;
        DECLARE @Nuevos TABLE(PagoId INT PRIMARY KEY);
        DECLARE c CURSOR LOCAL FAST_FORWARD FOR
            SELECT FormaPagoId,Monto FROM @Tmp ORDER BY FilaId;

        OPEN c;
        FETCH NEXT FROM c INTO @FormaPagoId,@Monto;

        WHILE @@FETCH_STATUS=0
        BEGIN
            INSERT dbo.Pagos(
                FacturaId,Monto,FormaPagoId,NumeroReferencia,
                FechaHora,UsuarioId,Observaciones,Anulado
            )
            VALUES(
                @FacturaId,@Monto,@FormaPagoId,NULL,
                SYSDATETIME(),@UsuarioId,@Observaciones,0
            );

            SET @PagoId=SCOPE_IDENTITY();

            UPDATE dbo.Pagos
            SET NumeroReferencia=CONCAT(N'PAG-',RIGHT(N'00000000'+CONVERT(NVARCHAR(20),@PagoId),8))
            WHERE PagoId=@PagoId;

            INSERT @Nuevos(PagoId) VALUES(@PagoId);

            FETCH NEXT FROM c INTO @FormaPagoId,@Monto;
        END;

        CLOSE c;
        DEALLOCATE c;

        SET @Saldo=@Saldo-@TotalPago;

        UPDATE dbo.Facturas
        SET SaldoPendiente=@Saldo,
            Estado=CASE WHEN @Saldo=0 THEN N'PAGADA' ELSE N'PARCIALMENTE PAGADA' END
        WHERE FacturaId=@FacturaId;

        COMMIT;

        SELECT p.PagoId,p.FacturaId,p.Monto,fp.Nombre FormaPago,p.NumeroReferencia,p.FechaHora,p.UsuarioId,p.Observaciones
        FROM dbo.Pagos p
        JOIN dbo.FormasPago fp ON fp.FormaPagoId=p.FormaPagoId
        JOIN @Nuevos n ON n.PagoId=p.PagoId
        ORDER BY p.PagoId;

        SELECT @FacturaId FacturaId,@Saldo SaldoPendiente,
               CASE WHEN @Saldo=0 THEN N'PAGADA' ELSE N'PARCIALMENTE PAGADA' END Estado,
               @TotalPago MontoRegistrado;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','c')>=-1
        BEGIN
            IF CURSOR_STATUS('local','c')> -1 CLOSE c;
            DEALLOCATE c;
        END;
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

/* Mantener compatibilidad con llamadas antiguas y generar referencia automática */
CREATE OR ALTER PROCEDURE dbo.sp_RegistrarPago
 @FacturaId INT,@Monto DECIMAL(18,2),@FormaPagoId INT,@Referencia NVARCHAR(120)=NULL,@UsuarioId INT,@Observaciones NVARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Json NVARCHAR(MAX)=N'[{"FormaPagoId":'+CONVERT(NVARCHAR(20),@FormaPagoId)+N',"Monto":'+CONVERT(NVARCHAR(60),@Monto)+N'}]';
 EXEC dbo.sp_RegistrarPagosFactura @FacturaId=@FacturaId,@PagosJson=@Json,@UsuarioId=@UsuarioId,@Observaciones=@Observaciones;
END;
GO


/* ============================================================
   REGLA FINAL DE GARANTÍAS
   Solo se permite una garantía cuando la orden o venta posee
   una factura completamente PAGADA y con saldo pendiente 0.
   ============================================================ */
GO
CREATE OR ALTER TRIGGER dbo.trg_Garantias_SoloFacturasPagadas
ON dbo.Garantias
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(
        SELECT 1
        FROM inserted i
        WHERE
            (i.OrdenTrabajoId IS NULL AND i.VentaId IS NULL)
            OR (i.OrdenTrabajoId IS NOT NULL AND i.VentaId IS NOT NULL)
            OR NOT EXISTS(
                SELECT 1
                FROM dbo.Facturas f
                WHERE f.Estado = N'PAGADA'
                  AND f.SaldoPendiente = 0
                  AND (
                        (i.OrdenTrabajoId IS NOT NULL AND f.OrdenTrabajoId = i.OrdenTrabajoId)
                     OR (i.VentaId IS NOT NULL AND f.VentaId = i.VentaId)
                  )
            )
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50350,
              'La garantía solo puede registrarse para una orden o venta con factura completamente pagada.',
              1;
    END;
END;
GO

PRINT N'TallerProDB final creada correctamente. Ahora ejecute 02_TallerPro_INSERCION_DATOS.sql.';
GO
