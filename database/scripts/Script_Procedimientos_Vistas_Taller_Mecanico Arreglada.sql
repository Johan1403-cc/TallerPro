-- ============================================================
-- TALLER MECANICO - Vistas, Funciones y Procedimientos (T-SQL)
-- Se ejecuta DESPUES de:
--   1) SQLQuery1.sql (script original)
--   2) Script_Complemento_Taller_Mecanico.sql (tablas faltantes)
-- ============================================================

USE taller_mecanico;
GO

-- ============================================================
-- 1. VISTAS
-- ============================================================

-- Saldo pendiente de cada factura (total - pagos registrados)
CREATE OR ALTER VIEW VW_SALDO_FACTURAS AS
SELECT
    f.id_factura,
    f.numero_consecutivo,
    f.id_cliente,
    f.total,
    ISNULL(SUM(p.monto), 0)                       AS total_pagado,
    f.total - ISNULL(SUM(p.monto), 0)             AS saldo_pendiente,
    f.estado
FROM FACTURAS f
LEFT JOIN PAGOS p ON p.id_factura = f.id_factura
GROUP BY f.id_factura, f.numero_consecutivo, f.id_cliente, f.total, f.estado;
GO

-- Repuestos que llegaron o estan por debajo de la existencia minima
CREATE OR ALTER VIEW VW_INVENTARIO_ALERTA AS
SELECT
    r.id_repuesto,
    r.codigo_interno,
    r.nombre,
    r.stock_actual,
    r.existencia_minima,
    r.existencia_maxima,
    p.nombre_empresa AS proveedor_principal
FROM REPUESTOS r
LEFT JOIN PROVEEDORES p ON p.id_proveedor = r.id_proveedor
WHERE r.stock_actual <= r.existencia_minima
  AND r.estado = 'ACTIVO';
GO

-- Resumen de ordenes de trabajo con datos de cliente y vehiculo
CREATE OR ALTER VIEW VW_ORDENES_RESUMEN AS
SELECT
    o.id_orden,
    o.estado,
    o.prioridad,
    o.fecha_ingreso,
    o.fecha_estimada_entrega,
    v.id_vehiculo,
    v.placa,
    c.id_cliente,
    c.nombre AS nombre_cliente,
    (SELECT ISNULL(SUM(ds.subtotal), 0) FROM DETALLE_ORDEN_SERVICIOS ds WHERE ds.id_orden = o.id_orden)
      + (SELECT ISNULL(SUM(dr.subtotal), 0) FROM DETALLE_ORDEN_REPUESTOS dr WHERE dr.id_orden = o.id_orden) AS total_estimado
FROM ORDENES_TRABAJO o
JOIN VEHICULOS v ON v.id_vehiculo = o.id_vehiculo
JOIN CLIENTES c ON c.id_cliente = v.id_cliente;
GO

-- Historial completo de un vehiculo (recepciones, diagnosticos, ordenes)
CREATE OR ALTER VIEW VW_HISTORIAL_VEHICULO AS
SELECT
    v.id_vehiculo,
    v.placa,
    'RECEPCION'         AS tipo_evento,
    rc.id_recepcion     AS id_referencia,
    rc.fecha_hora_ingreso AS fecha_evento,
    rc.motivo_visita    AS descripcion
FROM RECEPCIONES rc
JOIN VEHICULOS v ON v.id_vehiculo = rc.id_vehiculo
UNION ALL
SELECT
    v.id_vehiculo,
    v.placa,
    'DIAGNOSTICO'        AS tipo_evento,
    d.id_diagnostico      AS id_referencia,
    d.fecha_hora           AS fecha_evento,
    d.problemas_encontrados AS descripcion
FROM DIAGNOSTICOS d
JOIN RECEPCIONES rc ON rc.id_recepcion = d.id_recepcion
JOIN VEHICULOS v ON v.id_vehiculo = rc.id_vehiculo
UNION ALL
SELECT
    v.id_vehiculo,
    v.placa,
    'ORDEN_TRABAJO'      AS tipo_evento,
    o.id_orden            AS id_referencia,
    o.fecha_ingreso         AS fecha_evento,
    o.estado                 AS descripcion
FROM ORDENES_TRABAJO o
JOIN VEHICULOS v ON v.id_vehiculo = o.id_vehiculo;
GO

-- ============================================================
-- 2. FUNCIONES
-- ============================================================

-- Total actual de una orden de trabajo (servicios + repuestos)
CREATE OR ALTER FUNCTION FN_TOTAL_ORDEN (@id_orden INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);
    SELECT @total =
        ISNULL((SELECT SUM(subtotal) FROM DETALLE_ORDEN_SERVICIOS WHERE id_orden = @id_orden), 0)
      + ISNULL((SELECT SUM(subtotal) FROM DETALLE_ORDEN_REPUESTOS WHERE id_orden = @id_orden), 0);
    RETURN @total;
END;
GO

-- Total de una cotizacion (servicios + repuestos)
CREATE OR ALTER FUNCTION FN_TOTAL_COTIZACION (@id_cotizacion INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);
    SELECT @total =
        ISNULL((SELECT SUM(subtotal) FROM COTIZACION_SERVICIOS WHERE id_cotizacion = @id_cotizacion), 0)
      + ISNULL((SELECT SUM(subtotal) FROM COTIZACION_REPUESTOS WHERE id_cotizacion = @id_cotizacion), 0);
    RETURN @total;
END;
GO

-- Saldo pendiente de una factura especifica
CREATE OR ALTER FUNCTION FN_SALDO_FACTURA (@id_factura INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2), @pagado DECIMAL(10,2);
    SELECT @total = total FROM FACTURAS WHERE id_factura = @id_factura;
    SELECT @pagado = ISNULL(SUM(monto), 0) FROM PAGOS WHERE id_factura = @id_factura;
    RETURN ISNULL(@total, 0) - ISNULL(@pagado, 0);
END;
GO

-- ============================================================
-- 3. PROCEDIMIENTOS ALMACENADOS
-- ============================================================

-- ------------------------------------------------------------
-- 3.0 Auditoria: insercion generica en la bitacora
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_REGISTRAR_AUDITORIA
    @id_usuario             INT = NULL,
    @direccion_ip           VARCHAR(45) = NULL,
    @modulo                 VARCHAR(60),
    @accion                 VARCHAR(60),
    @tipo_operacion         VARCHAR(20),
    @id_registro_afectado   INT = NULL,
    @valores_anteriores     VARCHAR(MAX) = NULL,
    @valores_nuevos         VARCHAR(MAX) = NULL,
    @descripcion            VARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO BITACORA_AUDITORIA
        (id_usuario, direccion_ip, modulo, accion, tipo_operacion,
         id_registro_afectado, valores_anteriores, valores_nuevos, descripcion)
    VALUES
        (@id_usuario, @direccion_ip, @modulo, @accion, @tipo_operacion,
         @id_registro_afectado, @valores_anteriores, @valores_nuevos, @descripcion);
END;
GO

-- ------------------------------------------------------------
-- 3.1 Movimiento de inventario (nucleo de todo cambio de stock)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_REGISTRAR_MOVIMIENTO_INVENTARIO
    @id_repuesto            INT,
    @tipo_movimiento        VARCHAR(30),     -- COMPRA/VENTA/USO_ORDEN/DEVOLUCION_CLIENTE/DEVOLUCION_PROVEEDOR/AJUSTE_POSITIVO/AJUSTE_NEGATIVO/DANADO/TRASLADO
    @cantidad               DECIMAL(10,2),   -- siempre positiva; el signo lo decide el tipo de movimiento
    @id_usuario             INT,
    @documento_referencia   VARCHAR(60) = NULL,
    @observaciones          VARCHAR(300) = NULL,
    @forzar_negativo        BIT = 0          -- 1 = permite existencia negativa (autorizacion especial)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @cantidad <= 0
    BEGIN
        RAISERROR('La cantidad del movimiento debe ser mayor a cero.', 16, 1);
        RETURN;
    END

    DECLARE @existencia_anterior DECIMAL(10,2);
    DECLARE @existencia_posterior DECIMAL(10,2);
    DECLARE @signo INT;

    -- Movimientos que aumentan stock vs los que lo disminuyen
    IF @tipo_movimiento IN ('COMPRA', 'DEVOLUCION_CLIENTE', 'AJUSTE_POSITIVO')
        SET @signo = 1;
    ELSE IF @tipo_movimiento IN ('VENTA', 'USO_ORDEN', 'DEVOLUCION_PROVEEDOR', 'AJUSTE_NEGATIVO', 'DANADO')
        SET @signo = -1;
    ELSE
    BEGIN
        RAISERROR('Tipo de movimiento no reconocido: %s', 16, 1, @tipo_movimiento);
        RETURN;
    END

    BEGIN TRANSACTION;

        SELECT @existencia_anterior = stock_actual
        FROM REPUESTOS WITH (UPDLOCK, ROWLOCK)
        WHERE id_repuesto = @id_repuesto;

        IF @existencia_anterior IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Repuesto no encontrado.', 16, 1);
            RETURN;
        END

        SET @existencia_posterior = @existencia_anterior + (@signo * @cantidad);

        IF @existencia_posterior < 0 AND @forzar_negativo = 0
        BEGIN
            ROLLBACK TRANSACTION;
            DECLARE @existenciaTexto VARCHAR(30);
            SET @existenciaTexto = CONVERT(VARCHAR(30), @existencia_anterior);

            RAISERROR(
                'Existencia insuficiente para el repuesto %d. Disponible: %s',
                16,
                1,
                @id_repuesto,
                @existenciaTexto
            );
            RETURN;
        END

        UPDATE REPUESTOS
        SET stock_actual = @existencia_posterior
        WHERE id_repuesto = @id_repuesto;

        INSERT INTO MOVIMIENTOS_INVENTARIO
            (id_repuesto, tipo_movimiento, cantidad, id_usuario, documento_referencia,
             existencia_anterior, existencia_posterior, observaciones)
        VALUES
            (@id_repuesto, @tipo_movimiento, @cantidad, @id_usuario, @documento_referencia,
             @existencia_anterior, @existencia_posterior, @observaciones);

    COMMIT TRANSACTION;

    IF @existencia_posterior <= (SELECT existencia_minima FROM REPUESTOS WHERE id_repuesto = @id_repuesto)
    BEGIN
        -- deja registro para que la aplicacion genere la notificacion de existencia minima
        EXEC SP_REGISTRAR_AUDITORIA
            @id_usuario = @id_usuario,
            @modulo = 'INVENTARIO',
            @accion = 'ALERTA_EXISTENCIA_MINIMA',
            @tipo_operacion = 'CONSULTA',
            @id_registro_afectado = @id_repuesto,
            @descripcion = 'El repuesto alcanzo o quedo por debajo de la existencia minima.';
    END
END;
GO

-- ------------------------------------------------------------
-- 3.2 Confirmar una compra (aumenta inventario por cada linea)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_CONFIRMAR_COMPRA
    @id_compra      INT,
    @id_usuario     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM COMPRAS WHERE id_compra = @id_compra AND estado = 'REGISTRADA')
    BEGIN
        RAISERROR('La compra no existe o ya fue procesada.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

        DECLARE @id_repuesto INT, @cantidad DECIMAL(10,2);
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT id_repuesto, cantidad FROM DETALLE_COMPRA WHERE id_compra = @id_compra;

        OPEN cur;
        FETCH NEXT FROM cur INTO @id_repuesto, @cantidad;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @documento VARCHAR(60);
            SET @documento = CONCAT('COMPRA-', @id_compra);

            EXEC SP_REGISTRAR_MOVIMIENTO_INVENTARIO
                @id_repuesto = @id_repuesto,
                @tipo_movimiento = 'COMPRA',
                @cantidad = @cantidad,
                @id_usuario = @id_usuario,
                @documento_referencia = @documento
            FETCH NEXT FROM cur INTO @id_repuesto, @cantidad;
        END
        CLOSE cur;
        DEALLOCATE cur;

        UPDATE COMPRAS SET estado = 'RECIBIDA' WHERE id_compra = @id_compra;

    COMMIT TRANSACTION;

    EXEC SP_REGISTRAR_AUDITORIA
        @id_usuario = @id_usuario, @modulo = 'COMPRAS', @accion = 'CONFIRMAR_COMPRA',
        @tipo_operacion = 'ACTUALIZACION', @id_registro_afectado = @id_compra,
        @descripcion = 'Compra confirmada, inventario actualizado.';
END;
GO

-- ------------------------------------------------------------
-- 3.3 Confirmar una venta (valida y disminuye inventario)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_CONFIRMAR_VENTA
    @id_venta       INT,
    @id_usuario     INT,
    @forzar_negativo BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM VENTAS WHERE id_venta = @id_venta AND estado = 'CONFIRMADA')
    BEGIN
        RAISERROR('La venta no existe o su estado no permite confirmarla.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

        DECLARE @id_repuesto INT, @cantidad DECIMAL(10,2);
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT id_repuesto, cantidad FROM DETALLE_VENTA WHERE id_venta = @id_venta;

        OPEN cur;
        FETCH NEXT FROM cur INTO @id_repuesto, @cantidad;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @documento VARCHAR(60);
            SET @documento = CONCAT('VENTA-', @id_venta);

            EXEC SP_REGISTRAR_MOVIMIENTO_INVENTARIO
                @id_repuesto = @id_repuesto,
                @tipo_movimiento = 'VENTA',
                @cantidad = @cantidad,
                @id_usuario = @id_usuario,
                @documento_referencia = @documento,
                @forzar_negativo = @forzar_negativo;
            FETCH NEXT FROM cur INTO @id_repuesto, @cantidad;
        END
        CLOSE cur;
        DEALLOCATE cur;

    COMMIT TRANSACTION;

    EXEC SP_REGISTRAR_AUDITORIA
        @id_usuario = @id_usuario, @modulo = 'VENTAS', @accion = 'CONFIRMAR_VENTA',
        @tipo_operacion = 'ACTUALIZACION', @id_registro_afectado = @id_venta,
        @descripcion = 'Venta confirmada, inventario actualizado.';
END;
GO

-- ------------------------------------------------------------
-- 3.4 Usar un repuesto en una orden de trabajo
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_USAR_REPUESTO_EN_ORDEN
    @id_orden       INT,
    @id_repuesto    INT,
    @cantidad       DECIMAL(10,2),
    @id_usuario     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @precio_venta DECIMAL(10,2);
    SELECT @precio_venta = precio_venta FROM REPUESTOS WHERE id_repuesto = @id_repuesto;

    IF @precio_venta IS NULL
    BEGIN
        RAISERROR('Repuesto no encontrado.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

        INSERT INTO DETALLE_ORDEN_REPUESTOS (id_orden, id_repuesto, cantidad, subtotal)
        VALUES (@id_orden, @id_repuesto, @cantidad, @cantidad * @precio_venta);

        DECLARE @documento VARCHAR(60);
        SET @documento = CONCAT('ORDEN-', @id_orden);

        EXEC SP_REGISTRAR_MOVIMIENTO_INVENTARIO
            @id_repuesto = @id_repuesto,
            @tipo_movimiento = 'USO_ORDEN',
            @cantidad = @cantidad,
            @id_usuario = @id_usuario,
            @documento_referencia = @documento;

    COMMIT TRANSACTION;
END;
GO

-- ------------------------------------------------------------
-- 3.5 Cambiar el estado de una orden de trabajo (con historial)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_CAMBIAR_ESTADO_ORDEN
    @id_orden       INT,
    @nuevo_estado   VARCHAR(20),
    @id_usuario     INT,
    @observacion    VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @estado_actual VARCHAR(20);
    SELECT @estado_actual = estado FROM ORDENES_TRABAJO WHERE id_orden = @id_orden;

    IF @estado_actual IS NULL
    BEGIN
        RAISERROR('Orden de trabajo no encontrada.', 16, 1);
        RETURN;
    END

    IF @estado_actual = @nuevo_estado
    BEGIN
        RAISERROR('La orden ya se encuentra en ese estado.', 16, 1);
        RETURN;
    END

    -- Regla de negocio: no se entrega una orden que sigue en proceso
    IF @nuevo_estado = 'ENTREGADA' AND @estado_actual NOT IN ('FACTURADA', 'FINALIZADA')
    BEGIN
        RAISERROR('La orden no puede entregarse mientras no este finalizada/facturada.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

        UPDATE ORDENES_TRABAJO SET estado = @nuevo_estado WHERE id_orden = @id_orden;

        INSERT INTO HISTORIAL_ESTADO_ORDEN (id_orden, estado_anterior, estado_nuevo, id_usuario, observacion)
        VALUES (@id_orden, @estado_actual, @nuevo_estado, @id_usuario, @observacion);

    COMMIT TRANSACTION;

    EXEC SP_REGISTRAR_AUDITORIA
        @id_usuario = @id_usuario, @modulo = 'ORDENES_TRABAJO', @accion = 'CAMBIO_ESTADO',
        @tipo_operacion = 'ACTUALIZACION', @id_registro_afectado = @id_orden,
        @valores_anteriores = @estado_actual, @valores_nuevos = @nuevo_estado, @descripcion = @observacion;
END;
GO

-- ------------------------------------------------------------
-- 3.6 Generar factura a partir de una orden de trabajo finalizada
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_GENERAR_FACTURA_DESDE_ORDEN
    @id_orden           INT,
    @id_usuario_emite   INT,
    @porcentaje_impuesto DECIMAL(5,2) = 13.00
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @estado VARCHAR(20), @id_vehiculo INT, @id_cliente INT, @subtotal DECIMAL(10,2);

    SELECT @estado = estado, @id_vehiculo = id_vehiculo FROM ORDENES_TRABAJO WHERE id_orden = @id_orden;
    IF @estado IS NULL
    BEGIN
        RAISERROR('Orden de trabajo no encontrada.', 16, 1);
        RETURN;
    END
    IF @estado <> 'FINALIZADA'
    BEGIN
        RAISERROR('Solo se pueden facturar ordenes finalizadas.', 16, 1);
        RETURN;
    END

    SELECT @id_cliente = id_cliente FROM VEHICULOS WHERE id_vehiculo = @id_vehiculo;
    SET @subtotal = dbo.FN_TOTAL_ORDEN(@id_orden);

    DECLARE @impuestos DECIMAL(10,2) = ROUND(@subtotal * @porcentaje_impuesto / 100.0, 2);
    DECLARE @total DECIMAL(10,2) = @subtotal + @impuestos;

    BEGIN TRANSACTION;

        INSERT INTO FACTURAS
            (numero_consecutivo, tipo_factura, id_orden, id_cliente, subtotal, impuestos, descuentos, total, estado, id_usuario_emite)
        VALUES
            ((SELECT ISNULL(MAX(numero_consecutivo), 0) + 1 FROM FACTURAS), 'ORDEN', @id_orden, @id_cliente,
             @subtotal, @impuestos, 0, @total, 'PENDIENTE', @id_usuario_emite);

        DECLARE @id_factura INT = SCOPE_IDENTITY();

        UPDATE ORDENES_TRABAJO SET estado = 'FACTURADA' WHERE id_orden = @id_orden;

        INSERT INTO HISTORIAL_ESTADO_ORDEN (id_orden, estado_anterior, estado_nuevo, id_usuario, observacion)
        VALUES (@id_orden, 'FINALIZADA', 'FACTURADA', @id_usuario_emite, CONCAT('Factura generada #', @id_factura));

    COMMIT TRANSACTION;
        DECLARE @descripcion VARCHAR(300);
        SET @descripcion = CONCAT('Factura generada desde orden #', @id_orden);

        EXEC SP_REGISTRAR_AUDITORIA
            @id_usuario = @id_usuario_emite,
            @modulo = 'FACTURACION',
            @accion = 'GENERAR_FACTURA',
            @tipo_operacion = 'INSERCION',
            @id_registro_afectado = @id_factura,
            @descripcion = @descripcion;
END;
GO

-- ------------------------------------------------------------
-- 3.7 Registrar un pago sobre una factura (parcial o total)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_REGISTRAR_PAGO
    @id_factura         INT,
    @monto              DECIMAL(10,2),
    @forma_pago         VARCHAR(20),
    @numero_referencia  VARCHAR(60) = NULL,
    @id_usuario_recibe  INT,
    @observaciones      VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @monto <= 0
    BEGIN
        RAISERROR('El monto del pago debe ser mayor a cero.', 16, 1);
        RETURN;
    END

    DECLARE @estado_factura VARCHAR(20), @saldo DECIMAL(10,2);
    SELECT @estado_factura = estado FROM FACTURAS WHERE id_factura = @id_factura;

    IF @estado_factura IS NULL
    BEGIN
        RAISERROR('Factura no encontrada.', 16, 1);
        RETURN;
    END
    IF @estado_factura = 'ANULADA'
    BEGIN
        RAISERROR('No se pueden registrar pagos sobre una factura anulada.', 16, 1);
        RETURN;
    END

    SET @saldo = dbo.FN_SALDO_FACTURA(@id_factura);
    IF @monto > @saldo
        BEGIN
            DECLARE @saldoTexto VARCHAR(30);
            SET @saldoTexto = CONVERT(VARCHAR(30), @saldo);

            RAISERROR(
                'El monto excede el saldo pendiente de la factura (%s).',
                16,
                1,
                @saldoTexto
            );

            RETURN;
        END

    BEGIN TRANSACTION;

        INSERT INTO PAGOS (id_factura, monto, forma_pago, numero_referencia, id_usuario_recibe, observaciones)
        VALUES (@id_factura, @monto, @forma_pago, @numero_referencia, @id_usuario_recibe, @observaciones);

        UPDATE FACTURAS
        SET estado = CASE
                        WHEN dbo.FN_SALDO_FACTURA(@id_factura) - @monto <= 0 THEN 'PAGADA'
                        ELSE 'PARCIAL'
                      END
        WHERE id_factura = @id_factura;

    COMMIT TRANSACTION;
        DECLARE @descripcion VARCHAR(300);
        SET @descripcion = CONCAT('Pago de ', @monto, ' registrado sobre factura #', @id_factura);

        EXEC SP_REGISTRAR_AUDITORIA
            @id_usuario = @id_usuario_recibe,
            @modulo = 'PAGOS',
            @accion = 'REGISTRAR_PAGO',
            @tipo_operacion = 'INSERCION',
            @id_registro_afectado = @id_factura,
            @descripcion = @descripcion;
END;
GO

-- ------------------------------------------------------------
-- 3.8 Anular una factura (proceso controlado y auditado)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_ANULAR_FACTURA
    @id_factura     INT,
    @id_usuario     INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @estado VARCHAR(20);
    SELECT @estado = estado FROM FACTURAS WHERE id_factura = @id_factura;

    IF @estado IS NULL
    BEGIN
        RAISERROR('Factura no encontrada.', 16, 1);
        RETURN;
    END
    IF @estado = 'PAGADA'
    BEGIN
        RAISERROR('Una factura pagada no puede anularse; utilice el proceso de reembolso.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
        UPDATE FACTURAS SET estado = 'ANULADA' WHERE id_factura = @id_factura;
    COMMIT TRANSACTION;

    EXEC SP_REGISTRAR_AUDITORIA
        @id_usuario = @id_usuario, @modulo = 'FACTURACION', @accion = 'ANULAR_FACTURA',
        @tipo_operacion = 'ACTUALIZACION', @id_registro_afectado = @id_factura,
        @valores_anteriores = @estado, @valores_nuevos = 'ANULADA', @descripcion = @motivo;
END;
GO

-- ============================================================
-- FIN DEL SCRIPT DE VISTAS, FUNCIONES Y PROCEDIMIENTOS
-- Pendiente:
--   - Triggers (opcional) para auditoria automatica de UPDATE/DELETE
--   - Datos de prueba
--   - Vistas/SP especificos de reportes (paso posterior)
-- ============================================================
