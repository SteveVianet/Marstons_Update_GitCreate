CREATE PROCEDURE [dbo].[GetStockRecordsForSite]
(
	@EDISID	INTEGER
)

AS

SELECT	Stock.Quantity,
		Stock.Hour,
		Stock.BeforeDelivery,
		Stock.ProductID,
		Stock.MasterDateID,
		MasterDates.[Date]
FROM dbo.Stock
	JOIN MasterDates ON MasterDateID = MasterDates.ID
WHERE EDISID = @EDISID
ORDER BY MasterDates.[Date] DESC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetStockRecordsForSite] TO PUBLIC
    AS [dbo];

