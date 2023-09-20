CREATE PROCEDURE [dbo].[GetStackDispense2]
(
    @EDISID INT,
    @PumpID INT = NULL,
    @From   DATE,
    @To     DATE = NULL
)
AS
BEGIN

--DECLARE @EDISID INT = 4104
--DECLARE @From DATE  = '2016-11-16'
--DECLARE @To DATE    = '2016-11-16'
--DECLARE @PumpID INT = NULL

/*
SELECT DISTINCT [Shift] FROM DLData ORDER BY [Shift] -- 1 -> 24
SELECT DISTINCT [Time] FROM WaterStack ORDER BY [Time] -- 0 -> 23
SELECT DISTINCT [Time] FROM CleaningStack ORDER BY [Time] -- 0 -> 23
*/

IF @To IS NULL
BEGIN
    SET @To = @From
END

-- Stolen from GetPumpAddressesForDay (and modified)
DECLARE @PreviousPFS INT -- Used to store the relevant PFS
DECLARE @MaxPulseAddress INT = 399

-- Get the last Proposed Font Setup prior to the date range we are looking at
SELECT @PreviousPFS = MAX(PFS.ID)
FROM ProposedFontSetups AS PFS
WHERE PFS.EDISID = @EDISID
AND CAST(CreateDate AS DATE) <= @From

-- Get a list of IFMs (that we need to exclude from the results)
DECLARE @IFMs TABLE ([Pump] INT NOT NULL PRIMARY KEY)
INSERT INTO @IFMs ([Pump])
SELECT
    PFSI.FontNumber
FROM ProposedFontSetups AS PFS
LEFT JOIN ProposedFontSetupItems AS PFSI ON PFS.ID = PFSI.ProposedFontSetupID
WHERE PFS.EDISID = @EDISID
AND PFS.ID = @PreviousPFS
AND (PFSI.PhysicalAddress > @MaxPulseAddress) 
AND (@PumpID Is NULL OR PFSI.FontNumber = @PumpID)

DECLARE @Shifts TABLE ([Shift] INT NOT NULL PRIMARY KEY)
INSERT INTO @Shifts ([Shift]) VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24)

DECLARE	@Dates TABLE ([Date] DATETIME NOT NULL, MasterDateID INT NULL)

DECLARE @currentDate DATE = CAST(@From AS DATE)

WHILE @currentDate <= CAST(@To AS DATE)
BEGIN
	INSERT INTO @Dates ([Date])
	SELECT @currentDate

	SET @currentDate = DATEADD(day, 1, @currentDate)
END

UPDATE @Dates SET MasterDateID = ISNULL(ID, 0)
FROM	@Dates d
LEFT JOIN MasterDates md ON d.[Date] = md.[Date] AND md.EDISID = @EDISID

--SELECT
--    [MD].[MasterDateID] AS [ID],
--    @EDISID as EDISID,
--    [MD].[Date],
--    [S].[Shift],
--    CAST(LEFT(CONVERT(VARCHAR(33), [MD].[Date], 126),10) + ' ' + CAST([S].[Shift]-1 AS VARCHAR(2)) + ':00' AS DATETIME) AS [Timestamp]
--FROM @Dates AS [MD]
--CROSS APPLY @Shifts AS [S]


SELECT
    [MasterShifts].[ID] AS [MasterDateID],
    [MasterShifts].[EDISID],
    [MasterShifts].[Timestamp],
    [MasterShifts].[Shift],
    [MasterPumps].[Pump],
	CASE 
		WHEN [IFMs].[Pump] IS NULL THEN 'Pulse'
		ELSE 'IFM'
	END AS MeterType,
    [MasterProducts].[ProductID] AS [ProductID],
    [MasterProducts].[Product] AS [Product],
	[MasterProducts].Location,
	[MasterProducts].[IsCask],
	[MasterProducts].[IsWater],
    [Dispense].[Quantity] AS [DispenseQuantity],
    [Water].[Quantity] AS [WaterQuantity],
    [Cleaner].[Quantity] AS [CleanerQuantity]
FROM ( -- Generate a master list of Shifts to work from
    SELECT
        [MD].[MasterDateID] AS [ID],
        @EDISID as EDISID,
        [MD].[Date],
        [S].[Shift],
        CAST(LEFT(CONVERT(VARCHAR(33), [MD].[Date], 126),10) + ' ' + CAST([S].[Shift]-1 AS VARCHAR(2)) + ':00' AS DATETIME) AS [Timestamp]
    FROM @Dates AS [MD]
    CROSS APPLY @Shifts AS [S]
    ) AS [MasterShifts]
JOIN ( -- The Pump Setup might have been altered during the day, quickly scan the relevant tables to find all possible values   
	SELECT DISTINCT
		@EDISID as EDISID,
		p.Pump,
		p.ProductID,
		p.InUse
	FROM	PumpSetup p
	WHERE	p.EDISID = @EDISID
	AND		(p.[ValidTo] IS NULL OR p.[ValidTo] >= @From)
	AND		(p.[ValidFrom] IS NULL OR p.[ValidFrom] <= @To)
    ) AS [MasterPumps] ON [MasterShifts].[EDISID] = [MasterPumps].[EDISID]
LEFT JOIN @IFMs AS [IFMs] ON [MasterPumps].[Pump] = [IFMs].[Pump]
LEFT JOIN (
    SELECT
        [PS].[EDISID],
        [PS].[Pump],
        [PS].[ProductID],
        [P].[Description] AS [Product],
		[L].[Description] AS [Location],
		[P].[IsCask],
		[P].[IsWater]
    FROM [dbo].[PumpSetup] AS [PS]
    JOIN [dbo].[Products] AS [P] ON [PS].[ProductID] = [P].[ID]
	JOIN [dbo].[Locations] AS [L] ON [L].[ID] = [PS].[LocationID]
    WHERE 
        EDISID = @EDISID
	AND		([ValidTo] IS NULL OR [ValidTo] >= @From)
	AND		([ValidFrom] IS NULL OR [ValidFrom] <= @To)
    ) AS [MasterProducts] ON [MasterPumps].[EDISID] = [MasterProducts].[EDISID] AND [MasterPumps].[Pump] = [MasterProducts].[Pump]
LEFT JOIN (
    SELECT 
        [MD].[ID] AS [MasterDateID],
        [MD].[EDISID],
        CAST(LEFT(CONVERT(VARCHAR(33), [MD].[Date], 126),10) + ' ' + CAST([D].[Shift]-1 AS VARCHAR(2)) + ':00' AS DATETIME) AS [Timestamp],
        [D].[Pump],
        [P].[ID] AS [ProductID],
        [P].[Description] AS [Product],
        [D].[Quantity],
        2 AS [LiquidType]
    FROM [dbo].[MasterDates] AS [MD]
    JOIN [dbo].[DLData] AS [D] ON [MD].[ID] = [D].[DownloadID]
    JOIN [dbo].[Products] AS [P] ON [D].[Product] = [P].[ID]
    WHERE 
        [MD].[EDISID] = @EDISID
    AND [MD].[Date] BETWEEN @From AND @To
    --ORDER BY [MD].[Date]
    ) AS [Dispense] 
        ON  ([MasterShifts].[ID] = [Dispense].[MasterDateID] AND [MasterShifts].[EDISID] = [Dispense].[EDISID] AND [MasterShifts].[Timestamp] = [Dispense].[Timestamp])
        AND ([MasterPumps].[EDISID] = [Dispense].[EDISID] AND [MasterPumps].[Pump] = [Dispense].[Pump])
LEFT JOIN (
    SELECT
        [MD].[ID] AS [MasterDateID],
        [MD].[EDISID],
        CAST(CAST([MD].[Date] AS DATE) AS DATETIME) + CAST(CAST([W].[Time] AS TIME) AS DATETIME) AS [Timestamp], -- Double Casting to handle invalid date/time values on opposing fields
        [W].[Line] AS [Pump],
        -1 AS [ProductID],
        'Water' AS [Product],
        [W].[Volume] AS [Quantity],
        1 AS [LiquidType]
    FROM [dbo].[MasterDates] AS [MD]
    JOIN [dbo].[WaterStack] AS [W] ON [MD].[ID] = [W].[WaterID]
    WHERE 
        [MD].[EDISID] = @EDISID
    AND [MD].[Date] BETWEEN @From AND @To
    --ORDER BY [MD].[Date]
    ) AS [Water] 
        ON  ([MasterShifts].[ID] = [Water].[MasterDateID] AND [MasterShifts].[EDISID] = [Water].[EDISID] AND [MasterShifts].[Timestamp] = [Water].[Timestamp])
        AND ([MasterPumps].[EDISID] = [Water].[EDISID] AND [MasterPumps].[Pump] = [Water].[Pump])
LEFT JOIN (
    SELECT
        [MD].[ID] AS [MasterDateID],
        [MD].[EDISID],
        CAST(CAST([MD].[Date] AS DATE) AS DATETIME) + CAST(CAST([C].[Time] AS TIME) AS DATETIME) AS [Timestamp], -- Double Casting to handle invalid date/time values on opposing fields
        [C].[Line] AS [Pump],
        -2 AS [ProductID],
        'Cleaner' AS [Product],
        [C].[Volume] AS [Quantity],
        3 AS [LiquidType]
    FROM [dbo].[MasterDates] AS [MD]
    JOIN [dbo].[CleaningStack] AS [C] ON [MD].[ID] = [C].[CleaningID]
    WHERE 
        [MD].[EDISID] = @EDISID
    AND [MD].[Date] BETWEEN @From AND @To
    --ORDER BY [MD].[Date]
    ) AS [Cleaner]
        ON  ([MasterShifts].[ID] = [Cleaner].[MasterDateID] AND [MasterShifts].[EDISID] = [Cleaner].[EDISID] AND [MasterShifts].[Timestamp] = [Cleaner].[Timestamp])
        AND ([MasterPumps].[EDISID] = [Cleaner].[EDISID] AND [MasterPumps].[Pump] = [Cleaner].[Pump])
--WHERE
--    (
--        [Dispense].[MasterDateID] IS NOT NULL
--    OR  [Water].[MasterDateID] IS NOT NULL
--    OR  [Cleaner].[MasterDateID] IS NOT NULL
--    )
ORDER BY
    [MasterPumps].[Pump],
    [MasterShifts].[Timestamp]
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetStackDispense2] TO PUBLIC
    AS [dbo];

