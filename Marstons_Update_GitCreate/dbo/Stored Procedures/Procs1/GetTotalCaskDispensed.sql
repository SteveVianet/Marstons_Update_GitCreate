---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetTotalCaskDispensed]
(
	@EDISID	INT,
	@From		DATETIME,
	@To		DATETIME,
	@Tied		BIT = NULL
)

AS

SELECT SUM(Quantity)  AS TotalDispensed
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.[ID] = DLData.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = @EDISID AND SiteProductTies.ProductID = Products.[ID]
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE Sites.EDISID = @EDISID
AND Products.IsCask = 1
AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalCaskDispensed] TO PUBLIC
    AS [dbo];

