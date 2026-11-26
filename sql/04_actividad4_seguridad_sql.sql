-- ========================================================================================
-- ARCHIVO: sql/04_actividad4_seguridad.sql
-- AUTOR: Mauricio Rojas Arias (@chunchope)
-- OBJETIVO: Actividad 4 - Autenticación SQL, usuarios, roles personalizados bajo el
--           principio de privilegios mínimos y pruebas controladas de acceso.
-- NOTA: Claves exclusivamente de laboratorio local (no son credenciales reales).
-- ========================================================================================

USE master;
GO

-- 1. CREACION DE LOGINS A NIVEL DE SERVIDOR (AUTENTICACION SQL SERVER)
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'login_nm_analista')
    CREATE LOGIN login_nm_analista
        WITH PASSWORD = N'Lab_NovaMarket#2026_A1',
             DEFAULT_DATABASE = NovaMarket,
             CHECK_EXPIRATION = OFF,
             CHECK_POLICY = ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'login_nm_operador')
    CREATE LOGIN login_nm_operador
        WITH PASSWORD = N'Lab_NovaMarket#2026_O2',
             DEFAULT_DATABASE = NovaMarket,
             CHECK_EXPIRATION = OFF,
             CHECK_POLICY = ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'login_nm_auditor')
    CREATE LOGIN login_nm_auditor
        WITH PASSWORD = N'Lab_NovaMarket#2026_U3',
             DEFAULT_DATABASE = NovaMarket,
             CHECK_EXPIRATION = OFF,
             CHECK_POLICY = ON;
GO

-- 2. USUARIOS, ROLES Y PERMISOS EN NovaMarket
USE NovaMarket;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_nm_analista')
    CREATE USER usr_nm_analista FOR LOGIN login_nm_analista;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_nm_operador')
    CREATE USER usr_nm_operador FOR LOGIN login_nm_operador;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_nm_auditor')
    CREATE USER usr_nm_auditor FOR LOGIN login_nm_auditor;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'rol_nm_analista' AND type = 'R')
    CREATE ROLE rol_nm_analista;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'rol_nm_operador' AND type = 'R')
    CREATE ROLE rol_nm_operador;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'rol_nm_auditor' AND type = 'R')
    CREATE ROLE rol_nm_auditor;
GO

-- Perfil 1: Analista Comercial (Solo lectura + consumo de funciones)
GRANT SELECT ON dbo.Cliente TO rol_nm_analista;
GRANT SELECT ON dbo.Categoria TO rol_nm_analista;
GRANT SELECT ON dbo.Producto TO rol_nm_analista;
GRANT SELECT ON dbo.Pedido TO rol_nm_analista;
GRANT SELECT ON dbo.DetallePedido TO rol_nm_analista;
GRANT EXECUTE ON dbo.fn_PrecioActualProducto TO rol_nm_analista;
GRANT SELECT ON dbo.fn_ProductosPorCategoria TO rol_nm_analista;
DENY INSERT, UPDATE, DELETE ON dbo.Producto TO rol_nm_analista;
GO

-- Perfil 2: Operador de Ventas (Registro de ventas y actualización operativa, SIN DELETE ni auditoría)
GRANT SELECT ON dbo.Cliente TO rol_nm_operador;
GRANT SELECT ON dbo.Categoria TO rol_nm_operador;
GRANT SELECT, UPDATE ON dbo.Producto TO rol_nm_operador;
GRANT SELECT, INSERT, UPDATE ON dbo.Pedido TO rol_nm_operador;
GRANT SELECT, INSERT ON dbo.DetallePedido TO rol_nm_operador;
DENY DELETE ON dbo.Producto TO rol_nm_operador;
DENY DELETE ON dbo.Pedido TO rol_nm_operador;
DENY INSERT, UPDATE, DELETE ON dbo.HistorialPrecioProducto TO rol_nm_operador;
GO

-- Perfil 3: Auditor de Precios (Solo lectura de Producto e Historial; sin acceso a Cliente ni escritura)
GRANT SELECT ON dbo.Producto TO rol_nm_auditor;
GRANT SELECT ON dbo.HistorialPrecioProducto TO rol_nm_auditor;
DENY SELECT ON dbo.Cliente TO rol_nm_auditor;
DENY INSERT, UPDATE, DELETE ON dbo.HistorialPrecioProducto TO rol_nm_auditor;
GO

-- Asignación de usuarios a sus roles
ALTER ROLE rol_nm_analista ADD MEMBER usr_nm_analista;
ALTER ROLE rol_nm_operador ADD MEMBER usr_nm_operador;
ALTER ROLE rol_nm_auditor  ADD MEMBER usr_nm_auditor;
GO

-- 3. VERIFICACION DE ROLES Y PERMISOS ASIGNADOS
SELECT
    r.name AS RolBaseDatos,
    u.name AS UsuarioMiembro,
    u.type_desc AS TipoUsuario
FROM sys.database_role_members drm
INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
INNER JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id
WHERE r.name LIKE 'rol_nm_%'
ORDER BY r.name, u.name;

SELECT
    dp.name AS Rol,
    perm.state_desc AS EstadoPermiso,
    perm.permission_name AS Permiso,
    OBJECT_NAME(perm.major_id) AS Objeto
FROM sys.database_permissions perm
INNER JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
WHERE dp.name LIKE 'rol_nm_%'
ORDER BY dp.name, OBJECT_NAME(perm.major_id), perm.permission_name;
GO

-- 4. PRUEBAS CONTROLADAS DE ACCESO (EXECUTE AS USER + TRY/CATCH + REVERT)
SET NOCOUNT ON;

DECLARE @PruebasAcceso TABLE (
    IDPrueba       INT IDENTITY(1,1),
    Usuario        VARCHAR(30),
    AccionProbada  VARCHAR(100),
    Esperado       VARCHAR(15),
    ResultadoReal  VARCHAR(15),
    Detalle        VARCHAR(200)
);

-- Prueba 1: Analista consulta productos (PERMITIDO)
BEGIN TRY
    EXECUTE AS USER = 'usr_nm_analista';
        DECLARE @Cnt1 INT;
        SELECT @Cnt1 = COUNT(*) FROM dbo.Producto;
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_analista', 'SELECT sobre dbo.Producto', 'PERMITIDO', 'PERMITIDO',
            'Lectura exitosa. Productos visibles: ' + CAST(@Cnt1 AS VARCHAR));
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_analista', 'SELECT sobre dbo.Producto', 'PERMITIDO', 'DENEGADO', ERROR_MESSAGE());
END CATCH;

-- Prueba 2: Analista intenta modificar Producto (DENEGADO)
BEGIN TRY
    EXECUTE AS USER = 'usr_nm_analista';
        UPDATE dbo.Producto SET PrecioLista = 999.00 WHERE ProductoID = 2;
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_analista', 'UPDATE sobre dbo.Producto', 'DENEGADO', 'PERMITIDO', 'Fallo de seguridad');
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_analista', 'UPDATE sobre dbo.Producto', 'DENEGADO', 'DENEGADO', ERROR_MESSAGE());
END CATCH;

-- Prueba 3: Operador actualiza Stock en Producto (PERMITIDO)
BEGIN TRY
    EXECUTE AS USER = 'usr_nm_operador';
        UPDATE dbo.Producto SET Stock = Stock WHERE ProductoID = 2;
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_operador', 'UPDATE Stock en dbo.Producto', 'PERMITIDO', 'PERMITIDO',
            'Actualizacion operativa permitida correctamente.');
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_operador', 'UPDATE Stock en dbo.Producto', 'PERMITIDO', 'DENEGADO', ERROR_MESSAGE());
END CATCH;

-- Prueba 4: Operador intenta eliminar un Pedido (DENEGADO)
BEGIN TRY
    EXECUTE AS USER = 'usr_nm_operador';
        DELETE FROM dbo.Pedido WHERE PedidoID = 40;
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_operador', 'DELETE sobre dbo.Pedido', 'DENEGADO', 'PERMITIDO', 'Fallo de seguridad');
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_operador', 'DELETE sobre dbo.Pedido', 'DENEGADO', 'DENEGADO', ERROR_MESSAGE());
END CATCH;

-- Prueba 5: Auditor consulta HistorialPrecioProducto (PERMITIDO)
BEGIN TRY
    EXECUTE AS USER = 'usr_nm_auditor';
        DECLARE @Cnt5 INT;
        SELECT @Cnt5 = COUNT(*) FROM dbo.HistorialPrecioProducto;
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_auditor', 'SELECT sobre dbo.HistorialPrecioProducto', 'PERMITIDO', 'PERMITIDO',
            'Auditoria leida exitosamente. Registros: ' + CAST(@Cnt5 AS VARCHAR));
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_auditor', 'SELECT sobre dbo.HistorialPrecioProducto', 'PERMITIDO', 'DENEGADO', ERROR_MESSAGE());
END CATCH;

-- Prueba 6: Auditor intenta leer datos personales en Cliente (DENEGADO)
BEGIN TRY
    EXECUTE AS USER = 'usr_nm_auditor';
        SELECT TOP 1 * FROM dbo.Cliente;
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_auditor', 'SELECT sobre dbo.Cliente', 'DENEGADO', 'PERMITIDO', 'Fallo de seguridad');
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @PruebasAcceso (Usuario, AccionProbada, Esperado, ResultadoReal, Detalle)
    VALUES ('usr_nm_auditor', 'SELECT sobre dbo.Cliente', 'DENEGADO', 'DENEGADO', ERROR_MESSAGE());
END CATCH;

SELECT
    IDPrueba,
    Usuario,
    AccionProbada,
    Esperado,
    ResultadoReal,
    CASE WHEN Esperado = ResultadoReal THEN 'OK' ELSE 'FALLO' END AS Validacion,
    Detalle
FROM @PruebasAcceso;
GO