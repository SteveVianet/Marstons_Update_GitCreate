CREATE PROCEDURE GetStoppedLines
(
	@EDISID		INTEGER,
	@StartDate	DATETIME,
	@EndDate	DATETIME,
	@Granularity	INT
)

AS

SET DATEFIRST 1

SELECT	DATEPART(ww, MasterDates.[Date]) AS WeekCommencing,
	Delivery.Product
FROM dbo.MasterDates
JOIN dbo.Delivery ON Delivery.DeliveryID = MasterDates.[ID]
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @StartDate AND @EndDate
AND Sites.EDISID = @EDISID
AND MasterDates.[Date] >= Sites.SiteOnline
AND Delivery.Quantity > 0
AND NOT EXISTS	(SELECT DownloadID
		FROM dbo.DLData
		JOIN dbo.MasterDates AS InnerMasterDates ON DLData.DownloadID = InnerMasterDates.[ID]
		JOIN dbo.Sites ON Sites.EDISID = InnerMasterDates.EDISID
		WHERE InnerMasterDates.[Date] BETWEEN @StartDate AND @EndDate
		AND Sites.EDISID = @EDISID
		AND DLData.Product = Delivery.Product
		AND InnerMasterDates.[Date] >= Sites.SiteOnline
		AND DATEPART(ww, InnerMasterDates.[Date]) = DATEPART(ww, MasterDates.[Date]))
AND EXISTS	(SELECT PumpSetup.ProductID
		FROM dbo.PumpSetup
		WHERE PumpSetup.EDISID = @EDISID
		AND PumpSetup.ProductID = Delivery.Product
		AND PumpSetup.ValidTo IS NULL)
GROUP BY DATEPART(ww, MasterDates.[Date]), Delivery.Product



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetStoppedLines] TO PUBLIC
    AS [dbo];

