CREATE PROCEDURE [dbo].[GetWebSiteStockByDate]
(
	@EDISID 		INTEGER, 
	@Date			DATETIME
)

AS

SET NOCOUNT ON

DECLARE @MasterDateID		INTEGER

SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

SELECT MasterDates.EDISID,
	   MasterDates.[Date],
	   Quantity,
	   Hour,
	   BeforeDelivery,
	   ProductID,
	   Products.[Description] AS Product
FROM dbo.Stock
JOIN MasterDates ON MasterDates.[ID] = Stock.MasterDateID
JOIN Products ON Products.[ID] = Stock.ProductID
WHERE MasterDateID = @MasterDateID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteStockByDate] TO PUBLIC
    AS [dbo];

