CREATE PROCEDURE [dbo].[AutoFixSiteDispenseActions]
(
	@EDISID		INT,
	@From		DATE,
	@To			DATE

)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @ThisDay						DATETIME
DECLARE @ThisSiteTap					INT
DECLARE @Actions						INT
DECLARE @ThisSiteTapIsCask				BIT
DECLARE @ThisSiteTapWaterVol			FLOAT
DECLARE @ThisSiteTapCleanerVol			FLOAT

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

DECLARE @PreviousIsWater				BIT
DECLARE @PreviousPreviousIsWater		BIT
DECLARE @PreviousWaterTime				DATETIME

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

DECLARE @SiteIsUS						BIT
DECLARE @SiteIsiDraught					BIT

-- This must only run for iDraught systems (currently iDraughtPanel system type and now GW3 )
SELECT @SiteIsiDraught = CASE WHEN SystemTypeID = 8 or SystemTypeID = 10 THEN 1 ELSE 0 END
FROM Sites
WHERE EDISID = @EDISID

IF @SiteIsiDraught = 0
BEGIN
	RETURN
	
END

-- And we have rule variations for the USA (of course!)
SELECT @SiteIsUS = CASE WHEN SiteProperties.Value = 'en-US' THEN 1 ELSE 0 END
FROM Properties
JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
WHERE Properties.Name = 'International'
AND SiteProperties.EDISID = @EDISID

-- *********************************************************************************************
-- Stage 1
-- Attempt to fix outside-of-clean issues (by assuming most stuff on keg lines is beer)

IF @SiteIsUS = 0
BEGIN
	DECLARE curOutsideOfClean CURSOR FORWARD_ONLY READ_ONLY FOR
		SELECT  TradingDay,
				Pump,
				COUNT(*),
				IsCask, 
				SUM(CASE WHEN LiquidType = 1 THEN Pints ELSE 0 END), 
				SUM(CASE WHEN LiquidType = 3 THEN Pints ELSE 0 END)
		FROM DispenseActions
		JOIN Products ON Products.ID = DispenseActions.Product
		WHERE EDISID = @EDISID
		AND (TradingDay BETWEEN @From AND @To)
		AND Products.IsMetric = 0
		GROUP BY	TradingDay, 
					Pump, 
					Products.IsCask

	OPEN curOutsideOfClean
	FETCH NEXT FROM curOutsideOfClean INTO @ThisDay, @ThisSiteTap, @Actions, @ThisSiteTapIsCask, @ThisSiteTapWaterVol, @ThisSiteTapCleanerVol
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ThisSiteTapIsCask = 0 AND @ThisSiteTapWaterVol < 1 AND @ThisSiteTapCleanerVol = 0
		BEGIN
			UPDATE DispenseActions
			SET LiquidType = 2, IFMLiquidType = LiquidType
			WHERE EDISID = @EDISID
			AND TradingDay = @ThisDay
			AND Pump = @ThisSiteTap
			AND LiquidType = 1
			AND DATEPART(Hour, StartTime) BETWEEN 12 AND 21
		END

		FETCH NEXT FROM curOutsideOfClean INTO @ThisDay, @ThisSiteTap, @Actions, @ThisSiteTapIsCask, @ThisSiteTapWaterVol, @ThisSiteTapCleanerVol

	END

	CLOSE curOutsideOfClean
	DEALLOCATE curOutsideOfClean

END


-- *********************************************************************************************
-- Stage 2
-- Attempt to process the individual actions by tap
-- All non-metric taps, where we have >8 pours

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

DECLARE curTapsToProcess CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT Pump, COUNT(*) AS Actions
	FROM DispenseActions
	JOIN Products ON Products.ID = DispenseActions.Product
	WHERE EDISID = @EDISID
	AND (TradingDay BETWEEN @From AND @To)
	AND Products.IsMetric = 0
	GROUP BY Pump
	HAVING COUNT(*) > 6

OPEN curTapsToProcess
FETCH NEXT FROM curTapsToProcess INTO @ThisSiteTap, @Actions
WHILE @@FETCH_STATUS = 0
BEGIN
	-- For this site/tap combination, grab the dispense actions and analyse them
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
	WHERE EDISID = @EDISID
			AND TradingDay BETWEEN @From AND @To
			AND Pump = @ThisSiteTap
			AND LiquidType <> 5		-- ignore beer-in-clean
	ORDER BY StartTime
	
	SET @ThisActionID = 1
	SET @NextActionID = 2
	
	WHILE (@ThisActionID IS NOT NULL)
	BEGIN
		-- Process this action
		-- 0=unknown, 1=water, 2=beer, 3=cleaner, 4=intrans, 5=beerclean
		SET @NewLiquidType = NULL
		
		-- For water, track the history
		-- Note that because we are just before the select from #Actions, 'this' means 'previous'!
		IF @ThisActionOriginalLiquid = 1
		BEGIN
			SET @PreviousIsWater = 1
			
		END
		ELSE
		BEGIN
			SET @PreviousIsWater = 0
		
		END
		
		IF @PreviousIsWater = 1
		BEGIN
			SET @PreviousWaterTime = @ThisActionTime

		END

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

		SELECT @PreviousPreviousIsWater = (CASE WHEN SUM(Volume) > 0 THEN 1 ELSE 0 END)
		FROM #Actions
		WHERE IFMLiquid = 1 AND [Order] = (@ThisActionID-2)

        -- Note that any records changed by an auditor will not be updated
        -- This MAY only apply to cask, as the keg issues MAY have been covered by stage 1
		
		-- 1. If a record of water less than 1 pint occurs
		--    and the record before and after are beer
		--    and the records are not within 8 dispense actions from Cleaner
		--    ...then beer
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

			IF (@EitherSideIsBeer = 1 AND @NearCleaner = 0)
			BEGIN
				SET @NewLiquidType = 2
			
			END
			
        END
        
        -- 1b. For US only, try to identify keg changes
        --     If >1 consecutive water, AND BEER WITHIN 120 SECONDS!!! then change next beer to beer-in-clean
        IF (@SiteIsUS = 1
			AND @ThisActionLiquidChanged = 0
			AND @ThisActionLiquid = 2
			AND @PreviousIsWater = 1
			AND @PreviousPreviousIsWater = 1
			AND DATEDIFF(SECOND, @PreviousWaterTime, @ThisActionTime) <= 120)
        BEGIN
			SET @NewLiquidType = 5
        
        END
        
		-- All beer inbetween cleaner should be set to cleaner

		-- 2. If a record of Beer is within a record [back] of water
		--    and next record is water
		--    and a record within 5 forward is cleaner then water.
		-- 3. If a record of Beer is within a record [back] of cleaner and the next record is water then Water.
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
            
            ---- For US only, if we still have an unknown liquid type at this point, set it to cleaner.
            IF (@SiteIsUS = 1 AND @ThisActionOriginalLiquid = 0)
            BEGIN
                SET @NewLiquidType = 3
            END
        
        END

		-- Do we need to make an update as a result of the rules above?
		IF (@NewLiquidType IS NOT NULL)
		BEGIN
			UPDATE DispenseActions
			SET IFMLiquidType = @ThisActionLiquid, LiquidType = @NewLiquidType
			WHERE EDISID = @EDISID AND Pump = @ThisSiteTap AND StartTime = @ThisActionTime
			
			UPDATE #Actions
			SET IFMLiquid = @NewLiquidType
			WHERE [Order] = @ThisActionID

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

			UPDATE DispenseActions
			SET IFMLiquidType = LiquidType, LiquidType = 5
			WHERE EDISID = @EDISID
			AND TradingDay = @CurrentCleaningDay
			AND Pump = @ThisSiteTap
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
			WHERE EDISID = @EDISID
			AND TradingDay = @CurrentCleaningDay
			AND Pump = @ThisSiteTap
			AND LiquidType = 5
			AND OriginalLiquidType IS NULL
			
			UPDATE DispenseActions
			SET IFMLiquidType = LiquidType, LiquidType = 5
			WHERE EDISID = @EDISID
			AND TradingDay = @CurrentCleaningDay
			AND StartTime BETWEEN @FirstBeerInClean AND @LastBeerInClean
			AND Pump = @ThisSiteTap
			AND LiquidType = 2
			AND OriginalLiquidType IS NULL
			
		END

		FETCH NEXT FROM curCleaningDays INTO @CurrentCleaningDay
		
	END

	CLOSE curCleaningDays
	DEALLOCATE curCleaningDays

	DELETE FROM #Actions
	
	FETCH NEXT FROM curTapsToProcess INTO @ThisSiteTap, @Actions

END

DROP TABLE #Actions

CLOSE curTapsToProcess
DEALLOCATE curTapsToProcess

-- *********************************************************************************************
-- Stage 4
-- All DLData/WaterStack/CleanerStack changes are sorted, so re-build legacy tables.

EXEC RebuildStacksFromDispenseConditions NULL, @EDISID, @From, @To


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AutoFixSiteDispenseActions] TO PUBLIC
    AS [dbo];

