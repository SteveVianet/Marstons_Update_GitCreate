CREATE PROCEDURE dbo.GetUserTotalsWithMaxVariance
(
	@UserID 	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME,
	@MaxVariance	FLOAT,
	@Tied		BIT	= NULL
)

AS

SELECT	SUM(ISNULL(Dispensed, 0)) AS Dispensed,
	SUM(ISNULL(Delivered, 0)) AS Delivered
FROM
(			SELECT	UserSites.EDISID,
				 	SUM(DLData.Quantity) AS Dispensed
			FROM MasterDates
			JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
			JOIN Products ON DLData.Product = Products.[ID]
			LEFT JOIN SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			JOIN UserSites ON UserSites.EDISID = MasterDates.EDISID
			JOIN Sites ON Sites.EDISID = UserSites.EDISID
			WHERE UserSites.UserID = @UserID
			AND MasterDates.[Date] BETWEEN @From AND @To
			AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
			AND MasterDates.[Date] >= Sites.SiteOnline
			GROUP BY UserSites.EDISID) AS DispensedData
FULL OUTER JOIN 	(SELECT	UserSites.EDISID,
	 				SUM(Delivery.Quantity) AS Delivered
			FROM MasterDates
			JOIN Delivery ON Delivery.DeliveryID = MasterDates.[ID]
			JOIN Products ON Products.[ID] = Delivery.Product
			LEFT JOIN SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
			LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
			JOIN UserSites ON UserSites.EDISID = MasterDates.EDISID
			JOIN Sites ON Sites.EDISID = UserSites.EDISID
			WHERE UserSites.UserID = @UserID
			AND MasterDates.[Date] BETWEEN @From AND @To
			AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
			AND MasterDates.[Date] >= Sites.SiteOnline
			GROUP BY UserSites.EDISID) AS DeliveredData
ON DispensedData.EDISID = DeliveredData.EDISID
JOIN Sites ON COALESCE(DispensedData.EDISID, DeliveredData.EDISID) = Sites.EDISID
WHERE (ISNULL(Delivered, 0) - ISNULL(Dispensed * 0.568 / 4.546, 0)) <= @MaxVariance

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserTotalsWithMaxVariance] TO PUBLIC
    AS [dbo];

