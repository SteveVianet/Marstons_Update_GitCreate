---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteSummaryReport
(
	@EDISID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

SET DATEFIRST 1

SELECT Locations.[ID] AS LocationID,
	DLData.Pump,
	Products.[ID] AS ProductID,
	DATEPART(dw, MasterDates.[Date]) AS [WeekDay],
	SUM(DLData.Quantity) AS Dispensed
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.PumpSetup ON PumpSetup.Pump = DLData.Pump AND MasterDates.EDISID = PumpSetup.EDISID
JOIN dbo.Locations ON Locations.[ID] = PumpSetup.LocationID
JOIN dbo.Products ON Products.[ID] = PumpSetup.ProductID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
AND PumpSetup.ValidTo IS NULL
GROUP BY Locations.[ID], DLData.Pump, Products.[ID], DATEPART(dw, MasterDates.[Date])
ORDER BY Locations.[ID], DLData.Pump, DATEPART(dw, MasterDates.[Date])


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteSummaryReport] TO PUBLIC
    AS [dbo];

