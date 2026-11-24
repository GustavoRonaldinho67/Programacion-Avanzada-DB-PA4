USE NovaMarket;
GO


-- ACTIVIDAD 2 = FUNCION ESCALAR
-- Devuelve el precio actual de un producto


CREATE FUNCTION dbo.fn_PrecioActualProducto
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

-- La funcion escalar devuelve un solo valor. En este caso permite obtener el precio actual de un producto segun su ProductoID
-- La funcion escalar es conveniente cuando se necesita obtener o calcular un valor individual


-- ACTIVIDAD 2 = FUNCION DE TIPO TABLA
-- Devuelve productos por categoria


CREATE FUNCTION dbo.fn_ProductosPorCategoria
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

-- La funcion de tipo tabla devuelve un conjunto de registros. En este caso permite consultar todos los productos que pertenecen a una categoria
-- La funcion de tabla es conveniente cuando se necesita reutilizar una consulta que devuelve varias filas y columnas.