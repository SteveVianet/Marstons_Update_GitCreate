CREATE PROCEDURE [dbo].[GetBillingItems]
(
	@BillingItemID	INT = NULL,
	@TypeID			INT = 0
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetBillingItems @BillingItemID, 0, @TypeID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetBillingItems] TO PUBLIC
    AS [dbo];

