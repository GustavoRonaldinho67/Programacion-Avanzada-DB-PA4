USE NovaMarket;
GO

CREATE TABLE HistorialPrecioProducto
(
    HistorialID INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT NOT NULL,
    PrecioAnterior DECIMAL(10,2) NOT NULL,
    PrecioNuevo DECIMAL(10,2) NOT NULL,
    FechaCambio DATETIME NOT NULL DEFAULT GETDATE()
);
GO


-- ACTIVIDAD 1 - DESENCADENANTE
-- Historial de cambios de precio

CREATE TRIGGER trg_HistorialPrecioProducto
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

SELECT ProductoID, Nombre, PrecioLista
FROM Producto
WHERE ProductoID = 1;

UPDATE Producto
SET PrecioLista = 350.00
WHERE ProductoID = 1;

SELECT *
FROM HistorialPrecioProducto;