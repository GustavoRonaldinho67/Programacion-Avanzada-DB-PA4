-- ========================================================================================
-- ARCHIVO: sql/01_actividad1_trigger.sql
-- AUTOR: Gustavo Muñoz Izquierdo | Revisión QA: Mauricio Rojas Arias
-- OBJETIVO: Actividad 1 - Desencadenante AFTER UPDATE para historial de precios.
-- ========================================================================================

USE NovaMarket;
GO

IF OBJECT_ID('dbo.HistorialPrecioProducto', 'U') IS NULL
BEGIN
    CREATE TABLE HistorialPrecioProducto
    (
        HistorialID INT IDENTITY(1,1) PRIMARY KEY,
        ProductoID INT NOT NULL,
        PrecioAnterior DECIMAL(10,2) NOT NULL,
        PrecioNuevo DECIMAL(10,2) NOT NULL,
        FechaCambio DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_HistorialPrecio_Producto
            FOREIGN KEY (ProductoID) REFERENCES Producto(ProductoID)
    );
END
GO

-- ACTIVIDAD 1 - DESENCADENANTE
-- Historial de cambios de precio
CREATE OR ALTER TRIGGER trg_HistorialPrecioProducto
ON Producto
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(PrecioLista)
    BEGIN
        INSERT INTO HistorialPrecioProducto
        (
            ProductoID,
            PrecioAnterior,
            PrecioNuevo
        )
        SELECT
            d.ProductoID,
            d.PrecioLista,
            i.PrecioLista
        FROM deleted d
        INNER JOIN inserted i
            ON d.ProductoID = i.ProductoID
        WHERE d.PrecioLista <> i.PrecioLista;
    END
END;
GO

-- PRUEBA DE MODIFICACION Y VERIFICACION
SELECT ProductoID, Nombre, PrecioLista
FROM Producto
WHERE ProductoID = 1;

UPDATE Producto
SET PrecioLista = 350.00
WHERE ProductoID = 1;

SELECT *
FROM HistorialPrecioProducto;
GO