CREATE PROCEDURE [dbo].[SetAutomaticSiteRankings]
(
	@To							DATETIME,
	@SiteID						VARCHAR(50) = NULL,
	@IncludeCleaningTL			BIT = 1,
	@IncludeThroughputTL		BIT = 1,
	@IncludeTemperatureTL		BIT = 1,
	@IncludeEquipmentTL			BIT = 1,
	@IncludeYieldTL				BIT = 1
)
AS

SET NOCOUNT ON

DECLARE @ReportFrom DATETIME
DECLARE @ThroughputFrom DATETIME

SET @To = CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, @To)))
SET @ReportFrom = DATEADD(day, -7, @To)
SET @ThroughputFrom = DATEADD(day, -28, @To)

CREATE TABLE #Sites(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
CREATE TABLE #SitePumpCounts(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
CREATE TABLE #SitePumpOffsets(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
CREATE TABLE #PreviousCleans(EDISID INT NOT NULL, Pump INT NOT NULL, Cleaned DATETIME NOT NULL)
CREATE TABLE #SiteInputCounts(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxInput INT NOT NULL)
CREATE TABLE #SiteInputOffsets(EDISID INT NOT NULL, InputOffset INT NOT NULL)
CREATE TABLE #TradingSold(TradingDateAndHour DATETIME, Quantity FLOAT)

CREATE TABLE #TradingDispensed (EDISID INT,
					[DateAndTime] DATETIME,
					TradingDateAndTime DATETIME,
					ProductID INT,
					LocationID INT,
					Quantity FLOAT,
					Drinks FLOAT,
					SitePump INT,
					Pump INT,
					AverageTemperature FLOAT,
					TradingDay DATETIME)				
					
CREATE TABLE #AllSitePumps(EDISID INT NOT NULL, PumpID INT NOT NULL, SitePump INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
				  FlowRateSpecification FLOAT NOT NULL, FlowRateTolerance FLOAT NOT NULL,
				  TemperatureSpecification FLOAT NOT NULL, TemperatureTolerance FLOAT NOT NULL,
				  ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL, DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL, PreviousClean DATETIME NOT NULL)

DECLARE @EDISID INT
DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT

DECLARE @LowVolumeThreshold FLOAT

SELECT @LowVolumeThreshold = DBs.LowVolumeThreshold
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS DBs
WHERE DB_NAME() = DBs.Name

DECLARE curDatabases CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT Sites.EDISID
FROM Sites
LEFT JOIN SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
LEFT JOIN SiteGroups ON SiteGroups.[ID] = SiteGroupSites.SiteGroupID AND TypeID = 1 AND SiteGroupSites.IsPrimary = 1
WHERE Quality = 1
AND Hidden = 0
AND (Sites.SiteID = @SiteID OR @SiteID IS NULL)
ORDER BY Sites.EDISID

OPEN curDatabases
FETCH NEXT FROM curDatabases INTO @EDISID

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @SiteOnline = SiteOnline, @IsBQM = Quality
	FROM dbo.Sites
	WHERE EDISID = @EDISID

	-- Find out which EDISIDs are relevant (plough through SiteGroups)
	INSERT INTO #Sites
	(EDISID)
	SELECT EDISID
	FROM Sites
	WHERE EDISID = @EDISID
	 
	SELECT @SiteGroupID = SiteGroupID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	WHERE TypeID = 1 AND EDISID = @EDISID
	 
	INSERT INTO #Sites (EDISID)
	SELECT SiteGroupSites.EDISID
	FROM SiteGroupSites
	JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
	WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID
	
	-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
	INSERT INTO #SitePumpCounts (EDISID, MaxPump)
	SELECT PumpSetup.EDISID, MAX(Pump)
	FROM PumpSetup
	JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
	WHERE ValidTo IS NULL
	GROUP BY PumpSetup.EDISID, Sites.CellarID
	ORDER BY CellarID

	INSERT INTO #SitePumpOffsets (EDISID, PumpOffset)
	SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
	FROM #SitePumpCounts AS MainCounts
	LEFT JOIN #SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
	LEFT JOIN #SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
	LEFT JOIN #SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

	INSERT INTO #PreviousCleans
	(EDISID, Pump, Cleaned)
	SELECT MasterDates.EDISID,
 		 PumpSetup.Pump,
		 MAX(MasterDates.[Date])
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND CleaningStack.Line = PumpSetup.Pump
             			AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	WHERE MasterDates.EDISID IN (SELECT EDISID FROM #Sites)
	AND MasterDates.[Date] <= @To
	GROUP BY MasterDates.EDISID,
			  PumpSetup.Pump

	INSERT INTO #AllSitePumps (EDISID, PumpID, SitePump, LocationID, ProductID, FlowRateSpecification, FlowRateTolerance, TemperatureSpecification, TemperatureTolerance, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed, PreviousClean)
	SELECT Sites.EDISID, PumpSetup.Pump+PumpOffset, PumpSetup.Pump, PumpSetup.LocationID, PumpSetup.ProductID,
		ISNULL(SiteProductSpecifications.FlowSpec, Products.FlowRateSpecification),
		ISNULL(SiteProductSpecifications.FlowTolerance, Products.FlowRateTolerance),
		ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification),
		ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance),
		ValidFrom,
		ISNULL(ValidTo, @To),
		COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
		COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
		ISNULL(PreviousCleans.Cleaned, 0) AS PreviousClean
	FROM PumpSetup
	JOIN #Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
	JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
	LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
	LEFT JOIN #PreviousCleans AS PreviousCleans ON PreviousCleans.EDISID = PumpSetup.EDISID 
        								  AND PreviousCleans.Pump = PumpSetup.Pump
	WHERE (ValidFrom <= @To)
	AND (ISNULL(ValidTo, @To) >= @ReportFrom)
	AND (ISNULL(ValidTo, @To) >= @SiteOnline)
	AND Products.IsWater = 0
	AND Products.IsMetric = 0
	AND InUse = 1

	INSERT INTO #TradingDispensed
	(EDISID,
	DateAndTime,
	TradingDateAndTime,
	ProductID,
	LocationID,
	Quantity,
	Drinks,
	SitePump,
	Pump,
	AverageTemperature,
	TradingDay)
	SELECT  DispenseActions.EDISID,
		StartTime,
		TradingDay + CONVERT(VARCHAR(10), StartTime, 108) AS TradingDateAndTime,
		DispenseActions.Product,
		Location,
		Pints,
		EstimatedDrinks,
		DispenseActions.Pump,
		DispenseActions.Pump + PumpOffset,
		MinimumTemperature,
		TradingDay
	FROM DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	JOIN #SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	WHERE DispenseActions.EDISID IN (SELECT EDISID FROM #Sites)
	AND TradingDay BETWEEN @ThroughputFrom AND @To
	AND (Products.IsMetric = 0)
	AND (Products.IsWater = 0)
	AND (LiquidType = 2)
	--AND (Pints >= 0.3)
	AND TradingDay >= @SiteOnline

	INSERT INTO #SiteInputCounts (EDISID, MaxInput)
	SELECT EquipmentItems.EDISID, MAX(InputID)
	FROM EquipmentItems
	JOIN #Sites AS Sites ON Sites.EDISID = EquipmentItems.EDISID
	GROUP BY EquipmentItems.EDISID

	INSERT INTO #SiteInputOffsets (EDISID, InputOffset)
	SELECT MainCounts.EDISID, ISNULL(SecondaryCounts.MaxInput, 0)
	FROM #SiteInputCounts AS MainCounts
	LEFT JOIN #SiteInputCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter

	DECLARE @CleaningRanking INT
	DECLARE @ThroughputRanking INT
	DECLARE @TemperatureRanking INT
	DECLARE @EquipmentRecircRanking INT
	DECLARE @EquipmentAmbientRanking INT
	DECLARE @TillYieldRanking INT
	DECLARE @PouringYieldRanking INT
	
	SELECT  @CleaningRanking = ISNULL(CleaningTL, 6),
			@ThroughputRanking = ISNULL(ThroughputTL, 6),
			@TemperatureRanking = ISNULL(TemperatureTL, 6),
			@EquipmentRecircRanking = ISNULL(EquipmentRecircTL, 6),
			@EquipmentAmbientRanking = ISNULL(EquipmentAmbientTL, 6),
			@TillYieldRanking = ISNULL(TillYieldTL, 6),
			@PouringYieldRanking = ISNULL(PouringYieldTL, 6)
	FROM SiteRankingCurrent
	WHERE EDISID = @EDISID

	-- 1. CLEANING TRAFFIC LIGHT
	IF @IncludeCleaningTL = 1
	BEGIN
		DECLARE @PumpsOverdue FLOAT
		DECLARE @PumpsDue FLOAT
		DECLARE @TotalPumps FLOAT

		SELECT @PumpsOverdue = SUM(CASE WHEN DATEDIFF(Day, PreviousClean, @To) > DaysBeforeRed THEN 1 ELSE 0 END),
			   @PumpsDue = SUM(CASE WHEN DATEDIFF(Day, PreviousClean, @To) BETWEEN DaysBeforeAmber AND DaysBeforeRed THEN 1 ELSE 0 END),
			   @TotalPumps = COUNT(*)
		FROM (
			SELECT PumpID,
				   PreviousClean,
				   DaysBeforeAmber,
				   DaysBeforeRed
			FROM #AllSitePumps AS AllSitePumps
			WHERE ValidTo = @To
			) AS AllSitePumps
		LEFT JOIN 
		(SELECT EDISID,
			   Pump,
			   Cleaned
		FROM #PreviousCleans
		) AS PumpDispense ON PumpDispense.Pump = AllSitePumps.PumpID
		JOIN
		(SELECT Pump, SUM(Quantity) AS Quantity
		 FROM #TradingDispensed
		 WHERE TradingDateAndTime >= @ReportFrom
		 GROUP BY Pump
		 HAVING SUM(Quantity) > 2
		 ) AS Dispense ON Dispense.Pump = AllSitePumps.PumpID

		SELECT @CleaningRanking = (CASE 
					WHEN (@PumpsOverdue/@TotalPumps)*100 > 15  THEN 1
					WHEN (@PumpsDue/@TotalPumps)*100 > 20 THEN 2
	    			WHEN (@PumpsDue/@TotalPumps)*100 < 20 THEN 3
	    			WHEN (SELECT SUM(Quantity) 
						  FROM #TradingDispensed
						  WHERE TradingDateAndTime >= @ReportFrom) > 0 THEN 1
	    			ELSE 6
       				END)
		FROM Sites
		WHERE EDISID = @EDISID
	
	END
	
	-- 2. THROUGHPUT TRAFFIC LIGHT
	IF @IncludeThroughputTL = 1
	BEGIN
		DECLARE @WeekCount INT
		DECLARE @DispenseTotal FLOAT
		SET @WeekCount = DATEDIFF(week, @ThroughputFrom, @To)
		
		SELECT @DispenseTotal = ISNULL(SUM(Quantity), 0)
		FROM #TradingDispensed
		
		IF @DispenseTotal = 0
		BEGIN
			SET @ThroughputRanking = 6
		END
		ELSE
		BEGIN
		
			SELECT @ThroughputRanking = CASE WHEN COUNT(*) > 1 THEN 1 
											 WHEN COUNT(*) = 1 THEN 2 
											 ELSE 3 END
			FROM
			(
				SELECT Pump, ProductID, AVG(WeeklyVolume) AS AvgWeeklyVolume
				FROM
				(
					SELECT Pump,
						   ProductID,
						   DATEADD(ww, DATEDIFF(ww,0,TradingDay), 0) AS TradingDate, 
						   SUM(Quantity) AS WeeklyVolume
					FROM #TradingDispensed
					GROUP BY Pump, ProductID, DATEADD(ww, DATEDIFF(ww,0,TradingDay), 0)
				) AS WeeklyVolume
			GROUP BY Pump, ProductID
			HAVING AVG(WeeklyVolume) < @LowVolumeThreshold
			) AS ThroughputAverages

		END
		
	END
	
	-- 3. TEMPERATURE TRAFFIC LIGHT
	IF @IncludeTemperatureTL = 1
	BEGIN
		DECLARE @TemperatureAmberValue INT
		SET @TemperatureAmberValue = 2
		
		DECLARE @UnderSpecIsInSpec BIT
		SET @UnderSpecIsInSpec = 1

		DECLARE @TotalInSpec FLOAT
		DECLARE @TotalInTolerance FLOAT
		DECLARE @TotalOutOfSpec FLOAT
		DECLARE @TotalDispense FLOAT
				
		SELECT @TotalInSpec = SUM(InSpec),
			   @TotalInTolerance = SUM(InTolerance),
			   @TotalOutOfSpec = SUM(OutOfSpec),
			   @TotalDispense = SUM(InSpec + InTolerance + OutOfSpec)
		FROM 
		(
		SELECT AllSitePumps.EDISID,
			   AllSitePumps.PumpID,
			   AllSitePumps.TemperatureSpecification,
			   AllSitePumps.TemperatureTolerance,
		   		SUM(CASE WHEN (AverageTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance OR @UnderSpecIsInSpec = 1)
			  AND AverageTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance THEN Quantity ELSE 0 END) AS InSpec,
		SUM(CASE WHEN (AverageTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance
			  AND AverageTemperature >= AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
			  AND @UnderSpecIsInSpec = 0)
			  OR (AverageTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance
			  AND AverageTemperature <= AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue)
			 THEN Quantity ELSE 0 END) AS InTolerance,
		SUM(CASE WHEN (AverageTemperature < AllSitePumps.TemperatureSpecification - AllSitePumps.TemperatureTolerance - @TemperatureAmberValue
			  AND @UnderSpecIsInSpec = 0)
			  OR AverageTemperature > AllSitePumps.TemperatureSpecification + AllSitePumps.TemperatureTolerance + @TemperatureAmberValue THEN Quantity ELSE 0 END) AS OutOfSpec
		FROM #AllSitePumps AS AllSitePumps
		JOIN #TradingDispensed AS TradingDispensed 
			ON (AllSitePumps.PumpID = TradingDispensed.Pump 
				AND
				AllSitePumps.LocationID = TradingDispensed.LocationID 
				AND
				AllSitePumps.ProductID = TradingDispensed.ProductID
				)
		WHERE TradingDateAndTime >= @ReportFrom
		AND TradingDispensed.Quantity >= 0.3
		GROUP BY AllSitePumps.EDISID, AllSitePumps.PumpID, AllSitePumps.TemperatureSpecification, AllSitePumps.TemperatureTolerance
		) AS PumpTemperatures

		IF @TotalDispense = 0 OR @TotalDispense IS NULL
		BEGIN
			SET @TemperatureRanking = 6

		END
		ELSE
		BEGIN
			SELECT @TemperatureRanking = (CASE WHEN (@TotalOutOfSpec/@TotalDispense)*100 > 20 THEN 1
			       				   WHEN (@TotalInTolerance/@TotalDispense)*100 > 5 THEN 2
     	    		      				   ELSE 3
       		         					  END)
			FROM Sites
			WHERE EDISID = @EDISID
		END

	END
	
	-- 4. EQUIPMENT TRAFFIC LIGHT
	IF @IncludeEquipmentTL = 1
	BEGIN
	
		DECLARE @EquipmentRecircDaysOutOfSpec INT
		DECLARE @EquipmentRecircDaysInTolerance INT
		DECLARE @EquipmentAmbientDaysOutOfSpec INT
		DECLARE @EquipmentAmbientDaysInTolerance INT

		SELECT @EquipmentRecircDaysOutOfSpec = SUM(CASE WHEN Ranking = 'Red' AND EquipmentSubTypeID = 1 THEN 1 ELSE 0 END),
				@EquipmentRecircDaysInTolerance = SUM(CASE WHEN Ranking = 'Amber' AND EquipmentSubTypeID = 1 THEN 1 ELSE 0 END),
				@EquipmentAmbientDaysOutOfSpec = SUM(CASE WHEN Ranking = 'Red' AND EquipmentSubTypeID = 2 THEN 1 ELSE 0 END),
				@EquipmentAmbientDaysInTolerance = SUM(CASE WHEN Ranking = 'Amber' AND EquipmentSubTypeID = 2 THEN 1 ELSE 0 END)
		FROM
		(
		SELECT  EquipmentReadings.EDISID,
			  CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, EquipmentReadings.TradingDate))) AS TradingDay,
			  EquipmentReadings.InputID + InputOffset AS InputID,
			  ValueTolerance,
			  ValueHighSpecification,
			  EquipmentTypes.EquipmentSubTypeID,
			  CASE WHEN AVG(EquipmentReadings.Value) > (ValueHighSpecification + ValueTolerance) THEN 'Red'
						WHEN AVG(EquipmentReadings.Value) BETWEEN ValueHighSpecification AND (ValueHighSpecification + ValueTolerance) THEN 'Amber'
						 ELSE 'Green' END AS Ranking
		FROM EquipmentReadings
		JOIN EquipmentItems ON (EquipmentItems.EDISID = EquipmentReadings.EDISID AND
					  EquipmentItems.InputID = EquipmentReadings.InputID)
		JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
		JOIN #SiteInputOffsets AS SiteInputOffsets ON SiteInputOffsets.EDISID = EquipmentReadings.EDISID
		JOIN #Sites AS RelevantSites ON RelevantSites.EDISID = EquipmentReadings.EDISID
		WHERE TradingDate BETWEEN @ReportFrom AND DATEADD(second, -1, DATEADD(day, 1, @To))
		AND EquipmentReadings.Value BETWEEN -10 AND 30
		AND EquipmentItems.InUse = 1
		AND (CAST( CONVERT( VARCHAR(8), EquipmentReadings.LogDate, 108) AS TIME(0)) BETWEEN EquipmentItems.AlarmStartTime AND DATEADD(SECOND, -1, EquipmentItems.AlarmEndTime))
		GROUP BY EquipmentReadings.EDISID,
			 CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, EquipmentReadings.TradingDate))),
			 EquipmentReadings.InputID + InputOffset,
			 ValueTolerance,
			 ValueHighSpecification,
			 EquipmentTypes.EquipmentSubTypeID
		) AS EquipmentDailyAverages

		SELECT @EquipmentRecircRanking = (CASE
					WHEN @EquipmentRecircDaysOutOfSpec  > 1 THEN 1
					WHEN @EquipmentRecircDaysInTolerance >= 2 THEN 2
					WHEN @EquipmentRecircDaysInTolerance < 2 THEN 3
 					ELSE 6
						  END),
			   @EquipmentAmbientRanking = (CASE
					WHEN @EquipmentAmbientDaysOutOfSpec  > 1 THEN 1
					WHEN @EquipmentAmbientDaysInTolerance >= 2 THEN 2
					WHEN @EquipmentAmbientDaysInTolerance < 2 THEN 3
 					ELSE 6
						  END)          
		FROM Sites
		WHERE EDISID = @EDISID

	END
	
	-- 5. YIELD TRAFFIC LIGHTS
	IF @IncludeYieldTL = 1
	BEGIN
		DECLARE @Sold FLOAT
		DECLARE @PouringYieldPercentage FLOAT
		DECLARE @TillYieldPercentage FLOAT
		DECLARE @TradingDayBeginsAt INT
		DECLARE @LatestSalesDate DATETIME
		
		SELECT @LatestSalesDate = MAX([TradingDate])
		FROM Sales
		JOIN MasterDates ON MasterDates.[ID] = Sales.MasterDateID
		JOIN #Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
		WHERE MasterDates.[Date] BETWEEN @ReportFrom AND @To
		
		SET @TradingDayBeginsAt = 5

		INSERT INTO #TradingSold
		(TradingDateAndHour, Quantity)
		SELECT TradingDate,
			   SUM(Sales.Quantity)
		FROM Sales
		JOIN Products ON Products.[ID] = Sales.ProductID
		JOIN #Sites AS RelevantSites ON RelevantSites.EDISID = Sales.EDISID
		WHERE TradingDate BETWEEN @ReportFrom AND @LatestSalesDate
		AND Products.IsMetric = 0
		GROUP BY TradingDate

		SELECT 	@Sold = ISNULL(SUM(BeerSold.Quantity), 0), 
				@PouringYieldPercentage = CASE WHEN ISNULL(SUM(BeerDispensed.ActualQuantity), 0) = 0 THEN 0 ELSE ISNULL(SUM(BeerDispensed.RoundedQuantity), 0) / ISNULL(SUM(BeerDispensed.ActualQuantity), 0) * 100 END,
				@TillYieldPercentage = CASE WHEN ISNULL(SUM(BeerDispensed.RoundedQuantity), 0) = 0 THEN 0 ELSE ISNULL(SUM(BeerSold.Quantity), 0) / ISNULL(SUM(BeerDispensed.RoundedQuantity), 0) * 100 END,
				@DispenseTotal = ISNULL(SUM(BeerDispensed.ActualQuantity), 0)
		FROM
		(
			SELECT  DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) AS TradingDateAndHour,
			SUM(Quantity) AS ActualQuantity,
			SUM(Drinks) AS RoundedQuantity
			FROM #TradingDispensed AS TradingDispensed
			JOIN Products ON Products.ID = TradingDispensed.ProductID
			WHERE TradingDateAndTime BETWEEN @ReportFrom AND COALESCE(DATEADD(second, -1, DATEADD(day, 1, @LatestSalesDate)), @To)
			GROUP BY DATEADD(dw, -DATEPART(dw, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12) AS DATETIME)) + 1, CAST(CONVERT(VARCHAR(10), [TradingDateAndTime], 12)  AS DATETIME))
		) AS BeerDispensed
		FULL OUTER JOIN 
		(
		SELECT TradingDateAndHour,
			   SUM(Quantity) AS Quantity
		FROM #TradingSold
		GROUP BY TradingDateAndHour
		) AS BeerSold ON (BeerDispensed.[TradingDateAndHour] = BeerSold.[TradingDateAndHour])

		IF @Sold > 0 AND @DispenseTotal > 0
		BEGIN
			SET @TillYieldRanking = (CASE WHEN @TillYieldPercentage < 98 THEN 1
				 WHEN (@TillYieldPercentage BETWEEN 98 AND 99) OR @TillYieldPercentage > 102 THEN 2
				 WHEN @TillYieldPercentage BETWEEN 99 AND 102 THEN 3
			END)
		END
		ELSE
		BEGIN
			SET @TillYieldRanking = 6
		END
		
		SET @PouringYieldRanking = (CASE WHEN @PouringYieldPercentage <= 98 THEN 1
			 WHEN ((@PouringYieldPercentage > 98 AND @PouringYieldPercentage <= 102) OR @PouringYieldPercentage > 106) THEN 2
			 WHEN (@PouringYieldPercentage > 102 AND @PouringYieldPercentage <=106) THEN 3
		END)
		
		IF (@PouringYieldRanking IS NULL) OR (@DispenseTotal = 0)
		BEGIN
			SET @PouringYieldRanking = 6
		END

	END
	
	--ADD TO/UPDATE SITERANKINGCURRENT TABLE
	DECLARE @RankingEDISID INT
	SET @RankingEDISID = NULL
	
	SELECT @RankingEDISID = EDISID 
	FROM SiteRankingCurrent
	WHERE EDISID = @EDISID

	IF @RankingEDISID IS NULL
	BEGIN
		INSERT INTO dbo.SiteRankingCurrent
		(EDISID, PouringYieldTL, TillYieldTL, CleaningTL, TemperatureTL, EquipmentRecircTL, EquipmentAmbientTL, ThroughputTL)
		VALUES
		(@EDISID, @PouringYieldRanking, @TillYieldRanking, @CleaningRanking, @TemperatureRanking, @EquipmentRecircRanking, @EquipmentAmbientRanking, @ThroughputRanking)
	END
	ELSE
	BEGIN
		UPDATE dbo.SiteRankingCurrent
		SET PouringYieldTL = @PouringYieldRanking,
			TillYieldTL = @TillYieldRanking,
			CleaningTL = @CleaningRanking,
			TemperatureTL = @TemperatureRanking,
			EquipmentRecircTL = @EquipmentRecircRanking, 
			EquipmentAmbientTL = @EquipmentAmbientRanking,
			ThroughputTL = @ThroughputRanking
		WHERE EDISID = @EDISID
		
	END
	
	TRUNCATE TABLE #Sites
	TRUNCATE TABLE #SitePumpCounts
	TRUNCATE TABLE #SitePumpOffsets
	TRUNCATE TABLE #PreviousCleans
	TRUNCATE TABLE #SiteInputCounts
	TRUNCATE TABLE #SiteInputOffsets
	TRUNCATE TABLE #TradingDispensed
	TRUNCATE TABLE #AllSitePumps
	TRUNCATE TABLE #TradingSold
	
	SET @SiteGroupID = NULL
	SET @Sold = NULL
	SET @DispenseTotal = NULL
	SET @LatestSalesDate = NULL
	
	FETCH NEXT FROM curDatabases INTO @EDISID
END

CLOSE curDatabases
DEALLOCATE curDatabases

DROP TABLE #Sites
DROP TABLE #SitePumpCounts
DROP TABLE #SitePumpOffsets
DROP TABLE #PreviousCleans
DROP TABLE #SiteInputCounts
DROP TABLE #SiteInputOffsets
DROP TABLE #TradingDispensed
DROP TABLE #AllSitePumps
DROP TABLE #TradingSold

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetAutomaticSiteRankings] TO PUBLIC
    AS [dbo];

