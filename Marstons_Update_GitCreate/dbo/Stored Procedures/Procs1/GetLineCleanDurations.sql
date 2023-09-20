CREATE PROCEDURE [dbo].[GetLineCleanDurations] 

	@EDISID AS INT,
	@FromDate AS DATETIME,
	@ToDate AS DATETIME,
	@Pump AS INT = 0

AS

SELECT  Sites.EDISID, 
	DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)),
	Pump, 
	MIN(StartTime) AS CleanStarted, MAX(StartTime) AS CleanEnded,
	SUM(Duration) AS DispenseDuration,
	DATEDIFF(mi, MIN(StartTime), MAX(StartTime)) AS SoakTimeMins,
	(DATEDIFF(ss, MIN(StartTime), MAX(StartTime))+SUM(Duration))/60 AS SoakTimeMinsIncDuration 

FROM DispenseActions
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID 
WHERE LiquidType = 3 
AND DispenseActions.EDISID = @EDISID
AND (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) Between @FromDate AND @ToDate)
AND (DispenseActions.Pump = @Pump OR @Pump IS NULL)
GROUP BY Sites.EDISID, DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)), Pump 
ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)), Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLineCleanDurations] TO PUBLIC
    AS [dbo];

