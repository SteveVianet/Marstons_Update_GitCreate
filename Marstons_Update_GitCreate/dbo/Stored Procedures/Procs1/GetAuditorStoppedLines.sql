CREATE PROCEDURE [dbo].[GetAuditorStoppedLines]
AS

SET NOCOUNT ON

DECLARE @CustomerID INT
DECLARE @CurrentWeekFrom DATETIME
DECLARE @To DATETIME
DECLARE @TwoWeeksAgoWeekFrom DATETIME
DECLARE @OneWeekAgoSunday DATETIME

SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SET @To = CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, GETDATE())))
SET @CurrentWeekFrom = DATEADD(day, -6, @To)
SET @TwoWeeksAgoWeekFrom = DATEADD(week, -2, @CurrentWeekFrom)
SET @OneWeekAgoSunday = DATEADD(day, -1, @CurrentWeekFrom)

SELECT	@CustomerID AS CustomerID,
		Sites.EDISID, 
		PumpSetup.Pump, 
		PumpSetup.Product
FROM Sites
LEFT JOIN (	SELECT Sites.EDISID, Pump, SUM(Quantity) AS Volume
			FROM DLData
			JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID AND EDISID IN (SELECT EDISID FROM Sites)
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE MasterDates.[Date] BETWEEN @TwoWeeksAgoWeekFrom AND @OneWeekAgoSunday
			GROUP BY Sites.EDISID, Pump
			HAVING SUM(Quantity) >= 4) AS Last2WeeksDispense 
    ON Last2WeeksDispense.EDISID = Sites.EDISID
LEFT JOIN (	SELECT Sites.EDISID, Pump, SUM(Quantity) AS Volume
			FROM DLData
			JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID AND EDISID IN (SELECT EDISID FROM Sites)
			JOIN Sites ON Sites.EDISID = MasterDates.EDISID
			WHERE MasterDates.[Date] BETWEEN @CurrentWeekFrom AND @To
			GROUP BY Sites.EDISID, Pump) AS LastWeeksDispense 
    ON LastWeeksDispense.EDISID = Last2WeeksDispense.EDISID
	AND LastWeeksDispense.Pump = Last2WeeksDispense.Pump
LEFT JOIN ( SELECT EDISID, Pump, ProductID, Products.[Description] AS Product
            FROM PumpSetup
            JOIN Products ON Products.ID = PumpSetup.ProductID
            WHERE InUse = 1
            AND ValidTo IS NULL
        ) AS PumpSetup 
    ON PumpSetup.EDISID = Sites.EDISID
    AND PumpSetup.Pump = Last2WeeksDispense.Pump
WHERE Sites.Hidden = 0
AND Sites.Quality = 1
AND Last2WeeksDispense.Volume IS NOT NULL
AND LastWeeksDispense.Volume IS NULL
AND PumpSetup.Pump IS NOT NULL

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorStoppedLines] TO PUBLIC
    AS [dbo];

