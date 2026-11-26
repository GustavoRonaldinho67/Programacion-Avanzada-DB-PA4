-- ========================================================================================
-- ARCHIVO: sql/03_actividad3_cursor.sql
-- AUTOR: Mauricio Rojas Arias (@chunchope)
-- OBJETIVO: Actividad 3 - Implementación de un cursor sencillo y evaluación crítica
--           frente a una alternativa basada en conjuntos (set-based).
-- ========================================================================================

USE NovaMarket;
GO

SET NOCOUNT ON;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

/* ========================================================================================
   CASO: Valorización del inventario activo (Stock * PrecioLista) y clasificación de
   reposición por producto (CRITICO <= 12, MODERADO <= 20, OPTIMO > 20).
======================================================================================== */

-- ========================================================================================
-- ENFOQUE 1: CURSOR (RECORRIDO FILA POR FILA - LOCAL FAST_FORWARD)
-- ========================================================================================
PRINT '===============================================================================';
PRINT ' ENFOQUE 1: CONSUMO DE CURSOR (RECORRIDO SECUENCIAL FILA POR FILA)             ';
PRINT '===============================================================================';

DECLARE @ProductoID      INT;
DECLARE @NombreProducto  VARCHAR(80);
DECLARE @Categoria       VARCHAR(50);
DECLARE @Stock           INT;
DECLARE @PrecioLista     DECIMAL(10,2);
DECLARE @ValorInventario DECIMAL(12,2);
DECLARE @EstadoStock     VARCHAR(15);
DECLARE @TotalGeneral    DECIMAL(14,2) = 0;

DECLARE @ResultadoCursor TABLE (
    ProductoID      INT,
    Producto        VARCHAR(80),
    Categoria       VARCHAR(50),
    Stock           INT,
    PrecioLista     DECIMAL(10,2),
    ValorInventario DECIMAL(12,2),
    EstadoStock     VARCHAR(15)
);

-- 1. Declarar cursor
DECLARE cur_ValorizacionInventario CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        p.ProductoID,
        p.Nombre,
        c.Nombre AS Categoria,
        p.Stock,
        p.PrecioLista
    FROM Producto p
    INNER JOIN Categoria c ON p.CategoriaID = c.CategoriaID
    WHERE p.Activo = 1
    ORDER BY p.ProductoID;

-- 2. Abrir cursor
OPEN cur_ValorizacionInventario;

-- 3. Leer primera fila
FETCH NEXT FROM cur_ValorizacionInventario
INTO @ProductoID, @NombreProducto, @Categoria, @Stock, @PrecioLista;

-- 4. Recorrer filas
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @ValorInventario = @Stock * @PrecioLista;
    SET @TotalGeneral = @TotalGeneral + @ValorInventario;

    IF @Stock <= 12
        SET @EstadoStock = 'CRITICO';
    ELSE IF @Stock <= 20
        SET @EstadoStock = 'MODERADO';
    ELSE
        SET @EstadoStock = 'OPTIMO';

    INSERT INTO @ResultadoCursor
        (ProductoID, Producto, Categoria, Stock, PrecioLista, ValorInventario, EstadoStock)
    VALUES
        (@ProductoID, @NombreProducto, @Categoria, @Stock, @PrecioLista, @ValorInventario, @EstadoStock);

    FETCH NEXT FROM cur_ValorizacionInventario
    INTO @ProductoID, @NombreProducto, @Categoria, @Stock, @PrecioLista;
END;

-- 5. Cerrar y liberar memoria
CLOSE cur_ValorizacionInventario;
DEALLOCATE cur_ValorizacionInventario;

SELECT * FROM @ResultadoCursor ORDER BY ProductoID;
SELECT 'CURSOR (Fila por fila)' AS Enfoque, @TotalGeneral AS ValorTotalInventario;
GO

-- ========================================================================================
-- ENFOQUE 2: ALTERNATIVA BASADA EN CONJUNTOS (SET-BASED)
-- ========================================================================================
PRINT '===============================================================================';
PRINT ' ENFOQUE 2: CONSULTA BASADA EN CONJUNTOS (SET-BASED)                           ';
PRINT '===============================================================================';

SELECT
    p.ProductoID,
    p.Nombre AS Producto,
    c.Nombre AS Categoria,
    p.Stock,
    p.PrecioLista,
    CAST(p.Stock * p.PrecioLista AS DECIMAL(12,2)) AS ValorInventario,
    CASE
        WHEN p.Stock <= 12 THEN 'CRITICO'
        WHEN p.Stock <= 20 THEN 'MODERADO'
        ELSE 'OPTIMO'
    END AS EstadoStock
FROM Producto p
INNER JOIN Categoria c ON p.CategoriaID = c.CategoriaID
WHERE p.Activo = 1
ORDER BY p.ProductoID;

SELECT
    'SET-BASED (Conjuntos)' AS Enfoque,
    CAST(SUM(p.Stock * p.PrecioLista) AS DECIMAL(14,2)) AS ValorTotalInventario
FROM Producto p
WHERE p.Activo = 1;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO