CREATE PROCEDURE [dbo].[GetLatestEquipmentLogs]
(
	@EDISID					INT,
	@From					DATETIME,
	@To						DATETIME,
	@EquipmentTypeID		INT = NULL,
	@EquipmentSubTypeID		INT = NULL,
	@ExcludeServiceIssues	BIT = 0
)

AS


--DECLARE	@EDISID					INT = 1819
--DECLARE	@From					DATETIME = '2015-08-06'
--DECLARE	@To						DATETIME = '2015-08-06'
--DECLARE	@EquipmentTypeID		INT = NULL
--DECLARE	@EquipmentSubTypeID		INT = NULL
--DECLARE	@ExcludeServiceIssues	BIT = 1

-- Based ON [GetWebSiteEquipmentLogs]

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteInputCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxInput INT NOT NULL)
DECLARE @SiteInputOffsets TABLE(EDISID INT NOT NULL, InputOffset INT NOT NULL)
DECLARE @SiteOnline DATETIME

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO @SiteInputCounts (EDISID, MaxInput)
SELECT EquipmentItems.EDISID, MAX(InputID)
FROM EquipmentItems
JOIN @Sites AS Sites ON Sites.EDISID = EquipmentItems.EDISID
GROUP BY EquipmentItems.EDISID

INSERT INTO @SiteInputOffsets (EDISID, InputOffset)
SELECT MainCounts.EDISID, ISNULL(SecondaryCounts.MaxInput, 0)
FROM @SiteInputCounts AS MainCounts
LEFT JOIN @SiteInputCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter



SELECT 


    RelevantSites.EDISID,
    EquipmentItems.InputID,
	EquipmentReadings.LogDate,
	EquipmentReadings.TradingDate,
	EquipmentReadings.Value,
	EquipmentItems.HighAlarmThreshold,
	EquipmentItems.LowAlarmThreshold,
	CASE WHEN (EquipmentReadings.Value > EquipmentItems.HighAlarmThreshold OR EquipmentReadings.Value < EquipmentItems.LowAlarmThreshold) THEN 1 ELSE 0 END AS InAlarm
	INTO #TemperatureLogs

FROM EquipmentReadings
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
						EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN @SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentReadings.EDISID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentReadings.EDISID
WHERE TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND TradingDate >= @SiteOnline
AND (EquipmentReadings.EquipmentTypeID = @EquipmentTypeID OR @EquipmentTypeID IS Null)
AND (EquipmentTypes.EquipmentSubTypeID = @EquipmentSubTypeID OR @EquipmentSubTypeID IS Null)
AND EquipmentItems.InUse = 1
GROUP BY 
    RelevantSites.EDISID,
    EquipmentItems.InputID,
	EquipmentReadings.LogDate,
	EquipmentReadings.TradingDate,
	EquipmentReadings.Value,
	EquipmentItems.HighAlarmThreshold,
	EquipmentItems.LowAlarmThreshold
	

-- Get desired equipment logs
SELECT 
EquipmentItems.InputID,
    DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)) AS DateAndTime,
    DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.TradingDate), EquipmentReadings.TradingDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.TradingDate), EquipmentReadings.TradingDate)) AS TradingDateAndTime,
    EquipmentTypes.ID AS EquipmentTypeID,
	EquipmentTypes.[Description] AS EquipmentType,
	EquipmentSubTypes.ID AS EquipmentSubTypeID,
    EquipmentSubTypes.[Description] AS EquipmentSubType,
    Locations.[Description] AS Location,
    LTRIM(RTRIM(EquipmentItems.[Description])) AS [Description],
    ISNULL(AVG(ValueTolerance), 0) AS ValueTolerance,
    ISNULL(((AVG(ValueHighSpecification) - AVG(ValueLowSpecification)) / 2) + AVG(ValueLowSpecification), 0) AS ValueSpecification,
    AVG(EquipmentReadings.Value) AS Value,
    ISNULL(AVG(ValueLowSpecification), 0) AS ValueLowSpecification,
    ISNULL(AVG(ValueHighSpecification), 0) AS ValueHighSpecification,
    ISNULL(AVG(EquipmentItems.LowAlarmThreshold), 0) AS LowAlarmThreshold,
    ISNULL(AVG(EquipmentItems.HighAlarmThreshold), 0) AS HighAlarmThreshold,
	Temperatures.InAlarm AS InAlarmThreshold
    --CASE WHEN (CAST( CONVERT( VARCHAR(8), DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), 108) AS TIME(0)) BETWEEN EquipmentItems.AlarmStartTime AND DATEADD(SECOND, -1, EquipmentItems.AlarmEndTime)) THEN 1 ELSE 0 END AS InAlarmThreshold
FROM EquipmentReadings
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
						EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN @SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentReadings.EDISID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentReadings.EDISID
JOIN #TemperatureLogs AS Temperatures-- @LatestRecords AS LatestRecord 
    ON EquipmentItems.EDISID = Temperatures.EDISID-- LatestRecord.EDISID 
    AND EquipmentItems.[InputID] = Temperatures.InputID-- LatestRecord.[InputID]
    AND [EquipmentReadings].[LogDate] = Temperatures.LogDate-- LatestRecord.[LatestReading]
JOIN EquipmentSubTypes ON EquipmentSubTypes.ID = EquipmentTypes.EquipmentSubTypeID
JOIN Locations ON Locations.ID = EquipmentReadings.LocationID
WHERE EquipmentReadings.TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND EquipmentReadings.TradingDate >= @SiteOnline
AND (EquipmentReadings.EquipmentTypeID = @EquipmentTypeID OR @EquipmentTypeID IS Null)
AND (EquipmentTypes.EquipmentSubTypeID = @EquipmentSubTypeID OR @EquipmentSubTypeID IS Null)
AND EquipmentItems.InUse = 1
AND NOT EXISTS (SELECT ID
	FROM ServiceIssuesEquipment AS sie
	WHERE sie.DateFrom <= EquipmentReadings.TradingDate
	AND (sie.DateTo IS NULL OR sie.DateTo >= EquipmentReadings.TradingDate)
	AND sie.RealEDISID = EquipmentItems.EDISID
	AND sie.InputID = EquipmentItems.InputID
	AND @ExcludeServiceIssues = 1
)
GROUP BY EquipmentItems.InputID,
EquipmentTypes.ID,
EquipmentSubTypes.ID,
		DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)),
		 DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.TradingDate), EquipmentReadings.TradingDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.TradingDate), EquipmentReadings.TradingDate)),
		 EquipmentReadings.InputID + InputOffset,
		 EquipmentReadings.EquipmentTypeID,
		 EquipmentTypes.[Description],
		 EquipmentTypes.EquipmentSubTypeID,
		 EquipmentSubTypes.[Description],
		 Locations.[Description],
		 LTRIM(RTRIM(EquipmentItems.[Description])),
		 EquipmentItems.AlarmStartTime,
		 EquipmentItems.AlarmEndTime,
	Temperatures.InAlarm
ORDER BY DATEADD(Second, -DATEPART(Second, DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)), DATEADD(Minute, -DATEPART(Minute, EquipmentReadings.LogDate), EquipmentReadings.LogDate)) DESC



	DROP TABLE #TemperatureLogs




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLatestEquipmentLogs] TO [fusion]
    AS [dbo];

