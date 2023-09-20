CREATE PROCEDURE [dbo].[GetSiteRawEquipmentLogs]
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME,
	@GroupingInterval		INT,
	@EquipmentTypeID		INT = NULL,
	@MinimumValue		FLOAT = NULL,
	@MaximumValue		FLOAT = NULL
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteInputCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxInput INT NOT NULL)
DECLARE @SiteInputOffsets TABLE(EDISID INT NOT NULL, InputOffset INT NOT NULL)

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

IF @GroupingInterval = 0
BEGIN
	SELECT  EquipmentReadings.EDISID,
		  EquipmentReadings.LogDate AS DateAndTime,
		  EquipmentReadings.TradingDate AS TradingDateAndTime,
		  EquipmentReadings.EquipmentTypeID,
		  0 AS IsDigital,
		  EquipmentReadings.InputID AS SiteInputID,
		  EquipmentReadings.InputID + InputOffset AS InputID,
		  EquipmentReadings.LocationID,
		  EquipmentItems.[Description],
		  EquipmentTypes.[Description] AS EquipmentType,
		  ValueTolerance,
		  ValueSpecification,
		  ISNULL(EquipmentItems.ValueLowSpecification, DefaultLowSpecification) AS ValueLowSpecification,
		  ISNULL(EquipmentItems.ValueHighSpecification, DefaultHighSpecification) AS ValueHighSpecification,
		  EquipmentReadings.Value
	FROM EquipmentReadings
	JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
				  EquipmentItems.InputID = EquipmentReadings.InputID)
	JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
	JOIN @SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentReadings.EDISID
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentReadings.EDISID
	WHERE TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
	AND (EquipmentReadings.EquipmentTypeID = @EquipmentTypeID OR @EquipmentTypeID IS Null)
	AND (EquipmentReadings.Value >= @MinimumValue OR @MinimumValue IS NULL)
	AND (EquipmentReadings.Value <= @MaximumValue OR @MaximumValue IS NULL)
	ORDER BY EquipmentReadings.TradingDate

END
ELSE
BEGIN
-- Note that although we have cleverly hidden the site grouping, we still pass back
-- EDISID and SitePump, so the application can unmask the multi-cellars if required

	SELECT  CAST(STR(DATEPART(year,LogDate),4) + '-' + STR(DATEPART(month,LogDate),LEN(DATEPART(month,LogDate))) + '-' + STR(DATEPART(day,LogDate),LEN(DATEPART(day,LogDate))) + ' ' + STR(DATEPART(hour,LogDate),LEN(DATEPART(hour,LogDate))) + ':' + STR((DATEPART(minute, LogDate)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,LogDate))) + ':00' AS DATETIME) AS DateAndTime,
	   	 CAST(STR(DATEPART(year,TradingDate),4) + '-' + STR(DATEPART(month,TradingDate),LEN(DATEPART(month,TradingDate))) + '-' + STR(DATEPART(day,TradingDate),LEN(DATEPART(day,TradingDate))) + ' ' + STR(DATEPART(hour,TradingDate),LEN(DATEPART(hour,TradingDate))) + ':' + STR((DATEPART(minute, TradingDate)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,TradingDate))) + ':00' AS DATETIME) AS TradingDateAndTime,
		  EquipmentReadings.EquipmentTypeID,
		  0 AS IsDigital,
		  EquipmentReadings.InputID AS SiteInputID,
		  EquipmentReadings.InputID + InputOffset AS InputID,
		  EquipmentReadings.LocationID,
		  EquipmentItems.[Description],
		  EquipmentTypes.[Description] AS EquipmentType,
		  ValueTolerance,
		  ValueSpecification,
		  ISNULL(EquipmentItems.ValueLowSpecification, DefaultLowSpecification) AS ValueLowSpecification,
		  ISNULL(EquipmentItems.ValueHighSpecification, DefaultHighSpecification) AS ValueHighSpecification,
		  SUM(EquipmentReadings.Value) AS TotalValue,
		  AVG(EquipmentReadings.Value) AS AverageValue,
		  MIN(EquipmentReadings.Value) AS MinimumValue,
		  MAX(EquipmentReadings.Value) AS MaximumValue
	FROM EquipmentReadings
	JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
				  EquipmentItems.InputID = EquipmentReadings.InputID)
	JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
	JOIN @SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentReadings.EDISID
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentReadings.EDISID
	WHERE TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
	AND (EquipmentReadings.EquipmentTypeID = @EquipmentTypeID OR @EquipmentTypeID IS Null)
	AND (EquipmentReadings.Value >= @MinimumValue OR @MinimumValue IS NULL)
	AND (EquipmentReadings.Value <= @MaximumValue OR @MaximumValue IS NULL)
	GROUP BY CAST(STR(DATEPART(year,LogDate),4) + '-' + STR(DATEPART(month,LogDate),LEN(DATEPART(month,LogDate))) + '-' + STR(DATEPART(day,LogDate),LEN(DATEPART(day,LogDate))) + ' ' + STR(DATEPART(hour,LogDate),LEN(DATEPART(hour,LogDate))) + ':' + STR((DATEPART(minute, LogDate)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,LogDate))) + ':00' AS DATETIME),
	   	      CAST(STR(DATEPART(year,TradingDate),4) + '-' + STR(DATEPART(month,TradingDate),LEN(DATEPART(month,TradingDate))) + '-' + STR(DATEPART(day,TradingDate),LEN(DATEPART(day,TradingDate))) + ' ' + STR(DATEPART(hour,TradingDate),LEN(DATEPART(hour,TradingDate))) + ':' + STR((DATEPART(minute, TradingDate)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,TradingDate))) + ':00' AS DATETIME),
		      EquipmentReadings.EquipmentTypeID,
		      EquipmentReadings.InputID,
		      EquipmentReadings.InputID + InputOffset,
		      EquipmentReadings.LocationID,
		      EquipmentItems.[Description],
		      EquipmentTypes.[Description],
		      ValueTolerance,
		      ValueSpecification,
		      ISNULL(EquipmentItems.ValueLowSpecification, DefaultLowSpecification),
		      ISNULL(EquipmentItems.ValueHighSpecification, DefaultHighSpecification)

	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteRawEquipmentLogs] TO PUBLIC
    AS [dbo];

