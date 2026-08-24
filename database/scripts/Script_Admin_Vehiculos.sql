/*
  TallerPro - Catálogo de vehículos para Administración
  Ejecutar después de crear la estructura base de la BD.
*/
IF OBJECT_ID('dbo.VEHICULOS_CATALOGO', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.VEHICULOS_CATALOGO (
        id_vehiculo_catalogo INT IDENTITY(1,1) PRIMARY KEY,
        id_marca INT NOT NULL,
        id_modelo INT NOT NULL,
        id_tipo_vehiculo INT NULL,
        id_tipo_combustible INT NOT NULL,
        id_categoria_vehiculo INT NOT NULL,
        activo BIT NOT NULL CONSTRAINT DF_vehiculos_catalogo_activo DEFAULT 1,

        CONSTRAINT FK_catalogo_vehiculo_marca
            FOREIGN KEY (id_marca) REFERENCES dbo.MARCAS_VEHICULO(id_marca),
        CONSTRAINT FK_catalogo_vehiculo_modelo
            FOREIGN KEY (id_modelo) REFERENCES dbo.MODELOS_VEHICULO(id_modelo),
        CONSTRAINT FK_catalogo_vehiculo_tipo
            FOREIGN KEY (id_tipo_vehiculo) REFERENCES dbo.TIPOS_VEHICULO(id_tipo_vehiculo),
        CONSTRAINT FK_catalogo_vehiculo_combustible
            FOREIGN KEY (id_tipo_combustible) REFERENCES dbo.TIPOS_COMBUSTIBLE(id_tipo_combustible),
        CONSTRAINT FK_catalogo_vehiculo_categoria
            FOREIGN KEY (id_categoria_vehiculo) REFERENCES dbo.CATEGORIAS_VEHICULO(id_categoria_vehiculo),

        CONSTRAINT UQ_vehiculos_catalogo_combinacion
            UNIQUE (id_marca, id_modelo, id_tipo_vehiculo, id_tipo_combustible, id_categoria_vehiculo)
    );
END
GO

/* Migra automáticamente las combinaciones que ya existían en VEHICULOS. */
INSERT INTO dbo.VEHICULOS_CATALOGO
    (id_marca,id_modelo,id_tipo_vehiculo,id_tipo_combustible,id_categoria_vehiculo,activo)
SELECT DISTINCT
    v.id_marca,v.id_modelo,v.id_tipo_vehiculo,v.id_tipo_combustible,v.id_categoria_vehiculo,1
FROM dbo.VEHICULOS v
WHERE v.id_marca IS NOT NULL
  AND v.id_modelo IS NOT NULL
  AND v.id_tipo_combustible IS NOT NULL
  AND v.id_categoria_vehiculo IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.VEHICULOS_CATALOGO vc
      WHERE vc.id_marca=v.id_marca
        AND vc.id_modelo=v.id_modelo
        AND ISNULL(vc.id_tipo_vehiculo,-1)=ISNULL(v.id_tipo_vehiculo,-1)
        AND vc.id_tipo_combustible=v.id_tipo_combustible
        AND vc.id_categoria_vehiculo=v.id_categoria_vehiculo
  );
GO

/* Relaciona cada vehículo de cliente con un vehículo del catálogo administrativo.
   Se conserva la información normalizada existente en VEHICULOS para compatibilidad. */
IF COL_LENGTH('dbo.VEHICULOS', 'id_vehiculo_catalogo') IS NULL
BEGIN
    ALTER TABLE dbo.VEHICULOS ADD id_vehiculo_catalogo INT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_vehiculo_catalogo'
      AND parent_object_id = OBJECT_ID('dbo.VEHICULOS')
)
BEGIN
    ALTER TABLE dbo.VEHICULOS
    ADD CONSTRAINT FK_vehiculo_catalogo
        FOREIGN KEY (id_vehiculo_catalogo)
        REFERENCES dbo.VEHICULOS_CATALOGO(id_vehiculo_catalogo);
END
GO

UPDATE v
SET v.id_vehiculo_catalogo = vc.id_vehiculo_catalogo
FROM dbo.VEHICULOS v
INNER JOIN dbo.VEHICULOS_CATALOGO vc
  ON vc.id_marca=v.id_marca
 AND vc.id_modelo=v.id_modelo
 AND ISNULL(vc.id_tipo_vehiculo,-1)=ISNULL(v.id_tipo_vehiculo,-1)
 AND vc.id_tipo_combustible=v.id_tipo_combustible
 AND vc.id_categoria_vehiculo=v.id_categoria_vehiculo
WHERE v.id_vehiculo_catalogo IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_vehiculos_catalogo_activo' AND object_id=OBJECT_ID('dbo.VEHICULOS_CATALOGO'))
    CREATE INDEX IX_vehiculos_catalogo_activo ON dbo.VEHICULOS_CATALOGO(activo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_vehiculos_id_catalogo' AND object_id=OBJECT_ID('dbo.VEHICULOS'))
    CREATE INDEX IX_vehiculos_id_catalogo ON dbo.VEHICULOS(id_vehiculo_catalogo);
GO
