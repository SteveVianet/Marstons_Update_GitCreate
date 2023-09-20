CREATE PROCEDURE [dbo].[PeriodCacheCleaningRebuild]

	@From 				DATETIME = NULL,
	@To					DATETIME = NULL,
	@FirstDayOfWeek		INT = 1

AS

DECLARE @EstateReportsEnabled VARCHAR(255)
SELECT @EstateReportsEnabled = PropertyValue
FROM dbo.Configuration
WHERE PropertyName = 'IDraughtEstateReporting'

SET DATEFIRST @FirstDayOfWeek


DELETE FROM PeriodCacheCleaning
WHERE (DispenseWeek BETWEEN dbo.fnGetMonday(@From) AND dbo.fnGetMonday(@To)) OR (@From IS NULL AND @To IS NULL)


--CALCULATE PUMP OFFSETS FOR SECOND SYSTEMS
DECLARE @PrimaryEDISID AS INT
DECLARE @EDISID AS INT
DECLARE @Pumps AS INT
DECLARE @Offset AS INT
DECLARE @IsPrime AS INT
DECLARE @PumpOffsets TABLE(PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE OffsetCursor CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID, ISNULL(MAX(PumpSetup.Pump), 0) AS Pumps, CASE WHEN MAX(PrimaryEDISID) = SiteGroupSites.EDISID THEN 1 ELSE 0 END AS PrimarySite
	FROM(
		SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID--, MAX(Pump) AS Pumps
		FROM SiteGroupSites 
		WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
		AND IsPrimary = 1
		GROUP BY SiteGroupID, SiteGroupSites.EDISID
	) AS PrimarySites
	JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
	LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
	GROUP BY SiteGroupSites.EDISID
	ORDER BY PrimaryEDISID, PrimarySite DESC
OPEN OffsetCursor
WHILE (0=0)
BEGIN
	FETCH NEXT FROM OffsetCursor INTO @PrimaryEDISID, @EDISID, @Pumps, @IsPrime 
	IF @@fetch_status <> 0 BREAK 
	
	IF @IsPrime = 1
	BEGIN
		SET @Offset = 0
	END
	
	INSERT INTO @PumpOffsets
	VALUES(@PrimaryEDISID, @EDISID, @Offset)
	SET @Offset = @Offset + @Pumps

END
CLOSE OffsetCursor
DEALLOCATE OffsetCursor


--BUILD SPEED TABLE
INSERT INTO PeriodCacheCleaning
SELECT EDISID, DispenseDay, CategoryID, SUM(Beer) AS ActiveLines, SUM(CASE Beer WHEN 1 THEN Cleaner ELSE 0 END) AS ActiveLinesCleaned
FROM (
	SELECT ISNULL(PumpOffsets.PrimaryEDISID, Dispense.EDISID) AS EDISID, Pump + ISNULL(PumpOffsets.PumpOffset, 0) AS Pump, DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DispenseDay) + 1, DispenseDay))) AS DispenseDay, CategoryID, MAX(Cleaner) AS Cleaner, MAX(Beer) AS Beer
	FROM(
		SELECT DispenseActions.EDISID, DispenseActions.Pump, CategoryID, DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) AS DispenseDay,
			CASE LiquidType WHEN 3 THEN 1  ELSE 0 END AS Cleaner, 
			CASE LiquidType WHEN 2 THEN 1  ELSE 0 END AS Beer
		FROM DispenseActions
		JOIN Products ON Products.ID = DispenseActions.Product
		JOIN Sites ON Sites.EDISID = DispenseActions.EDISID AND Sites.Quality = 1
		WHERE LiquidType IN (2,3) --Beer or Cleaner 
		AND Products.IsMetric = 0
		--AND CategoryID IN (SELECT ID FROM ProductCategories WHERE ProductCategories.IncludeInEstateReporting = 1)
		AND ((DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL))
		GROUP BY DispenseActions.EDISID, DispenseActions.Pump, DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)), LiquidType, CategoryID
	) AS Dispense
	LEFT JOIN @PumpOffsets AS PumpOffsets ON PumpOffsets.EDISID = Dispense.EDISID
	GROUP BY Dispense.EDISID, PumpOffsets.PrimaryEDISID, Pump, CategoryID, DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DispenseDay) + 1, DispenseDay))), PumpOffsets.PumpOffset
	--ORDER BY Dispense.EDISID, PumpOffsets.PrimaryEDISID, Pump, CategoryID, DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DispenseDay) + 1, DispenseDay))), PumpOffsets.PumpOffset
) AS ActiveLines
GROUP BY EDISID, DispenseDay, CategoryID
--ORDER BY EDISID, DispenseDay, CategoryID


INSERT INTO PeriodCacheCleaning
SELECT  EDISID,
		DispenseDay,
		CategoryID,
		SUM(Beer) AS ActiveLines,
		SUM(CASE Beer WHEN 1 THEN Cleaner ELSE 0 END) AS ActiveLinesCleaned
FROM (
	SELECT  ISNULL(PumpOffsets.PrimaryEDISID, Dispense.EDISID) AS EDISID,
			Pump + ISNULL(PumpOffsets.PumpOffset, 0) AS Pump,
			DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DispenseDay) + 1, DispenseDay))) AS DispenseDay,
			CategoryID,
			MAX(Cleaner) AS Cleaner,
			MAX(Beer) AS Beer
	FROM (
		SELECT  MasterDates.EDISID,
				DLData.Pump,
				ProductCategories.ID AS CategoryID,
				Date AS DispenseDay,
				MAX(CASE WHEN DLData.Quantity > 0 THEN 1 ELSE 0 END) AS Beer,
				MAX(CASE WHEN WaterStack.Volume > 0 THEN 1 ELSE 0 END) AS Cleaner
		FROM MasterDates
		JOIN Sites ON Sites.EDISID = MasterDates.EDISID
		JOIN DLData ON DLData.DownloadID = MasterDates.ID
		LEFT JOIN WaterStack ON (WaterStack.WaterID = MasterDates.ID AND WaterStack.Line = DLData.Pump)
		JOIN Products ON Products.ID = DLData.Product
		JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
		WHERE Sites.Quality = 0
		AND ( (MasterDates.Date BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL) )
		AND Products.IsWater = 0
		AND Products.IsMetric = 0
		--AND ProductCategories.IncludeInEstateReporting = 1
		GROUP BY MasterDates.EDISID, DLData.Pump, ProductCategories.ID, Date
		HAVING ( ISNULL(SUM(WaterStack.Volume),0) = 0 OR SUM(WaterStack.Volume) >= 4 )
	) AS Dispense
	LEFT JOIN @PumpOffsets AS PumpOffsets ON PumpOffsets.EDISID = Dispense.EDISID
	GROUP BY	Dispense.EDISID,
				PumpOffsets.PrimaryEDISID,
				Pump,
				CategoryID,
				DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, DispenseDay) + 1, DispenseDay))),
				PumpOffsets.PumpOffset
) AS ActiveLines
WHERE EDISID NOT IN (SELECT EDISID FROM PeriodCacheCleaning WHERE DispenseWeek BETWEEN dbo.fnGetMonday(@From) AND dbo.fnGetMonday(@To))
GROUP BY EDISID, DispenseDay, CategoryID
--ORDER BY EDISID, DispenseDay, CategoryID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheCleaningRebuild] TO PUBLIC
    AS [dbo];

