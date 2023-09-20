---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ClearDeliveryImportErrors

AS

DELETE FROM dbo.DeliveryImportErrors
WHERE UPPER(UserName) = UPPER(SYSTEM_USER)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ClearDeliveryImportErrors] TO PUBLIC
    AS [dbo];

