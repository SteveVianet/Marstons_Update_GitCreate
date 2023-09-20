CREATE PROCEDURE [dbo].[ProcessIFMLiquidTypes]
(
    @Locale VARCHAR(255) = NULL
)
AS
BEGIN

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @From			DATETIME
DECLARE @To				DATETIME
DECLARE @TestSiteID		VARCHAR(255)
DECLARE @TestPump		INT

SET @From = DATEADD(Day, -7, CAST(CONVERT(VARCHAR(10), GETDATE(), 12) AS DATETIME))
SET @To = DATEADD(Day, -1, CAST(CONVERT(VARCHAR(10), GETDATE(), 12) AS DATETIME))
SET @TestSiteID = NULL
SET @TestPump = NULL

--SET @From = '2011-10-03'
--SET @To = '2011-10-04'
--SET @TestSiteID = '4645'
--SET @TestPump = 3

DECLARE @ThisSiteEDISID					INT
DECLARE @ThisSiteID						VARCHAR(255)
DECLARE @ThisSiteName					VARCHAR(512)
DECLARE @ThisSitePump					INT
DECLARE @Actions						INT
DECLARE @ThisDay						DATETIME
DECLARE @ThisSitePumpIsCask				BIT
DECLARE @ThisSitePumpWaterVol			FLOAT
DECLARE @ThisSitePumpCleanerVol			FLOAT

DECLARE @ThisActionID					INT
DECLARE @NextActionID					INT

DECLARE @ThisActionTime					DATETIME
DECLARE @ThisActionVolume				FLOAT
DECLARE @ThisActionDuration				FLOAT
DECLARE @ThisActionMinCond				INT
DECLARE @ThisActionMaxCond				INT
DECLARE @ThisActionAvTemp				FLOAT
DECLARE @ThisActionLiquid				INT
DECLARE @ThisActionOriginalLiquid		INT
DECLARE @ThisActionLiquidChanged		BIT

DECLARE @StartOfBeerInCleanRange		DATETIME
DECLARE @StartOfBeerInCleanRange2		DATETIME
DECLARE @EndOfBeerInCleanRange			DATETIME
DECLARE @EndOfBeerInCleanRange2			DATETIME
DECLARE @CurrentCleaningDay				DATETIME

DECLARE @EitherSideIsBeer				BIT
DECLARE @NearStartOfClean				BIT
DECLARE @NearEndOfClean					BIT
DECLARE @PreviousIsWaterOrInTrans		BIT
DECLARE @NextIsWater					BIT
DECLARE @PreviousIsCleaner				BIT
DECLARE @NearStartOfWater				BIT
DECLARE @NearCleaner					BIT
DECLARE @NewLiquidType					INT
DECLARE @StartOfClean					DATETIME
DECLARE @EndOfClean						DATETIME
DECLARE @EndOfWater						DATETIME
DECLARE @NumberOfCleanerActions			INT

--******************************************************************************************************
-- IFMLiquidType (algo backup)       : value of LiquidType before this code changed it (or null)
-- LiquidType                        : what IFM, auditor or algorithm thinks liquid type is ('current')
-- OriginalLiquidType (audit backup) : what LiquidType was before manual auditor change


-- *****************************************************************************************************
-- Stage 0
-- Undo any liquid type changes made by this algorithm or the data auditor

/*
UPDATE DispenseActions
SET LiquidType = IFMLiquidType, IFMLiquidType = NULL
FROM DispenseActions
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE (TradingDay BETWEEN @From AND @To)
AND (Sites.SiteID = @TestSiteID OR @TestSiteID IS NULL)
AND (Pump = @TestPump OR @TestPump IS NULL)
AND IFMLiquidType IS NOT NULL
AND Sites.Status <> 9

UPDATE DispenseActions
SET LiquidType = OriginalLiquidType, OriginalLiquidType = NULL
FROM DispenseActions
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE (TradingDay BETWEEN @From AND @To)
AND (Sites.SiteID = @TestSiteID OR @TestSiteID IS NULL)
AND (Pump = @TestPump OR @TestPump IS NULL)
AND OriginalLiquidType IS NOT NULL AND 
AND Sites.Status <> 9
*/

-- *********************************************************************************************
-- Stage 1
-- Attempt to fix outside-of-clean issues (by assuming most stuff on keg lines is beer)

DECLARE curOutsideOfClean CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT  Sites.EDISID,
			SiteID,
			Sites.Name,
			TradingDay,
			Pump,
			COUNT(*),
			IsCask, 
			SUM(CASE WHEN LiquidType = 1 THEN Pints ELSE 0 END), 
			SUM(CASE WHEN LiquidType = 3 THEN Pints ELSE 0 END)
	FROM DispenseActions
	JOIN Products ON Products.ID = DispenseActions.Product
	JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
	LEFT JOIN (
        SELECT SiteProperties.EDISID, SiteProperties.Value AS International
        FROM Properties
        JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
        WHERE Properties.Name = 'International'
        ) AS SiteLocations ON SiteLocations.EDISID = Sites.EDISID	
	WHERE (TradingDay BETWEEN @From AND @To)
	AND (Sites.SiteID = @TestSiteID OR @TestSiteID IS NULL)
	AND Products.IsMetric = 0
	AND Sites.LastDownload > @From
	AND (Pump = @TestPump OR @TestPump IS NULL)
	AND Sites.Status <> 9
	AND ((@Locale IS NOT NULL AND SiteLocations.International = @Locale)
	    OR (@Locale IS NULL))
	GROUP BY	Sites.EDISID, 
				Sites.SiteID, 
				Sites.Name, 
				TradingDay, 
				Pump, 
				Products.IsCask

OPEN curOutsideOfClean
FETCH NEXT FROM curOutsideOfClean INTO @ThisSiteEDISID, @ThisSiteID, @ThisSiteName, @ThisDay, @ThisSitePump, @Actions, @ThisSitePumpIsCask, @ThisSitePumpWaterVol, @ThisSitePumpCleanerVol
WHILE @@FETCH_STATUS = 0
BEGIN

	/*
	PRINT CAST(@ThisSiteEDISID AS VARCHAR) + ', '
			+ @ThisSiteID  + ', '
			+ @ThisSiteName  + ', '
			+ CAST(@ThisDay AS VARCHAR)  + ', '
			+ CAST(@ThisSitePump AS VARCHAR)  + ', '
			+ CAST(@Actions AS VARCHAR)  + ', '
			+ CAST(@ThisSitePumpIsCask  AS VARCHAR)  + ', '
			+ CAST(@ThisSitePumpWaterVol AS VARCHAR)  + ', '
			+ CAST(@ThisSitePumpCleanerVol AS VARCHAR)
	*/

	IF @ThisSitePumpIsCask = 0 AND @ThisSitePumpWaterVol < 1 AND @ThisSitePumpCleanerVol = 0
	BEGIN
		UPDATE DispenseActions
		SET LiquidType = 2, IFMLiquidType = LiquidType
		WHERE EDISID = @ThisSiteEDISID
		AND TradingDay = @ThisDay
		AND Pump = @ThisSitePump
		AND LiquidType = 1
		AND DATEPART(Hour, StartTime) BETWEEN 12 AND 21
	END

	FETCH NEXT FROM curOutsideOfClean INTO @ThisSiteEDISID, @ThisSiteID, @ThisSiteName, @ThisDay, @ThisSitePump, @Actions, @ThisSitePumpIsCask, @ThisSitePumpWaterVol, @ThisSitePumpCleanerVol

END

CLOSE curOutsideOfClean
DEALLOCATE curOutsideOfClean

-- *********************************************************************************************
-- Stage 2
-- Attempt to process the individual actions by site/pump

CREATE TABLE #Actions ( [Order] INT IDENTITY(1,1) PRIMARY KEY,
						[Time] DATETIME NOT NULL,
						Volume FLOAT NOT NULL,
						Duration FLOAT NOT NULL,
						AverageTemperature FLOAT,
						MaximumConductivity INT,
						MinimumConductivity INT,
						IFMLiquid INT NOT NULL,
						LiveLiquid INT,
						LiquidChanged BIT,
						TradingDay DATETIME NOT NULL)

-- Get list of dispense actions to process
--PRINT 'Getting list of sites/pumps to process'
--PRINT 'From ' + CAST(@From AS VARCHAR)
--PRINT 'To ' + CAST(@To AS VARCHAR)

DECLARE curToProcess CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT Sites.EDISID, Sites.SiteID, Sites.Name, Pump, COUNT(*) AS Actions
	FROM DispenseActions
	JOIN Products ON Products.ID = DispenseActions.Product
	JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
    LEFT JOIN (
        SELECT SiteProperties.EDISID, SiteProperties.Value AS International
        FROM Properties
        JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
        WHERE Properties.Name = 'International'
        ) AS SiteLocations ON SiteLocations.EDISID = Sites.EDISID
	WHERE (TradingDay BETWEEN @From AND @To)
	AND (Sites.SiteID = @TestSiteID OR @TestSiteID IS NULL)
	AND Products.IsMetric = 0
	AND Sites.LastDownload > @From
	AND (Pump = @TestPump OR @TestPump IS NULL)
	AND Sites.Status <> 9
	AND ((@Locale IS NOT NULL AND SiteLocations.International = @Locale)
	    OR (@Locale IS NULL))
	GROUP BY Sites.EDISID, Sites.SiteID, Sites.Name, Pump
	HAVING COUNT(*) > 8

--PRINT 'Got list of sites/pumps to process'

OPEN curToProcess
FETCH NEXT FROM curToProcess INTO @ThisSiteEDISID, @ThisSiteID, @ThisSiteName, @ThisSitePump, @Actions
WHILE @@FETCH_STATUS = 0
BEGIN
	-- For this site/pump combination, grab the dispense actions and analyse them
	--   IFMLiquid = IFM or crappy algorithm in AddDispenseCondition procedure
	--   LiveLiquid = Liquid type set by auditor or this code (defaults to IFMLiquid if no change)
	INSERT INTO #Actions
	([Time], Volume, Duration, AverageTemperature, MaximumConductivity, MinimumConductivity, IFMLiquid, LiveLiquid, LiquidChanged, TradingDay)
	SELECT  StartTime,
			Pints,
			Duration,
			AverageTemperature,
			MaximumConductivity,
			MinimumConductivity,
			COALESCE(OriginalLiquidType, LiquidType),
			LiquidType,
			CAST(CASE WHEN OriginalLiquidType = LiquidType OR OriginalLiquidType IS NULL THEN 0 ELSE 1 END AS BIT),
			TradingDay
	FROM DispenseActions
	WHERE EDISID = @ThisSiteEDISID AND TradingDay BETWEEN @From AND @To AND Pump = @ThisSitePump AND LiquidType <> 5
	ORDER BY StartTime
	
	--PRINT 'Checking SiteID ' + @ThisSiteID + ', SiteName ' + @ThisSiteName + ', EDISID ' + CAST(@ThisSiteEDISID AS VARCHAR) + ', Pump ' + CAST(@ThisSitePump AS VARCHAR)
	--IF @ThisSitePump = 7
	--BEGIN
	--	SELECT * FROM #Actions WHERE @ThisSitePump = 7
	--END

	SET @ThisActionID = 1
	SET @NextActionID = 2
	
	WHILE (@ThisActionID IS NOT NULL)
	BEGIN
		-- Process this action
		-- 0=unknown, 1=water, 2=beer, 3=cleaner, 4=intrans, 5=beerclean
		SET @NewLiquidType = NULL

        SELECT  @ThisActionMinCond = MinimumConductivity,
				@ThisActionMaxCond = MaximumConductivity,
				@ThisActionAvTemp = AverageTemperature,
				@ThisActionDuration = Duration,
				@ThisActionTime = [Time],
				@ThisActionVolume = Volume,
				@ThisActionOriginalLiquid = IFMLiquid,
				@ThisActionLiquid = LiveLiquid,
				@ThisActionLiquidChanged = LiquidChanged
        FROM #Actions
        WHERE [Order] = @ThisActionID

		--IF @ThisSitePump = 7
		--BEGIN
		--	PRINT 'Dispense action ' + CAST(@ThisActionID AS VARCHAR) + ' at ' + CAST(@ThisActionTime AS VARCHAR) + ', duration ' + CAST(@ThisActionDuration AS VARCHAR) + ', liquid ' + CAST(@ThisActionLiquid AS VARCHAR) + ',  originalliquid ' + CAST(@ThisActionOriginalLiquid AS VARCHAR) + ',  liquidchanged ' + CAST(@ThisActionLiquidChanged AS VARCHAR)
		--	
		--END
        
        --Note that any records changed by an auditor will not be updated
        --This only applies to cask, as the keg issues will have been covered by stage 1
		--1.       If a record of water less than 1 pint occurs and the record before and after are beer then beer. AND The record are not within 8 dispense actions from liquid type “Cleaner”
        IF (@ThisActionLiquidChanged = 0 AND @ThisActionLiquid = 1 AND @ThisActionVolume < 1.0)
        BEGIN
			-- Are we following a clean?
			SET @NearCleaner = 0
			SELECT @NearCleaner = (CASE WHEN SUM(Volume) > 0 THEN 1 ELSE 0 END)
			FROM #Actions
			WHERE IFMLiquid = 3 AND [Order] BETWEEN (@ThisActionID-8) AND @ThisActionID

			-- Is there lots of beer around?
			SET @EitherSideIsBeer = 0
			SELECT @EitherSideIsBeer = CAST(Minus1IsBeer & Plus1IsBeer AS BIT)
			FROM (
				SELECT  CAST(SUM(CASE WHEN [Order] = (@ThisActionID-1) AND (Volume) > 0 THEN 1 ELSE 0 END) AS BIT) AS Minus1IsBeer,
						CAST(SUM(CASE WHEN [Order] = (@ThisActionID+1) AND (Volume) > 0 THEN 1 ELSE 0 END) AS BIT) AS Plus1IsBeer
				FROM #Actions
				WHERE IFMLiquid = 2 AND [Order] BETWEEN (@ThisActionID-1) AND (@ThisActionID+1)
			) AS AreNearbyActionsBeer

			--PRINT 'Investigating dispense action ' + CAST(@ThisActionID AS VARCHAR) + ' at ' + CAST(@ThisActionTime AS VARCHAR) + ', duration ' + CAST(@ThisActionDuration AS VARCHAR) + ', nearcleaner ' + CAST(@NearCleaner AS VARCHAR) + ', eithersideisbeer ' + CAST(@EitherSideIsBeer AS VARCHAR)
			
			IF (@EitherSideIsBeer = 1 AND @NearCleaner = 0)
			BEGIN
				SET @NewLiquidType = 2
				--PRINT '    Updated dispense action ' + CAST(@ThisActionID AS VARCHAR) + ', was ' + CAST(@ThisActionLiquid AS VARCHAR) + ', now 2'
			
			END
			
        END

		-- All beer inbetween cleaner should be set to cleaner

		--2.       If a record of Beer is within a record [back] of water and next record is water and a record within 5 forward is cleaner then water.
		--3.       If a record of Beer is within a record [back] of cleaner and the next record is water then Water.
        IF (@ThisActionLiquidChanged = 0 AND @ThisActionLiquid IN (0,2))
        BEGIN
			SET @PreviousIsWaterOrInTrans = 0
			SELECT @PreviousIsWaterOrInTrans = (CASE WHEN SUM(Volume) > 0 THEN 1 ELSE 0 END)
			FROM #Actions
			WHERE IFMLiquid IN (1,4) AND [Order] = (@ThisActionID-1)

			SET @NearStartOfClean = 0
			SELECT @NearStartOfClean = (CASE WHEN SUM(Volume) > 0 THEN 1 ELSE 0 END)
			FROM #Actions
			WHERE IFMLiquid = 3 AND [Order] BETWEEN @ThisActionID AND (@ThisActionID+10)

			SET @NearEndOfClean = 0
			SELECT @NearEndOfClean = (CASE WHEN SUM(Volume) > 0 THEN 1 ELSE 0 END)
			FROM #Actions
			WHERE IFMLiquid = 3 AND [Order] BETWEEN (@ThisActionID-10) AND @ThisActionID

			SET @PreviousIsCleaner = 0
			SELECT @PreviousIsCleaner = (CASE WHEN SUM(Volume) > 0 THEN 1 ELSE 0 END)
			FROM #Actions
			WHERE IFMLiquid = 3 AND [Order] = (@ThisActionID-1)

			SET @NearStartOfWater = 0
			SELECT @NearStartOfWater = (CASE WHEN SUM(Volume) > 0 THEN 1 ELSE 0 END)
			FROM #Actions
			WHERE IFMLiquid = 1 AND [Order] BETWEEN @ThisActionID AND (@ThisActionID+10)

			--IF @ThisSitePump = 7
			--BEGIN
			--	PRINT '2) Investigating dispense action ' + CAST(@ThisActionID AS VARCHAR) + ' at ' + CAST(@ThisActionTime AS VARCHAR) + ', duration ' + CAST(@ThisActionDuration AS VARCHAR) + ', liquid ' + CAST(@ThisActionLiquid AS VARCHAR) + ',  originalliquid ' + CAST(@ThisActionOriginalLiquid AS VARCHAR) + ',  liquidchanged ' + CAST(@ThisActionLiquidChanged AS VARCHAR) + ', @PreviousIsWater ' + CAST(@PreviousIsWaterOrInTrans AS VARCHAR) + ', @NearStartOfClean ' + CAST(@NearStartOfClean AS VARCHAR) + ', @PreviousIsCleaner ' + CAST(@PreviousIsCleaner AS VARCHAR) + ', @NearStartOfWater ' + CAST(@NearStartOfWater AS VARCHAR) + ', @NearEndOfClean ' + CAST(@NearEndOfClean AS VARCHAR)
			--END
			
			IF ( (@ThisActionOriginalLiquid = 2 OR @ThisActionOriginalLiquid = 0) AND (@PreviousIsCleaner = 1) AND (@NearStartOfClean = 1) )
				OR
			   ( (@ThisActionOriginalLiquid = 0) AND (@NearStartOfClean = 1) )
			
			BEGIN
				-- Change weakly mixed cleaner (beer) to cleaner
				-- Change super-mixed cleaner (unknown, since conductivity = 0) to cleaner
				SET @NewLiquidType = 3

			END				
			ELSE
			BEGIN
				-- a) beginning of clean... previous=water, cleaner in front
				-- b) end of clean......... previous=cleaner, water in front
				-- c) end of clean 2....... previous=water, water in front, cleaner behind
				IF (@PreviousIsWaterOrInTrans = 1 AND @NearStartOfClean = 1) OR
				   (@PreviousIsCleaner = 1 AND @NearStartOfWater = 1) OR
				   (@PreviousIsWaterOrInTrans = 1 AND @NearStartOfWater = 1 AND @NearEndOfClean = 1)
				BEGIN
					SET @NewLiquidType = 1

				END
			
			END
        
        END

		-- Do we need to make an update as a result of the rules above?
		IF (@NewLiquidType IS NOT NULL)
		BEGIN
			UPDATE DispenseActions
			SET IFMLiquidType = @ThisActionLiquid, LiquidType = @NewLiquidType
			WHERE EDISID = @ThisSiteEDISID AND Pump = @ThisSitePump AND StartTime = @ThisActionTime
			
			UPDATE #Actions
			SET IFMLiquid = @NewLiquidType
			WHERE [Order] = @ThisActionID

			--PRINT 'SiteID ' + @ThisSiteID + ', SiteName ' + @ThisSiteName + ', EDISID ' + CAST(@ThisSiteEDISID AS VARCHAR) + ', Pump ' + CAST(@ThisSitePump AS VARCHAR)
			--PRINT '    (2) Updated dispense action ' + CAST(@ThisActionID AS VARCHAR) + ', time ' + CAST(@ThisActionTime AS VARCHAR) + ' was ' + CAST(@ThisActionLiquid AS VARCHAR) + ', now 1'
			
			INSERT INTO [ProcessIFMLiquidTypesLog]
			(EDISID, Pump, DispenseTime, OldLiquidType, NewLiquidType, LogText)
			VALUES
			(@ThisSiteEDISID, @ThisSitePump, @ThisActionTime, @ThisActionLiquid, @NewLiquidType, 'Stage 2 fix')

		END

		-- Find next action to process
		SET @ThisActionID = NULL
		SELECT @ThisActionID = MIN([Order])
		FROM #Actions
		WHERE [Order] >= @NextActionID

		SET @NextActionID = @ThisActionID + 1

	END
	
	-- *********************************************************************************************
	-- Stage 3
	-- Fixing is now complete, so have a bash at beer in clean
	-- No need to re-build stacks, since Beer and BeerInClean both go into DLData
	
	DECLARE curCleaningDays CURSOR FORWARD_ONLY READ_ONLY FOR
		SELECT TradingDay
		FROM #Actions
		WHERE IFMLiquid = 3
		GROUP BY TradingDay

	OPEN curCleaningDays
	FETCH NEXT FROM curCleaningDays INTO @CurrentCleaningDay
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @NumberOfCleanerActions = 0
		
		SELECT  @StartOfClean = MIN(Time),
				@EndOfClean = MAX(Time),
				@NumberOfCleanerActions = COUNT(*)
		FROM #Actions
		WHERE TradingDay = @CurrentCleaningDay AND IFMLiquid = 3

		-- Only attempt beer in clean if whole cleaning cycle is reasonable length
		-- We do not want to try if there are, say, two cleans per day
		IF DATEDIFF(Hour, @StartOfClean, @EndOfClean) < 4
		BEGIN
			SET @EndOfWater = @StartOfClean
			
			-- Determine end of cleaning time:
			--   25 mins from start of clean
			--   15 mins from end of water (within 1 hour of clean), or 30 mins from end of clean
			-- Then use wider range (-35 mins, +30 mins), but only if volume is > 1.2 pints
			SELECT  @EndOfWater = MAX(Time)
			FROM #Actions
			WHERE TradingDay = @CurrentCleaningDay
				AND IFMLiquid = 1
				AND (Time BETWEEN @EndOfClean AND DATEADD(Hour, 1, @EndOfClean))
			
			SET @StartOfBeerInCleanRange = DATEADD(Minute, -25, @StartOfClean)
			SET @EndOfBeerInCleanRange = CASE WHEN @EndOfWater > @EndOfClean THEN DATEADD(Minute, 15, @EndOfWater) ELSE DATEADD(Minute, 30, @EndOfClean) END

			SET @StartOfBeerInCleanRange2 = DATEADD(Minute, -35, @StartOfBeerInCleanRange)
			SET @EndOfBeerInCleanRange2 = DATEADD(Minute, 30, @EndOfBeerInCleanRange)

			--PRINT 'SiteID ' + @ThisSiteID + ', SiteName ' + @ThisSiteName + ', EDISID ' + CAST(@ThisSiteEDISID AS VARCHAR) + ', Pump ' + CAST(@ThisSitePump AS VARCHAR)
			--PRINT '    (BeerInClean) CurrentCleaningDay ' + CAST(@CurrentCleaningDay AS VARCHAR)
			--PRINT '    (BeerInClean) StartOfClean ' + CAST(@StartOfClean AS VARCHAR) + ', EndOfClean ' + CAST(@EndOfClean AS VARCHAR) + ' EndOfWater ' + CAST(@EndOfWater AS VARCHAR)
			--PRINT '    (BeerInClean) StartOfBeerInCleanRange ' + CAST(@StartOfBeerInCleanRange AS VARCHAR) + ', EndOfBeerInCleanRange ' + CAST(@EndOfBeerInCleanRange AS VARCHAR)
			--PRINT '    (BeerInClean) StartOfBeerInCleanRange2 ' + CAST(@StartOfBeerInCleanRange2 AS VARCHAR) + ', EndOfBeerInCleanRange2 ' + CAST(@EndOfBeerInCleanRange2 AS VARCHAR)

			UPDATE DispenseActions
			SET IFMLiquidType = LiquidType, LiquidType = 5
			WHERE EDISID = @ThisSiteEDISID
			AND TradingDay = @CurrentCleaningDay
			AND Pump = @ThisSitePump
			AND ( 
					( StartTime BETWEEN @StartOfBeerInCleanRange AND @EndOfBeerInCleanRange ) 
			         OR
			        ( (StartTime BETWEEN @StartOfBeerInCleanRange2 AND @EndOfBeerInCleanRange2) AND Pints > 1.2 )
			    )
			AND LiquidType = 2
			AND OriginalLiquidType IS NULL
			
			DECLARE @FirstBeerInClean	DATETIME
			DECLARE @LastBeerInClean	DATETIME

			SELECT @FirstBeerInClean = MIN(StartTime), @LastBeerInClean = MAX(StartTime)
			FROM DispenseActions
			WHERE EDISID = @ThisSiteEDISID
			AND TradingDay = @CurrentCleaningDay
			AND Pump = @ThisSitePump
			AND LiquidType = 5
			AND OriginalLiquidType IS NULL
			
			--PRINT '    (BeerInClean) FirstBeerInClean ' + CAST(@FirstBeerInClean AS VARCHAR) + ', LastBeerInClean ' + CAST(@LastBeerInClean AS VARCHAR)

			UPDATE DispenseActions
			SET IFMLiquidType = LiquidType, LiquidType = 5
			WHERE EDISID = @ThisSiteEDISID
			AND TradingDay = @CurrentCleaningDay
			AND StartTime BETWEEN @FirstBeerInClean AND @LastBeerInClean
			AND Pump = @ThisSitePump
			AND LiquidType = 2
			AND OriginalLiquidType IS NULL
			
		END

		FETCH NEXT FROM curCleaningDays INTO @CurrentCleaningDay
		
	END

	CLOSE curCleaningDays
	DEALLOCATE curCleaningDays

	DELETE FROM #Actions
	
	FETCH NEXT FROM curToProcess INTO @ThisSiteEDISID, @ThisSiteID, @ThisSiteName, @ThisSitePump, @Actions

END

DROP TABLE #Actions

CLOSE curToProcess
DEALLOCATE curToProcess

-- *********************************************************************************************
-- Stage 4
-- All DLData/WaterStack/CleanerStack changes are sorted, so re-build legacy tables.
-- *** This has been moved to a separate job!

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ProcessIFMLiquidTypes] TO PUBLIC
    AS [dbo];

