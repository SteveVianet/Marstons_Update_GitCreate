CREATE PROCEDURE dbo.GetTotalNegativeVarianceByArea
(
	@AreaID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

SET DATEFIRST 1

SELECT	SUM(ISNULL(Delivered / 0.568 * 4.546, 0)) - SUM(ISNULL(Dispensed, 0)) AS TotalNegativeVariance
FROM (
			SELECT	Sites.EDISID,
			 	SUM(DLData.Quantity) AS Dispensed
			FROM dbo.MasterDates
			JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
			JOIN dbo.Products ON Products.[ID] = DLData.Product
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE Sites.AreaID = @AreaID
			AND MasterDates.[Date] BETWEEN @From AND @To
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY Sites.EDISID) AS DispensedData
FULL OUTER JOIN 	(SELECT	Sites.EDISID,
			 	SUM(Delivery.Quantity) AS Delivered
			FROM dbo.MasterDates
			JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
			JOIN dbo.Products ON Products.[ID] = Delivery.Product
			LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE Sites.AreaID = @AreaID
			AND MasterDates.[Date] BETWEEN @From AND @To
			AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
			GROUP BY Sites.EDISID) AS DeliveredData
ON DispensedData.EDISID = DeliveredData.EDISID
WHERE ISNULL(Dispensed, 0) > ISNULL(Delivered / 0.568 * 4.546, 0)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalNegativeVarianceByArea] TO PUBLIC
    AS [dbo];

