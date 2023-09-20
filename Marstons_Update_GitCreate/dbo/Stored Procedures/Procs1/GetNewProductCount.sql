CREATE PROCEDURE GetNewProductCount
(
	@EDISID		INTEGER,
	@StartDate	DATETIME,
	@EndDate	DATETIME
)

AS

SELECT Delivery.Product
FROM dbo.MasterDates
JOIN dbo.Delivery ON Delivery.DeliveryID = MasterDates.[ID]
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.Products ON Products.[ID] = Delivery.Product
WHERE MasterDates.[Date] BETWEEN @StartDate AND @EndDate
AND Sites.EDISID = @EDISID
AND MasterDates.[Date] >= Sites.SiteOnline
AND Delivery.Quantity > 0
AND Products.IsCask = 0
AND NOT EXISTS	(SELECT DownloadID
		FROM dbo.DLData
		JOIN dbo.MasterDates ON DLData.DownloadID = MasterDates.[ID]
		JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN dbo.Products ON Products.[ID] = Delivery.Product
		WHERE MasterDates.[Date] BETWEEN @StartDate AND @EndDate
		AND Sites.EDISID = @EDISID
		AND DLData.Product = Delivery.Product
		AND MasterDates.[Date] >= Sites.SiteOnline
		AND Products.IsCask = 0)
AND NOT EXISTS	(SELECT PumpSetup.ProductID
		FROM dbo.PumpSetup
		WHERE PumpSetup.EDISID = @EDISID
		AND PumpSetup.ProductID = Delivery.Product
		AND PumpSetup.ValidTo IS NULL)
GROUP BY MasterDates.EDISID, Delivery.Product


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNewProductCount] TO PUBLIC
    AS [dbo];

