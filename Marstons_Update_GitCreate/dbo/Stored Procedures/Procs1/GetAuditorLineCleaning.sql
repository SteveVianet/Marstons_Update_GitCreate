CREATE PROCEDURE [dbo].[GetAuditorLineCleaning]

AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @CustomerID INT
	SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
	FROM Configuration
	WHERE PropertyName = 'Service Owner ID'

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
			SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
			FROM SiteGroupSites 
			WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
			AND IsPrimary = 1
			GROUP BY SiteGroupID, SiteGroupSites.EDISID
		) AS PrimarySites
		JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
		LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
		WHERE PumpSetup.ValidTo IS NULL
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
	
	-- This is how far back we should be looking for unactioned cleans (1 week)
	DECLARE @From DATE = DATEADD(WEEK, -1, GETDATE())
	
	SELECT @CustomerID AS DatabaseID,
		   ISNULL(PumpOffsets.PrimaryEDISID, DispenseActions.EDISID) AS PrimaryEDISID,
		   DispenseActions.EDISID,
		   DispenseActions.TradingDay,
		   DispenseActions.Pump AS RealPumpID,
		   DispenseActions.Pump + ISNULL(PumpOffsets.PumpOffset, 0) AS Pump,  
		   SUM(CASE WHEN LiquidType = 3 THEN Pints ELSE 0 END) AS TotalCleanerVolume,
		   SUM(CASE WHEN LiquidType = 1 THEN Pints ELSE 0 END) AS TotalWaterVolume
	From DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	LEFT JOIN @PumpOffsets AS PumpOffsets ON PumpOffsets.EDISID = DispenseActions.EDISID
	LEFT OUTER JOIN CleaningProgress ON (CleaningProgress.EDISID = DispenseActions.EDISID AND
										CleaningProgress.Pump = DispenseActions.Pump AND
										CleaningProgress.Date = DispenseActions.TradingDay)
	WHERE TradingDay >= @From
	AND LiquidType IN (1, 3)
	AND CleaningProgress.Pump IS NULL
	AND Products.IsWater = 0
	GROUP BY DispenseActions.EDISID,
			 PumpOffsets.PrimaryEDISID,
			 DispenseActions.TradingDay,
			 DispenseActions.Pump,
			 PumpOffsets.PumpOffset
	HAVING (SUM(CASE WHEN LiquidType = 3 THEN Pints ELSE 0 END) > 0 OR
			SUM(CASE WHEN LiquidType = 1 THEN Pints ELSE 0 END) > 0)	
	ORDER BY DispenseActions.EDISID, Pump ASC
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorLineCleaning] TO PUBLIC
    AS [dbo];

