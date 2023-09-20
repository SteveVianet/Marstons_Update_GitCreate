---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetWaterDispensedBySchedule
(
	@ScheduleID	INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

DECLARE @ScheduleName VARCHAR(255)

CREATE TABLE #Sites(EDISID INT NOT NULL)

SET NOCOUNT ON

--Get name of schedule
SELECT @ScheduleName = [Description]
FROM Schedules
WHERE [ID] = @ScheduleID

--Determine if schedule is dynamic
IF LEFT(@ScheduleName, 1) = '£' OR LEFT(@ScheduleName, 1) = '$'
BEGIN
	--Schedule is dynamic so we need a special method to get sites
	DECLARE @Field VARCHAR(255)
	DECLARE @Value VARCHAR(255)

	SET @Field = SUBSTRING(LEFT(@ScheduleName, CHARINDEX('=', @ScheduleName)-1), 2, 255)

	SET @Value = SUBSTRING(@ScheduleName, CHARINDEX('=', @ScheduleName)+1, 255)
	SET @Value = LEFT(@Value, CHARINDEX(':', @Value)-1)

	INSERT INTO #Sites
	(EDISID)
	EXEC GetDynamicSites @Field, @Value
END
ELSE
BEGIN
	--Get sites the easy way
	INSERT INTO #Sites
	(EDISID)
	SELECT EDISID
	FROM ScheduleSites
	WHERE ScheduleID = @ScheduleID
END

--Get water data
SELECT	Sites.EDISID,
	MasterDates.[Date],
	SUM(DLData.Quantity) AS Quantity
FROM #Sites AS Sites
JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID
JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
JOIN Products ON Products.[ID] = DLData.Product
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND Products.IsWater = 1
GROUP BY Sites.EDISID, MasterDates.[Date]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWaterDispensedBySchedule] TO PUBLIC
    AS [dbo];

