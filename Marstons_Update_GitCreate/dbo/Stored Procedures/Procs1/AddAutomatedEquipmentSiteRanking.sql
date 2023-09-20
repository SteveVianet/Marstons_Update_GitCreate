CREATE PROCEDURE dbo.AddAutomatedEquipmentSiteRanking
(
	@EDISID	INT,
	@From		DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

DECLARE @TemperatureAmberValue INT
SET @TemperatureAmberValue = 2

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteInputCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxInput INT NOT NULL)
DECLARE @SiteInputOffsets TABLE(EDISID INT NOT NULL, InputOffset INT NOT NULL)
DECLARE @EquipmentDailyAverages TABLE(EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, InputID INT NOT NULL, ValueTolerance FLOAT NOT NULL, ValueSpecification FLOAT NOT NULL, DailyAverage FLOAT NOT NULL, Ranking VARCHAR(10) NOT NULL)
DECLARE @DaysOutOfSpec FLOAT
DECLARE @DaysInTolerance FLOAT
DECLARE @Ranking INT
DECLARE @EndOfWeek DATETIME

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

INSERT INTO @EquipmentDailyAverages
(EDISID, TradingDate, InputID, ValueTolerance, ValueSpecification, DailyAverage, Ranking)
SELECT  EquipmentReadings.EDISID,
	  CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, EquipmentReadings.TradingDate))),
	  EquipmentReadings.InputID + InputOffset AS InputID,
	  ValueTolerance,
	  ValueSpecification,
	  AVG(EquipmentReadings.Value),
	  CASE WHEN AVG(EquipmentReadings.Value) > (ValueSpecification + ValueTolerance + @TemperatureAmberValue) THEN 'Red'
	            WHEN AVG(EquipmentReadings.Value) > (ValueSpecification + ValueTolerance) THEN 'Amber'
	             ELSE 'Green' END
FROM EquipmentReadings
JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
			  EquipmentItems.InputID = EquipmentReadings.InputID)
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN @SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentReadings.EDISID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentReadings.EDISID
WHERE TradingDate BETWEEN @From AND DATEADD(second, -1, DATEADD(day, 1, @To))
AND EquipmentReadings.Value BETWEEN -10 AND 30
AND EquipmentItems.InUse = 1
GROUP BY EquipmentReadings.EDISID,
	 CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, EquipmentReadings.TradingDate))),
	 EquipmentReadings.InputID + InputOffset,
	 ValueTolerance,
	 ValueSpecification

SELECT @DaysOutOfSpec = SUM(CASE WHEN Ranking = 'Red' THEN 1 ELSE 0 END),
	 @DaysInTolerance = SUM(CASE WHEN Ranking = 'Amber' THEN 1 ELSE 0 END)
FROM @EquipmentDailyAverages

SELECT @Ranking = (CASE
			WHEN @DaysOutOfSpec  > 1 THEN 1
			WHEN @DaysInTolerance >= 2 THEN 2
			WHEN @DaysInTolerance < 2 THEN 3
 			ELSE 6
		          END)
FROM Sites
WHERE EDISID = @EDISID

SET @EndOfWeek =  DATEADD(day, -1, DATEADD(week, DATEDIFF(week, 0, GETDATE()) + 1, 0))

EXEC dbo.AssignSiteRanking @EDISID, @Ranking, '', @EndOfWeek, 7

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAutomatedEquipmentSiteRanking] TO PUBLIC
    AS [dbo];

