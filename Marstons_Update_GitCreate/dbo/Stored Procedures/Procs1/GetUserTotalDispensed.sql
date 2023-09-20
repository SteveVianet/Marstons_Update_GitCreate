CREATE PROCEDURE dbo.GetUserTotalDispensed
(
	@UserID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Tied		BIT	= NULL
)

AS

SELECT	SUM(DLData.Quantity) AS TotalDispensed
FROM DLData
JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN UserSites ON UserSites.EDISID = MasterDates.EDISID
JOIN Products ON Products.[ID] = DLData.Product
LEFT JOIN SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND UserSites.UserID = @UserID
AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserTotalDispensed] TO PUBLIC
    AS [dbo];

