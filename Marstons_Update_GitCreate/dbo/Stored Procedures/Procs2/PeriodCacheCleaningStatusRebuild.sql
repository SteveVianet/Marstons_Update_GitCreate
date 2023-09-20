
CREATE PROCEDURE [dbo].[PeriodCacheCleaningStatusRebuild]
(
	@FromDate	DATETIME = NULL,
	@ToDate		DATETIME = NULL,
	@BuildEDISID	INT = NULL
)
AS

SET DATEFIRST 1
SET NOCOUNT ON

DECLARE	@BuildFrom						DATETIME = dbo.fnGetMonday(@FromDate) -- '2011-07-04'
DECLARE	@BuildTo						DATETIME = @ToDate -- '2012-01-02'
DECLARE @BuildToSunday					DATETIME
DECLARE @EarliestDispense				DATETIME
DECLARE @BuildPrimaryEDISID				INT

DECLARE @EstateReportsEnabled VARCHAR(255)
SELECT @EstateReportsEnabled = PropertyValue
FROM dbo.Configuration
WHERE PropertyName = 'IDraughtEstateReporting'

IF @BuildFrom < '2010-01-04'
BEGIN
	SET @BuildFrom = '2010-01-04'
END

IF @EstateReportsEnabled = '1'
BEGIN

	SET @BuildToSunday = DATEADD(Day, 6, dbo.fnGetMonday(@BuildTo))

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

	--SELECT * FROM @PumpOffsets

	CREATE TABLE #AllSitePumps (PrimaryEDISID INT NOT NULL,
								EDISID INT NOT NULL, 
								PumpID INT NOT NULL,
								RealPumpID INT NOT NULL,
								ProductID INT NOT NULL,
								DaysBeforeAmber INT NOT NULL,
								ValidFrom DATETIME NOT NULL,
								ValidTo DATETIME NOT NULL)

	INSERT INTO #AllSitePumps
	(PrimaryEDISID, EDISID, PumpID, RealPumpID, ProductID, DaysBeforeAmber, ValidFrom, ValidTo)
	SELECT  ISNULL(PumpOffsets.PrimaryEDISID, PumpSetup.EDISID),
			ISNULL(PumpOffsets.EDISID, PumpSetup.EDISID), 
			Pump+ISNULL(PumpOffset,0), 
			PumpSetup.Pump, 
			PumpSetup.ProductID, 
			COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
			ValidFrom, 
			ISNULL(ValidTo, @BuildToSunday)
	FROM PumpSetup
	LEFT JOIN @PumpOffsets AS PumpOffsets ON PumpOffsets.EDISID = PumpSetup.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
	LEFT JOIN SiteSpecifications ON PumpSetup.EDISID = SiteSpecifications.EDISID
	WHERE (ValidFrom <= @BuildToSunday)
	AND PumpSetup.InUse = 1
	AND (ISNULL(ValidTo, @BuildToSunday) >= @BuildFrom)
	AND Products.IsWater = 0
	AND Products.IsMetric = 0

	IF @BuildEDISID IS NOT NULL
	BEGIN
		SELECT @BuildPrimaryEDISID = PrimaryEDISID
		FROM @PumpOffsets
		WHERE EDISID = @BuildEDISID
		
		IF @BuildPrimaryEDISID IS NULL
		BEGIN
			SET @BuildPrimaryEDISID = @BuildEDISID
		END
		
		DELETE FROM #AllSitePumps
		WHERE PrimaryEDISID <> @BuildPrimaryEDISID
	END

	--SELECT * FROM #AllSitePumps

	SELECT @EarliestDispense = DATEADD(DAY, -MAX(DaysBeforeAmber), @BuildFrom)
	FROM #AllSitePumps

	CREATE TABLE #LineCleans (EDISID INT NOT NULL, Pump INT NOT NULL, RealPump INT NOT NULL, ProductID INT NOT NULL, [Date] DATETIME NOT NULL)

	INSERT INTO #LineCleans
	(EDISID, Pump, RealPump, ProductID, [Date])
	SELECT MasterDates.EDISID,
		 SitePumps.PumpID,
		 SitePumps.RealPumpID,
		 SitePumps.ProductID,
		 MasterDates.[Date]
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN #AllSitePumps AS SitePumps
	  ON MasterDates.EDISID = SitePumps.EDISID
	 AND CleaningStack.Line = SitePumps.RealPumpID
	 AND MasterDates.[Date] >= SitePumps.ValidFrom
	 AND (MasterDates.[Date] <= SitePumps.ValidTo OR SitePumps.ValidTo IS NULL)
	WHERE Sites.Quality = 1 AND MasterDates.Date >= @EarliestDispense
	GROUP BY MasterDates.EDISID,
		 SitePumps.PumpID,
		 SitePumps.RealPumpID,
		 SitePumps.ProductID,
		 MasterDates.[Date]

	INSERT INTO #LineCleans
	(EDISID, Pump, RealPump, ProductID, [Date])
	SELECT MasterDates.EDISID,
		SitePumps.PumpID,
		SitePumps.RealPumpID,
		SitePumps.ProductID,
		MasterDates.[Date]
	FROM WaterStack
	JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN #AllSitePumps AS SitePumps 
	  ON MasterDates.EDISID = SitePumps.EDISID
	 AND WaterStack.Line = SitePumps.RealPumpID
	 AND MasterDates.[Date] >= SitePumps.ValidFrom
	 AND (MasterDates.[Date] <= SitePumps.ValidTo OR SitePumps.ValidTo IS NULL)
	WHERE Sites.Quality = 0 AND MasterDates.Date >= @EarliestDispense
	GROUP BY MasterDates.EDISID,
		 SitePumps.PumpID,
		 SitePumps.RealPumpID,
		 SitePumps.ProductID,
		 MasterDates.[Date]
	HAVING SUM(WaterStack.Volume) > 4

	--SELECT * FROM #LineCleans
	
	--SELECT PeriodCacheCleaningStatus.* FROM PeriodCacheCleaningStatus
	DELETE PeriodCacheCleaningStatus FROM PeriodCacheCleaningStatus
	WHERE ((Date BETWEEN dbo.fnGetMonday(@BuildFrom) AND dbo.fnGetMonday(@BuildTo)) OR (@BuildFrom IS NULL AND @BuildTo IS NULL))
	AND ((@BuildPrimaryEDISID IS NULL) OR (@BuildPrimaryEDISID = PeriodCacheCleaningStatus.EDISID))

	----BUILD SPEED TABLE
	INSERT INTO PeriodCacheCleaningStatus
	(EDISID, Date, PumpID, RealPumpID, CleanDays, OverdueCleanDays)
	SELECT EDISID, 
		   DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay) AS Date, 
		   PumpID, 
		   RealPumpID,
		   COUNT(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) < DaysBeforeAmber THEN 1 ELSE NULL END) AS CleanDays,
		   COUNT(CASE WHEN DATEDIFF(DAY, CleanDate, TradingDay) >= DaysBeforeAmber OR CleanDate IS NULL THEN 1 ELSE NULL END) AS DirtyDays
	FROM (
			SELECT ISNULL(DailyPumps.PrimaryEDISID, DailyPumps.EDISID) AS EDISID,
				   DailyPumps.TradingDay,
				   DailyPumps.ProductID,
				   DailyPumps.PumpID,
				   DailyPumps.RealPumpID,
				   DailyPumps.DaysBeforeAmber,
				   MAX(LineCleans.[Date]) AS CleanDate
			FROM 
				(
					SELECT PumpSetup.PrimaryEDISID, PumpSetup.EDISID, PumpSetup.PumpID, PumpSetup.RealPumpID, ProductID, ValidFrom, ValidTo, TradingDay, DaysBeforeAmber
					FROM #AllSitePumps AS PumpSetup
					JOIN Sites ON Sites.EDISID = PumpSetup.EDISID AND Sites.Hidden = 0
					JOIN Products ON Products.ID = PumpSetup.ProductID AND Products.IsMetric = 0 AND Products.IsWater = 0
					JOIN (
						SELECT CalendarDate AS TradingDay
						FROM [SQL1\SQL1].ServiceLogger.dbo.Calendar
						WHERE CalendarDate BETWEEN @BuildFrom AND @BuildToSunday) AS GeneratedDates 
					 ON TradingDay >= ValidFrom
					 AND (TradingDay <= ValidTo OR ValidTo IS NULL)
				) AS DailyPumps
			JOIN Products ON Products.[ID] = DailyPumps.ProductID
			LEFT JOIN #LineCleans AS LineCleans ON LineCleans.EDISID = DailyPumps.EDISID
												AND LineCleans.[Date] <= DailyPumps.TradingDay
												AND LineCleans.Pump = DailyPumps.PumpID
												AND LineCleans.RealPump = DailyPumps.RealPumpID
												AND LineCleans.ProductID = DailyPumps.ProductID
			JOIN Sites ON Sites.EDISID = DailyPumps.EDISID AND Sites.Hidden = 0
			WHERE ((DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay) BETWEEN @BuildFrom AND @BuildToSunday) OR (@BuildFrom IS NULL AND @BuildToSunday IS NULL))
			GROUP BY ISNULL(DailyPumps.PrimaryEDISID, DailyPumps.EDISID),
				   DailyPumps.TradingDay,
				   DailyPumps.ProductID,
				   DailyPumps.PumpID,
				   DailyPumps.RealPumpID,
				   DailyPumps.DaysBeforeAmber
	) AS Dispense
	GROUP BY EDISID, DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay), PumpID, RealPumpID
	ORDER BY EDISID, DATEADD(dd, -DATEPART(dw, TradingDay) + 1, TradingDay), PumpID, RealPumpID

	DROP TABLE #AllSitePumps
	DROP TABLE #LineCleans

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheCleaningStatusRebuild] TO PUBLIC
    AS [dbo];

