CREATE PROCEDURE [dbo].[RebuildStacksFromDispenseConditions]
(
	@MasterDateID		INTEGER = NULL,
	@EDISID 			INTEGER = NULL,
	@Date				SMALLDATETIME = NULL,
	@ToDate				SMALLDATETIME = NULL,
	@PumpID				INT = NULL
)

AS

/* Testing */
--DECLARE	@MasterDateID		INTEGER = NULL
--DECLARE	@EDISID 			INTEGER = 174
--DECLARE	@Date				SMALLDATETIME = GETDATE()
--DECLARE	@ToDate				SMALLDATETIME = NULL
--DECLARE	@PumpID				INT = NULL

SET NOCOUNT ON

/* Before anything is done, check whether this procedure should apply to the Site */
DECLARE @AllowRebuild BIT = 0

IF @EDISID IS NULL AND @MasterDateID IS NOT NULL
BEGIN
    -- Use MasterDateID to get the EDISID
    SELECT @EDISID = [EDISID]
    FROM [dbo].[MasterDates]
    WHERE [ID] = @MasterDateID
END

-- Testing
--SELECT * FROM [dbo].[Sites] WHERE [EDISID] = @EDISID
--SELECT * FROM [dbo].[Sites] WHERE ([SystemTypeID] IN (8, 10) OR [Quality] = 1)

IF @EDISID IS NOT NULL
BEGIN
    -- If we find a Site which is valid for rebuilding, let it happen
    SELECT @AllowRebuild = 1
    FROM [dbo].[Sites]
    WHERE [EDISID] = @EDISID
    AND
        ([SystemTypeID] IN (8, 10) -- Comtech \ Gateway 3 - Matches Panel Capabilities
    OR [Quality] = 1) -- iDraught Enabled - Matches VB6 Logic
END


IF @AllowRebuild = 1
BEGIN
    DECLARE @CurrentDate DATETIME

    IF @ToDate IS NULL
    BEGIN
	    SET @ToDate = @Date
    END

    IF @MasterDateID IS NULL AND @EDISID IS NULL AND @Date IS NULL
    BEGIN
	    RETURN
    END
    ELSE
    BEGIN 
	    CREATE TABLE #ValidMasterDates	([ID] INT NOT NULL PRIMARY KEY)

	    -- Use supplied MasterDateID
	    IF @MasterDateID IS NOT NULL
	    BEGIN
		    INSERT INTO #ValidMasterDates
		    ([ID])
		    SELECT @MasterDateID

	    END	
	    ELSE
	    BEGIN
		    -- Create MasterDateIDs
		    SET @CurrentDate = @Date
		    WHILE @CurrentDate <= @ToDate
		    BEGIN
			    EXEC [AddDelDispDate] @EDISID, @CurrentDate
			    SET @CurrentDate = DATEADD(Day, 1, @CurrentDate)
		
		    END

		    INSERT INTO #ValidMasterDates
		    ([ID])
		    SELECT [ID]
		    FROM dbo.MasterDates
		    WHERE EDISID = @EDISID
		    AND (
		          ([Date] BETWEEN @Date AND @ToDate AND @Date IS NOT NULL AND @ToDate IS NOT NULL)
		          OR
		          ([Date] = @Date AND @Date IS NOT NULL AND @ToDate IS NULL)
		    )
	
	    END

	    -- Erase DLData
	    DELETE
	    FROM DLData
	    WHERE DownloadID IN (SELECT [ID] FROM #ValidMasterDates) AND (Pump = @PumpID OR @PumpID IS NULL)
	
	    -- Erase WaterStack
	    DELETE
	    FROM WaterStack
	    WHERE WaterID IN (SELECT [ID] FROM #ValidMasterDates) AND (Line = @PumpID OR @PumpID IS NULL)
	
	    -- Erase CleaningStack
	    DELETE
	    FROM CleaningStack
	    WHERE CleaningID IN (SELECT [ID] FROM #ValidMasterDates) AND (Line = @PumpID OR @PumpID IS NULL)
	
	    -- Re-build DLData using beer+BeerInClean DispenseConditions (Unknown doesn't go anywhere!)
	    -- Horrid bodge in here to stop ProductID dupes (bad backdates, which shouldn't happen!) causing problems
	    INSERT INTO DLData (DownloadID, Pump, Shift, Product, Quantity)
	    SELECT	MasterDates.ID,
		    Pump,
		    DATEPART(hh, StartTime) + 1,
		    MIN(Product),
		    SUM(Pints)
	    FROM DispenseActions
	    JOIN MasterDates ON MasterDates.EDISID = DispenseActions.EDISID AND MasterDates.Date = CAST(DispenseActions.StartTime AS DATE)
	    WHERE MasterDates.ID IN (SELECT [ID] FROM #ValidMasterDates) AND LiquidType IN (2,5)AND (Pump = @PumpID OR @PumpID IS NULL)
	    GROUP BY MasterDates.ID, Pump, DATEPART(hh, StartTime) + 1
	
	    -- Re-build WaterStack using water DispenseConditions
	    INSERT INTO WaterStack (WaterID, [Time], Line, Volume)
	    SELECT	MasterDates.ID,
		    CAST('1899-12-30 ' + CAST(DATEPART(hh, StartTime) AS VARCHAR) + ':00:00.000' AS DATETIME),
		    Pump,
		    SUM(Pints)
	    FROM DispenseActions
	    JOIN MasterDates ON MasterDates.EDISID = DispenseActions.EDISID AND MasterDates.Date = CAST(DispenseActions.StartTime AS DATE)
	    WHERE MasterDates.ID IN (SELECT [ID] FROM #ValidMasterDates) AND LiquidType = 1 AND (Pump = @PumpID OR @PumpID IS NULL)
	    GROUP BY MasterDates.ID, Pump, CAST('1899-12-30 ' + CAST(DATEPART(hh, StartTime) AS VARCHAR) + ':00:00.000' AS DATETIME)
	
	    -- Re-build CleaningStack using cleaner+in-transition DispenseConditions
	    INSERT INTO CleaningStack (CleaningID, [Time], Line, Volume)
	    SELECT	MasterDates.ID,
		    CAST('1899-12-30 ' + CAST(DATEPART(hh, StartTime) AS VARCHAR) + ':00:00.000' AS DATETIME),
		    Pump,
		    SUM(Pints)
	    FROM DispenseActions
	    JOIN MasterDates ON MasterDates.EDISID = DispenseActions.EDISID AND MasterDates.Date = CAST(DispenseActions.StartTime AS DATE)
	    WHERE MasterDates.ID IN (SELECT [ID] FROM #ValidMasterDates) AND LiquidType IN (3,4) AND (Pump = @PumpID OR @PumpID IS NULL)
	    GROUP BY MasterDates.ID, Pump, CAST('1899-12-30 ' + CAST(DATEPART(hh, StartTime) AS VARCHAR) + ':00:00.000' AS DATETIME)
	
	    DROP TABLE #ValidMasterDates
	
    END
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RebuildStacksFromDispenseConditions] TO PUBLIC
    AS [dbo];

