CREATE PROCEDURE dbo.GetUserProductVarianceSummaryReport
(
	@UserID 	INT,
	@ProductID	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Granularity	TINYINT
)

AS

DECLARE @AllSitesVisible	BIT

SET DATEFIRST 1

SELECT @AllSitesVisible = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

IF @AllSitesVisible = 1
BEGIN
	SELECT COALESCE(DispensedData.[Date], DeliveredData.[Date]) AS [Date],
		ISNULL(Dispensed, 0) AS Dispensed,
		ISNULL(Delivered, 0) AS Delivered
	FROM
	(	SELECT DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
			SUM(DLData.Quantity) AS Dispensed
		FROM MasterDates
		JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
		JOIN Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN Products ON Products.[ID] = DLData.Product
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND DLData.Product = @ProductID
		AND Products.Tied = 1
		GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])) AS DispensedData
	FULL JOIN 	(SELECT DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
			SUM(Delivery.Quantity) AS Delivered
			FROM MasterDates
			JOIN Delivery ON MasterDates.[ID] = Delivery.DeliveryID
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID
			JOIN Products ON Products.[ID] = Delivery.Product
			WHERE MasterDates.[Date] BETWEEN @From AND @To
			AND MasterDates.[Date] >= Sites.SiteOnline
			AND Delivery.Product = @ProductID
			AND Products.Tied = 1
			GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])) AS DeliveredData
	ON DispensedData.[Date] = DeliveredData.[Date]
END
ELSE
BEGIN
	SELECT COALESCE(DispensedData.[Date], DeliveredData.[Date]) AS [Date],
		ISNULL(Dispensed, 0) AS Dispensed,
		ISNULL(Delivered, 0) AS Delivered
	FROM
	(	SELECT 	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
			SUM(DLData.Quantity) AS Dispensed
		FROM MasterDates
		JOIN UserSites ON UserSites.EDISID = MasterDates.EDISID
		JOIN Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
		JOIN Products ON Products.[ID] = DLData.Product
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND UserSites.UserID = @UserID
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND DLData.Product = @ProductID
		AND Products.Tied = 1
		GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])) AS DispensedData
	FULL JOIN 	(SELECT DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
			SUM(Delivery.Quantity) AS Delivered
			FROM MasterDates
			JOIN UserSites ON UserSites.EDISID = MasterDates.EDISID
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID
			JOIN Delivery ON MasterDates.[ID] = Delivery.DeliveryID
			JOIN Products ON Products.[ID] = Delivery.Product
			WHERE MasterDates.[Date] BETWEEN @From AND @To
			AND MasterDates.[Date] >= Sites.SiteOnline
			AND UserSites.UserID = @UserID
			AND Delivery.Product = @ProductID
			AND Products.Tied = 1
			GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])) AS DeliveredData
	ON DispensedData.[Date] = DeliveredData.[Date]
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserProductVarianceSummaryReport] TO PUBLIC
    AS [dbo];

