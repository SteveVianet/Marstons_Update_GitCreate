
CREATE PROCEDURE GetTotalProductSold
(
	@EDISID	INT,
	@ProductID	INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT SUM(Quantity) AS TotalSold
FROM dbo.Sales
JOIN dbo.MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.Sites ON MasterDates.EDISID = Sites.EDISID
WHERE Sites.EDISID = @EDISID
AND Sales.ProductID = @ProductID
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalProductSold] TO PUBLIC
    AS [dbo];

