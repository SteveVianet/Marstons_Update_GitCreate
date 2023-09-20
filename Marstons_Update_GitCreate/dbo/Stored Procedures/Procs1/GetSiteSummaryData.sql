---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteSummaryData
(
	@StartDate DATETIME,
	@EndDate DATETIME,
	@SiteID VARCHAR(50)
)

AS

SET DATEFIRST 1

SELECT Locations.[Description] AS Location,
	DLData.Pump,
	Products.[Description] AS Product,
	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
	SUM(DLData.Quantity) AS Dispensed
FROM dbo.Sites
JOIN dbo.MasterDates ON MasterDates.EDISID = Sites.EDISID
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.PumpSetup ON PumpSetup.Pump = DLData.Pump AND Sites.EDISID = PumpSetup.EDISID
JOIN dbo.Locations ON Locations.[ID] = PumpSetup.LocationID
JOIN dbo.Products ON Products.[ID] = PumpSetup.ProductID
WHERE Sites.SiteID = @SiteID
AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
AND PumpSetup.ValidTo IS NULL
GROUP BY Locations.[Description], DLData.Pump, Products.[Description], DATEPART(dw, MasterDates.[Date])
ORDER BY Locations.[Description], DLData.Pump, DATEPART(dw, MasterDates.[Date])


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteSummaryData] TO PUBLIC
    AS [dbo];

