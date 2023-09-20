
CREATE PROCEDURE GetTotalSold
(
	@EDISID		INT,
	@Tied		BIT = NULL,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT SUM(Quantity) AS TotalSold
FROM dbo.Sales
JOIN dbo.MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.Products ON Products.[ID] = Sales.ProductID
LEFT JOIN SiteProductTies ON SiteProductTies.EDISID = @EDISID AND SiteProductTies.ProductID = Products.[ID]
LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE Sites.EDISID = @EDISID
AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalSold] TO PUBLIC
    AS [dbo];

