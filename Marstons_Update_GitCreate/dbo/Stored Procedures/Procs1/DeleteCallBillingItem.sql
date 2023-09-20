CREATE PROCEDURE [dbo].[DeleteCallBillingItem]
(
	@CallID			INTEGER,
	@BillingItemID	INTEGER
)
AS

DELETE FROM dbo.CallBillingItems
WHERE 
	CallID = @CallID
AND
	CallBillingItems.BillingItemID = @BillingItemID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallBillingItem] TO PUBLIC
    AS [dbo];

