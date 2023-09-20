CREATE PROCEDURE [dbo].[GetWaterDates]
(
	@EDISID		INTEGER,
	@From			DATETIME = NULL,
	@To			DATETIME = NULL
)

AS



DECLARE @iEDISID AS INTEGER
DECLARE @iFrom AS DATETIME
DECLARE @iTo AS DATETIME

SET @iEDISID = @EDISID
SET @iFrom = @From
SET @iTo = @To


SELECT MD.[Date]
FROM (SELECT ID, EDISID, Date FROM MasterDates WHERE EDISID = @iEDISID) AS MD
JOIN dbo.WaterStack
ON WaterStack.WaterID = MD.[ID]
WHERE (MD.Date >= @iFrom OR @iFrom IS NULL) AND (MD.Date <= @iTo OR @iTo IS NULL)
GROUP BY MD.[Date]
ORDER BY MD.[Date]



--SELECT MasterDates.[Date]
--FROM dbo.WaterStack
--JOIN dbo.MasterDates ON MasterDates.[ID] = WaterStack.WaterID
--WHERE MasterDates.EDISID = @EDISID
--AND (MasterDates.Date >= @From OR @From IS NULL) AND (MasterDates.Date <= @To OR @To IS NULL)
--GROUP BY MasterDates.[Date]
--ORDER BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWaterDates] TO PUBLIC
    AS [dbo];

