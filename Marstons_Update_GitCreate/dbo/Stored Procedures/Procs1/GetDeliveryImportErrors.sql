---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDeliveryImportErrors

AS

SELECT Message,
	SiteID,
	[Date],
	DeliveryIdent,
	ProductAlias,
	Quantity
FROM dbo.DeliveryImportErrors
WHERE UPPER(UserName) = UPPER(SYSTEM_USER)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveryImportErrors] TO PUBLIC
    AS [dbo];

