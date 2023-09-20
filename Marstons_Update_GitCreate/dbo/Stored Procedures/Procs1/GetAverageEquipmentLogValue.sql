CREATE PROCEDURE GetAverageEquipmentLogValue
(	@ItemID		INT,
	@From		DATETIME,
	@To		DATETIME,
	@StartTime	DATETIME,
	@EndTime	DATETIME,
	@ValueIndex	INT
)

AS

-- Get average for daily average
SELECT AVG(DailyTotals.TotalDailyLog) AS AverageLogValue
FROM
	(SELECT	CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, LogDate))) AS [Date],
		AVG(EquipmentReadings.Value) AS TotalDailyLog
	FROM dbo.EquipmentReadings
	JOIN dbo.EquipmentItems ON	(EquipmentItems.EDISID = EquipmentReadings.EDISID AND
				EquipmentItems.InputID = EquipmentReadings.InputID AND
				EquipmentItems.InUse = 1)
	WHERE EquipmentItems.[ID] = @ItemID
	AND LogDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
	GROUP BY CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, LogDate)))) AS DailyTotals

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAverageEquipmentLogValue] TO PUBLIC
    AS [dbo];

