---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDispensingNIULines
(
	@EDISID		INTEGER,
	@StartDate	DATETIME,
	@EndDate	DATETIME
)

AS

SELECT PumpSetup.Pump
FROM PumpSetup
JOIN MasterDates ON MasterDates.EDISID = PumpSetup.EDISID
JOIN DLData ON (DLData.Pump = PumpSetup.Pump) AND (MasterDates.[ID] = DLData.DownloadID)
WHERE PumpSetup.ValidTo IS NULL
AND PumpSetup.InUse = 0
AND PumpSetup.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
AND MasterDates.[Date] >= PumpSetup.ValidFrom
GROUP BY PumpSetup.Pump


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispensingNIULines] TO PUBLIC
    AS [dbo];

