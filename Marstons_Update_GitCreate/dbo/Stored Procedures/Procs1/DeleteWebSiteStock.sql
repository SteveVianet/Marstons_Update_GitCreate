CREATE PROCEDURE [dbo].[DeleteWebSiteStock]
(
	@EDISID 		INTEGER, 
	@Date			DATETIME,
	@ProductID		INT
)

AS

SET NOCOUNT ON

DECLARE @MasterDateID		INTEGER

SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

DELETE
FROM dbo.Stock
WHERE MasterDateID = @MasterDateID
AND ProductID = @ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteWebSiteStock] TO PUBLIC
    AS [dbo];

