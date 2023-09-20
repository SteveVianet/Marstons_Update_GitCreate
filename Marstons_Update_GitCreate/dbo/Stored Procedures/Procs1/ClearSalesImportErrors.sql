
CREATE PROCEDURE ClearSalesImportErrors

AS

DELETE FROM dbo.SalesImportErrors
WHERE UPPER(UserName) = UPPER(SYSTEM_USER)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ClearSalesImportErrors] TO PUBLIC
    AS [dbo];

