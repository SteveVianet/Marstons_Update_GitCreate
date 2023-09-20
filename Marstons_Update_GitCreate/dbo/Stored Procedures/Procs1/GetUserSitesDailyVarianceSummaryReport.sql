CREATE PROCEDURE dbo.GetUserSitesDailyVarianceSummaryReport
(
	@UserID 	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

SET DATEFIRST 1

DECLARE @AllSitesVisible	BIT

SELECT @AllSitesVisible = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

IF @AllSitesVisible = 1
BEGIN
	SELECT COALESCE(DispensedData.[WeekDay], DeliveredData.[WeekDay]) AS [WeekDay],
		ISNULL(Dispensed, 0) AS Dispensed,
		ISNULL(Delivered, 0) AS Delivered,
		ISNULL(Sold, 0) AS Sold
	FROM
		(SELECT	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
			SUM(DLData.Quantity) AS Dispensed
		FROM dbo.MasterDates
		JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
		JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN dbo.Products ON Products.[ID] = DLData.Product
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND Products.IsWater = 0
		GROUP BY DATEPART(dw, MasterDates.[Date])) AS DispensedData
	FULL JOIN
		(SELECT	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
			SUM(Delivery.Quantity) AS Delivered
		FROM dbo.MasterDates
		JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
		JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN dbo.Products ON Products.[ID] = Delivery.Product
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND Products.IsWater = 0
		GROUP BY DATEPART(dw, MasterDates.[Date])) AS DeliveredData
	ON DispensedData.[WeekDay] = DeliveredData.[WeekDay]
	FULL JOIN
		(SELECT	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
			SUM(Sales.Quantity) AS Sold
		FROM dbo.MasterDates
		JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
		JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN dbo.Products ON Products.[ID] = Sales.ProductID
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND Products.IsWater = 0
		GROUP BY DATEPART(dw, MasterDates.[Date])) AS SoldData
	ON DispensedData.[WeekDay] = SoldData.[WeekDay]

END
ELSE
BEGIN
	SELECT COALESCE(DispensedData.[WeekDay], DeliveredData.[WeekDay]) AS [WeekDay],
		ISNULL(Dispensed, 0) AS Dispensed,
		ISNULL(Delivered, 0) AS Delivered,
		ISNULL(Sold, 0) AS Sold
	FROM
		(SELECT	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
			SUM(DLData.Quantity) AS Dispensed
		FROM dbo.MasterDates
		JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
		JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN dbo.UserSites ON UserSites.EDISID = Sites.EDISID
		JOIN dbo.Products ON Products.[ID] = DLData.Product
		WHERE UserSites.UserID = @UserID
		AND MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND Products.IsWater = 0
		GROUP BY DATEPART(dw, MasterDates.[Date])) AS DispensedData
	FULL JOIN
		(SELECT	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
			SUM(Delivery.Quantity) AS Delivered
		FROM dbo.MasterDates
		JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
		JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN dbo.UserSites ON UserSites.EDISID = Sites.EDISID
		JOIN dbo.Products ON Products.[ID] = Delivery.Product
		WHERE UserSites.UserID = @UserID
		AND MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND Products.IsWater = 0
		GROUP BY DATEPART(dw, MasterDates.[Date])) AS DeliveredData
	ON DispensedData.[WeekDay] = DeliveredData.[WeekDay]
	FULL JOIN
		(SELECT	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
			SUM(Sales.Quantity) AS Sold
		FROM dbo.MasterDates
		JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
		JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN dbo.UserSites ON UserSites.EDISID = Sites.EDISID
		JOIN dbo.Products ON Products.[ID] = Sales.ProductID
		WHERE UserSites.UserID = @UserID
		AND MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND Products.IsWater = 0
		GROUP BY DATEPART(dw, MasterDates.[Date])) AS SoldData
	ON DispensedData.[WeekDay] = SoldData.[WeekDay]
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserSitesDailyVarianceSummaryReport] TO PUBLIC
    AS [dbo];

