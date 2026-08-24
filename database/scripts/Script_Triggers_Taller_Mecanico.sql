-- ============================================================
-- TALLER MECANICO - Triggers de auditoria y reglas de negocio (T-SQL)
-- Se ejecuta DESPUES de:
--   1) SQLQuery1.sql
--   2) Script_Complemento_Taller_Mecanico.sql
--   3) Script_Procedimientos_Vistas_Taller_Mecanico.sql
--
-- Objetivo: dejar rastro en BITACORA_AUDITORIA de cualquier
-- INSERT/UPDATE/DELETE sobre tablas sensibles, incluso si no
-- se realizo a traves de los procedimientos almacenados, y
-- blindar reglas de negocio criticas (no eliminar facturas
-- pagadas, no eliminar catalogos en uso, etc.)
-- ============================================================

USE taller_mecanico;
GO

-- ============================================================
-- 1. USUARIOS, ROLES Y PERMISOS (cambios de seguridad)
-- ============================================================

CREATE OR ALTER TRIGGER TRG_USUARIOS_AUDIT
ON USUARIOS
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Altas
    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_nuevos, descripcion)
    SELECT 'USUARIOS', 'CREAR_USUARIO', 'INSERCION', i.id_usuario,
           CONCAT('nombre_usuario=', i.nombre_usuario, '; email=', i.email, '; activo=', i.activo), 'Alta de usuario'
    FROM inserted i
    LEFT JOIN deleted d ON d.id_usuario = i.id_usuario
    WHERE d.id_usuario IS NULL;

    -- Cambios (activo/inactivo, password, email, etc.)
    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'USUARIOS', 'MODIFICAR_USUARIO', 'ACTUALIZACION', i.id_usuario,
           CONCAT('activo=', d.activo, '; email=', d.email),
           CONCAT('activo=', i.activo, '; email=', i.email),
           CASE WHEN d.activo <> i.activo THEN 'Cambio de estado activo/inactivo' ELSE 'Modificacion de datos de usuario' END
    FROM inserted i
    JOIN deleted d ON d.id_usuario = i.id_usuario;

    -- Bajas fisicas (no deberian ocurrir; se registra igual)
    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, descripcion)
    SELECT 'USUARIOS', 'ELIMINAR_USUARIO', 'ELIMINACION', d.id_usuario,
           CONCAT('nombre_usuario=', d.nombre_usuario), 'Eliminacion fisica de usuario'
    FROM deleted d
    LEFT JOIN inserted i ON i.id_usuario = d.id_usuario
    WHERE i.id_usuario IS NULL;
END;
GO

CREATE OR ALTER TRIGGER TRG_USUARIO_ROL_AUDIT
ON USUARIO_ROL
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_nuevos, descripcion)
    SELECT 'ROLES', 'ASIGNAR_ROL', 'INSERCION', i.id_usuario,
           CONCAT('id_rol=', i.id_rol), 'Rol asignado a usuario'
    FROM inserted i;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, descripcion)
    SELECT 'ROLES', 'QUITAR_ROL', 'ELIMINACION', d.id_usuario,
           CONCAT('id_rol=', d.id_rol), 'Rol removido de usuario'
    FROM deleted d;
END;
GO

CREATE OR ALTER TRIGGER TRG_ROL_PERMISO_AUDIT
ON ROL_PERMISO
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_nuevos, descripcion)
    SELECT 'PERMISOS', 'ASIGNAR_PERMISO', 'INSERCION', i.id_rol,
           CONCAT('id_permiso=', i.id_permiso), 'Permiso asignado a rol'
    FROM inserted i;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, descripcion)
    SELECT 'PERMISOS', 'QUITAR_PERMISO', 'ELIMINACION', d.id_rol,
           CONCAT('id_permiso=', d.id_permiso), 'Permiso removido de rol'
    FROM deleted d;
END;
GO

-- ============================================================
-- 2. CAMBIOS DE PRECIO (servicios y repuestos)
-- ============================================================

CREATE OR ALTER TRIGGER TRG_REPUESTOS_PRECIO_AUDIT
ON REPUESTOS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(precio_venta) RETURN;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'REPUESTOS', 'MODIFICAR_PRECIO', 'ACTUALIZACION', i.id_repuesto,
           CONCAT('precio_venta=', d.precio_venta), CONCAT('precio_venta=', i.precio_venta),
           'Cambio de precio de venta de repuesto'
    FROM inserted i
    JOIN deleted d ON d.id_repuesto = i.id_repuesto
    WHERE d.precio_venta <> i.precio_venta;
END;
GO

CREATE OR ALTER TRIGGER TRG_SERVICIOS_PRECIO_AUDIT
ON SERVICIOS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(precio_base) RETURN;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'SERVICIOS', 'MODIFICAR_PRECIO', 'ACTUALIZACION', i.id_servicio,
           CONCAT('precio_base=', d.precio_base), CONCAT('precio_base=', i.precio_base),
           'Cambio de precio base de servicio'
    FROM inserted i
    JOIN deleted d ON d.id_servicio = i.id_servicio
    WHERE d.precio_base <> i.precio_base;
END;
GO

-- ============================================================
-- 3. VENTAS Y FACTURAS (anulaciones)
-- ============================================================

CREATE OR ALTER TRIGGER TRG_VENTAS_ANULACION_AUDIT
ON VENTAS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(estado) RETURN;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'VENTAS', 'ANULAR_VENTA', 'ACTUALIZACION', i.id_venta,
           CONCAT('estado=', d.estado), CONCAT('estado=', i.estado), 'Cambio de estado de venta'
    FROM inserted i
    JOIN deleted d ON d.id_venta = i.id_venta
    WHERE i.estado = 'ANULADA' AND d.estado <> 'ANULADA';
END;
GO

CREATE OR ALTER TRIGGER TRG_FACTURAS_NO_ELIMINAR_PAGADAS
ON FACTURAS
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted WHERE estado = 'PAGADA')
    BEGIN
        RAISERROR('No se pueden eliminar facturas pagadas. Utilice el proceso de anulacion.', 16, 1);
        RETURN;
    END

    -- Solo se permite eliminar fisicamente facturas que nunca se pagaron ni se anularon
    DELETE FROM FACTURAS WHERE id_factura IN (SELECT id_factura FROM deleted WHERE estado NOT IN ('PAGADA', 'PARCIAL'));

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, descripcion)
    SELECT 'FACTURACION', 'ELIMINAR_FACTURA', 'ELIMINACION', d.id_factura,
           CONCAT('estado=', d.estado), 'Eliminacion fisica de factura'
    FROM deleted d
    WHERE d.estado NOT IN ('PAGADA', 'PARCIAL');
END;
GO

-- ============================================================
-- 4. DESACTIVACION DE CATALOGOS Y ENTIDADES MAESTRAS
-- ============================================================

CREATE OR ALTER TRIGGER TRG_CLIENTES_ESTADO_AUDIT
ON CLIENTES
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(activo) RETURN;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'CLIENTES', CASE WHEN i.activo = 0 THEN 'DESACTIVAR_CLIENTE' ELSE 'ACTIVAR_CLIENTE' END,
           'ACTUALIZACION', i.id_cliente, CONCAT('activo=', d.activo), CONCAT('activo=', i.activo),
           'Cambio de estado de cliente'
    FROM inserted i
    JOIN deleted d ON d.id_cliente = i.id_cliente
    WHERE d.activo <> i.activo;
END;
GO

CREATE OR ALTER TRIGGER TRG_VEHICULOS_ESTADO_AUDIT
ON VEHICULOS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(activo) RETURN;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'VEHICULOS', CASE WHEN i.activo = 0 THEN 'DESACTIVAR_VEHICULO' ELSE 'ACTIVAR_VEHICULO' END,
           'ACTUALIZACION', i.id_vehiculo, CONCAT('activo=', d.activo), CONCAT('activo=', i.activo),
           'Cambio de estado de vehiculo'
    FROM inserted i
    JOIN deleted d ON d.id_vehiculo = i.id_vehiculo
    WHERE d.activo <> i.activo;
END;
GO

CREATE OR ALTER TRIGGER TRG_EMPLEADOS_ESTADO_AUDIT
ON EMPLEADOS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(estado_laboral) RETURN;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'EMPLEADOS', 'CAMBIO_ESTADO_LABORAL', 'ACTUALIZACION', i.id_empleado,
           CONCAT('estado_laboral=', d.estado_laboral), CONCAT('estado_laboral=', i.estado_laboral),
           'Cambio de estado laboral de empleado'
    FROM inserted i
    JOIN deleted d ON d.id_empleado = i.id_empleado
    WHERE d.estado_laboral <> i.estado_laboral;
END;
GO

CREATE OR ALTER TRIGGER TRG_PROVEEDORES_ESTADO_AUDIT
ON PROVEEDORES
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(estado) RETURN;

    INSERT INTO BITACORA_AUDITORIA (modulo, accion, tipo_operacion, id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    SELECT 'PROVEEDORES', 'CAMBIO_ESTADO_PROVEEDOR', 'ACTUALIZACION', i.id_proveedor,
           CONCAT('estado=', d.estado), CONCAT('estado=', i.estado), 'Cambio de estado de proveedor'
    FROM inserted i
    JOIN deleted d ON d.id_proveedor = i.id_proveedor
    WHERE d.estado <> i.estado;
END;
GO

-- ============================================================
-- 5. BLOQUEAR ELIMINACION FISICA DE CATALOGOS EN USO
-- ============================================================

-- Repuestos: no eliminar si tiene movimientos, compras, ventas u ordenes asociadas
CREATE OR ALTER TRIGGER TRG_REPUESTOS_NO_ELIMINAR_EN_USO
ON REPUESTOS
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM deleted d
        WHERE EXISTS (SELECT 1 FROM MOVIMIENTOS_INVENTARIO m WHERE m.id_repuesto = d.id_repuesto)
           OR EXISTS (SELECT 1 FROM DETALLE_VENTA dv WHERE dv.id_repuesto = d.id_repuesto)
           OR EXISTS (SELECT 1 FROM DETALLE_ORDEN_REPUESTOS dor WHERE dor.id_repuesto = d.id_repuesto)
           OR EXISTS (SELECT 1 FROM DETALLE_COMPRA dc WHERE dc.id_repuesto = d.id_repuesto)
    )
    BEGIN
        RAISERROR('No se puede eliminar un repuesto con movimientos historicos. Desactivelo en su lugar.', 16, 1);
        RETURN;
    END

    DELETE FROM REPUESTOS WHERE id_repuesto IN (SELECT id_repuesto FROM deleted);
END;
GO

-- Servicios: no eliminar si ya fue usado en alguna orden o cotizacion
CREATE OR ALTER TRIGGER TRG_SERVICIOS_NO_ELIMINAR_EN_USO
ON SERVICIOS
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM deleted d
        WHERE EXISTS (SELECT 1 FROM DETALLE_ORDEN_SERVICIOS dos WHERE dos.id_servicio = d.id_servicio)
           OR EXISTS (SELECT 1 FROM COTIZACION_SERVICIOS cs WHERE cs.id_servicio = d.id_servicio)
    )
    BEGIN
        RAISERROR('No se puede eliminar un servicio con historial de uso. Desactivelo en su lugar.', 16, 1);
        RETURN;
    END

    DELETE FROM SERVICIOS WHERE id_servicio IN (SELECT id_servicio FROM deleted);
END;
GO

-- ============================================================
-- FIN DEL SCRIPT DE TRIGGERS
-- Cubierto:
--   - Auditoria automatica de usuarios, roles y permisos
--   - Auditoria de cambios de precio (servicios y repuestos)
--   - Auditoria de anulacion de ventas
--   - Bloqueo de eliminacion fisica de facturas pagadas (regla 10)
--   - Bloqueo de eliminacion fisica de catalogos en uso (regla 15)
--   - Auditoria de activacion/desactivacion de clientes, vehiculos,
--     empleados y proveedores
-- Pendiente:
--   - Datos de prueba
--   - Diagrama ER y diccionario de datos
-- ============================================================
