-- ========================================================================================
-- ARCHIVO: sql/02_actividad2_funciones.sql
-- AUTOR: Gustavo Muñoz Izquierdo | Revisión QA: Mauricio Rojas Arias
-- OBJETIVO: Actividad 2 - Función escalar y función de tipo tabla en NovaMarket.
-- ========================================================================================

USE NovaMarket;
GO

-- ACTIVIDAD 2 - FUNCION ESCALAR
-- Devuelve el precio actual de un producto (PrecioOferta si existe, sino PrecioLista)
CREATE OR ALTER FUNCTION dbo.fn_PrecioActualProducto
(
    @ProductoID INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Precio DECIMAL(10,2);

    SELECT @Precio =
        CASE
            WHEN PrecioOferta IS NOT NULL
                THEN PrecioOferta
            ELSE PrecioLista
        END
    FROM Producto
    WHERE ProductoID = @ProductoID;

    RETURN @Precio;
END;
GO

SELECT
    ProductoID,
    Nombre,
    PrecioLista,
    PrecioOferta,
    dbo.fn_PrecioActualProducto(ProductoID) AS PrecioActual
FROM Producto;
GO

-- ACTIVIDAD 2 - FUNCION DE TIPO TABLA (INLINE)
-- Devuelve productos filtrados por categoria
CREATE OR ALTER FUNCTION dbo.fn_ProductosPorCategoria
(
    @CategoriaID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        p.ProductoID,
        p.Nombre,
        p.PrecioLista,
        p.PrecioOferta,
        p.Stock
    FROM Producto p
    WHERE p.CategoriaID = @CategoriaID
);
GO

SELECT *
FROM dbo.fn_ProductosPorCategoria(1);
GO