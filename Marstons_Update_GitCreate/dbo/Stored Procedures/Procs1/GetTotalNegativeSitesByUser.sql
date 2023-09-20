CREATE PROCEDURE dbo.GetTotalNegativeSitesByUser
(
	@UserID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@MaxVariance	FLOAT = 0
)

AS

SELECT	COUNT(*) AS TotalNegativeSites
FROM (
			SELECT	UserSites.EDISID,
			 	SUM(DLData.Quantity) AS Dispensed
			FROM dbo.MasterDates
			JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
			JOIN dbo.Products ON Products.[ID] = DLData.Product
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			JOIN dbo.UserSites ON UserSites.EDISID = MasterDates.EDISID
			WHERE UserSites.UserID = @UserID
			AND MasterDates.[Date] BETWEEN @From AND @To
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY UserSites.EDISID) AS DispensedData
FULL OUTER JOIN 	(SELECT	UserSites.EDISID,
			 	SUM(Delivery.Quantity) AS Delivered
			FROM dbo.MasterDates
			JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
			JOIN dbo.Products ON Products.[ID] = Delivery.Product
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			JOIN dbo.UserSites ON UserSites.EDISID = MasterDates.EDISID
			WHERE UserSites.UserID = @UserID
			AND MasterDates.[Date] BETWEEN @From AND @To
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY UserSites.EDISID) AS DeliveredData
ON DispensedData.EDISID = DeliveredData.EDISID
WHERE (ISNULL(Delivered, 0) - ISNULL(Dispensed * 0.568 / 4.546, 0)) <= @MaxVariance




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalNegativeSitesByUser] TO PUBLIC
    AS [dbo];

