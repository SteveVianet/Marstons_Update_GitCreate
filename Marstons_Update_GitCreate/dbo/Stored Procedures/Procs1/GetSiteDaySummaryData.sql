---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteDaySummaryData
(
	@StartDate	DATETIME,
	@SiteID		VARCHAR(50)
)

AS

SELECT	Locations.[Description] AS Location,
		PumpSetup.Pump,
		Products.[Description] AS Product,
		DLData.Shift,
		DLData.Quantity
FROM dbo.Sites
JOIN dbo.MasterDates ON MasterDates.EDISID = Sites.EDISID
JOIN dbo.DLData ON DLData.DownloadID = MasterDates.[ID]
JOIN dbo.PumpSetup ON PumpSetup.EDISID = Sites.EDISID AND PumpSetup.Pump = DLData.Pump
JOIN dbo.Locations ON Locations.[ID] = PumpSetup.LocationID
JOIN dbo.Products ON Products.[ID] = PumpSetup.ProductID
WHERE Sites.SiteID = @SiteID
AND MasterDates.[Date] = @StartDate
AND PumpSetup.ValidTo IS NULL
AND DLData.Shift BETWEEN 11 AND 24
ORDER BY Locations.[Description], PumpSetup.Pump


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDaySummaryData] TO PUBLIC
    AS [dbo];

