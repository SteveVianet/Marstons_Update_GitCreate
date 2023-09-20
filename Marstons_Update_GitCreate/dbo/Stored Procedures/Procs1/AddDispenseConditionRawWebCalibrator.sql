-- =============================================
-- Author:      Modification by Neil Watson
-- Create date: 01/02/2017
-- Description: Originally dbo.AddDispenseConditionRaw but this new one 
-- checks to make sure the row doesn't exist before inserting.
-- Modified date: 22/02/2017
-- Modified by: David Green
-- Description: Changed to save data to DispenseActions or DLData\WaterStack\CleaningStack
-- depending on the System Type or Site's iDraught status.
-- =============================================
CREATE PROCEDURE [dbo].[AddDispenseConditionRawWebCalibrator] 
(
    @EDISID                     INT, 
    @StartDateAndTime           DATETIME,
    @FlowmeterAddress           INT,
    @Duration                   FLOAT, 
    @PulseCount                 INT, 
    @LiquidType                 INT,
    @AverageTemperature         FLOAT, 
    @MinimumTemperature         FLOAT, 
    @MaximumTemperature         FLOAT, 
    @AverageConductivity        INT, 
    @MinimumConductivity        INT, 
    @MaximumConductivity        INT
)
AS

/*
DECLARE  @EDISID                     INT = 1625
DECLARE  @StartDateAndTime           DATETIME = '2017-02-24 09:51:20'
DECLARE  @FlowmeterAddress           INT = 1
DECLARE  @Duration                   FLOAT = 1
DECLARE  @PulseCount                 INT = 247
DECLARE  @LiquidType                 INT = 0
DECLARE  @AverageTemperature         FLOAT
DECLARE  @MinimumTemperature         FLOAT
DECLARE  @MaximumTemperature         FLOAT
DECLARE  @AverageConductivity        INT
DECLARE  @MinimumConductivity        INT
DECLARE  @MaximumConductivity        INT
*/

-- Takes unscaled pulse count: will lookup scalar, logical address and product details

DECLARE @ProductIsMetric    BIT
DECLARE @ProductID          INT
DECLARE @Prescalar          INT
DECLARE @StartTime          DATETIME
DECLARE @StartDate          DATETIME
DECLARE @TradingDate        DATETIME
DECLARE @Pump               INT
DECLARE @Location           INT
DECLARE @Pints              FLOAT

DECLARE @IsIdraught         BIT = 0
DECLARE @SystemType         INT


DECLARE @Error VARCHAR(1024)

SET NOCOUNT ON

SET @StartDate = CAST(CONVERT(VARCHAR(10), @StartDateAndTime, 12) AS DATETIME)
SET @StartTime = CAST('1899-12-30 ' + CONVERT(VARCHAR(10), @StartDateAndTime, 8) AS DATETIME)
SELECT @TradingDate = CASE WHEN DATEPART(Hour, @StartTime) < 5 THEN DATEADD(Day, -1, @StartDate) ELSE @StartDate END

SELECT
    @IsIdraught = [Quality],
    @SystemType = [SystemTypeID]
FROM [dbo].[Sites]
WHERE [EDISID] = @EDISID

-- Find logical address (required)
SET @Pump = dbo.fnGetPumpFromFlowmeterAddress(@EDISID, @FlowmeterAddress, @StartDate)

-- Find pump location (required)
SET @Location = dbo.fnGetLocationFromPump(@EDISID, @Pump, @StartDate)

IF @Pump IS NOT NULL
BEGIN
    IF @Location IS NOT NULL
    BEGIN
        -- Find scalar and scale data
        SET @Prescalar = dbo.fnGetPrescalar(@EDISID, @Pump, @StartDate)
        IF @Prescalar IS NOT NULL
        BEGIN
            SET @Pints = CAST(@PulseCount AS FLOAT) / (CAST(@Prescalar AS FLOAT) * 2)
        END

        IF @Prescalar IS NOT NULL
        BEGIN
            -- Find historical product
            SELECT @ProductID = ProductID, @ProductIsMetric = IsMetric
            FROM dbo.PumpSetup
            JOIN dbo.Products ON dbo.Products.ID = dbo.PumpSetup.ProductID
            WHERE EDISID = @EDISID
            AND Pump = @Pump
            AND ValidFrom <= @StartDate
            AND (ValidTo >= @StartDate OR ValidTo IS NULL)
            
            IF @ProductID IS NULL
            BEGIN
                SELECT @ProductID = ID, @ProductIsMetric = IsMetric
                FROM dbo.Products
                WHERE [Description] = '0'
            END
            
            IF @ProductIsMetric = 1
            BEGIN
                SET @Pints = (@Pints / 5.0) * 1.75975326
            END
            
            SELECT @LiquidType = (CASE 
                    WHEN @ProductIsMetric = 1 THEN 2
                    ELSE @LiquidType
                END)

            IF (@Pints > 0.009) OR (@ProductIsMetric = 1)
            BEGIN

                IF @IsIdraught = 1 OR @SystemType IN (8,10) -- iDraught (covers VB6 logic) or Comtech/GW3 (covers panel logic)
                BEGIN
                    IF NOT EXISTS (SELECT 1 FROM dbo.DispenseActions WHERE EDISID = @EDISID AND StartTime = @StartDateAndTime AND Pump = @Pump)
                    BEGIN
                        --PRINT 'INSERT INTO dbo.DispenseActions'
                        INSERT INTO dbo.DispenseActions
                        (EDISID, StartTime, TradingDay, Pump, Location, Product, Duration, AverageTemperature, MinimumTemperature, MaximumTemperature, LiquidType, IFMLiquidType, AverageConductivity, MinimumConductivity, MaximumConductivity, Pints, EstimatedDrinks)
                        VALUES
                        (@EDISID, @StartDateAndTime, @TradingDate, @Pump, @Location, @ProductID, @Duration, @AverageTemperature, @MinimumTemperature, @MaximumTemperature, @LiquidType, NULL, @AverageConductivity, @MinimumConductivity, @MaximumConductivity, @Pints, dbo.fnGetSiteDrinkVolume(@EDISID, @Pints*100, @ProductID) )
                    END
                END
                ELSE
                BEGIN
                    /* During a calibration we receive per-pour information, but this is not supported by these systems for general use.
                       We must convert this to per-shift information and not save per-pour to maintain consistency and not break any existing logic.
                       This must handle drip-feeding of data as we won't receive the entire shift at once like every other part of the database would!
                    */

                    DECLARE @VBMinDate DATETIME = CAST('1899-12-30' AS DATETIME) -- DATE Component for TIME in WaterStack\CleaningStack
                    DECLARE @Shift INT = DATEPART(HOUR, @StartDateAndTime) + 1   -- SHIFT value for DLData
                    DECLARE @DispenseDate DATE = CAST(@StartDateAndTime AS DATE) -- Strip the TIME for DLData
                    DECLARE @DispenseTime DATETIME = CAST(@StartDateAndTime AS TIME) -- Strip the DATE for WaterStack\CleaningStack
                    DECLARE @MasterDate DATE = NULL
                    DECLARE @PreviousQuantity FLOAT = 0
                    DECLARE @NewQuantity FLOAT = 0
                    SET @DispenseTime = (@VBMinDate + @DispenseTime) -- Update the TIME for WaterStack\CleaningStack to match VB6 DATE requirements
                    
                    IF @LiquidType IN (2, 0, 4, 5) -- Product (aka BEER) or another type which can't be stored as Water/Cleaner
                    BEGIN
                        -- If this gives us a value, we can trust that some dispense already exists in DLData for this Pump+Shift
                        SELECT @MasterDate = [MD].[Date], @PreviousQuantity = [D].[Quantity]
                        FROM [dbo].[MasterDates] AS [MD]
                        JOIN [dbo].[DLData] AS [D] ON [MD].[ID] = [D].[DownloadID]
                        WHERE
                            [EDISID] = @EDISID
                        AND [Shift] = @Shift
                        AND [Pump] = @Pump
                        AND [MD].[Date] = @DispenseDate

                        -- If dispense already exists, assume we must add our amount to the existing total. 
                        IF @MasterDate IS NOT NULL
                        BEGIN
                            -- Add to existing
                            SET @NewQuantity = @PreviousQuantity + @Pints
                            
                            --PRINT 'EXEC UpdateDispense @EDISID, @DispenseDate, @Pump, @Shift, @ProductID, @NewQuantity'
                            EXEC UpdateDispense @EDISID, @DispenseDate, @Pump, @Shift, @ProductID, @NewQuantity
                        END
                        ELSE
                        BEGIN
                            -- Add new
                            --PRINT 'EXEC AddDispense @EDISID, @DispenseDate, @Pump, @Shift, @ProductID, @Pints'
                            EXEC AddDispense @EDISID, @DispenseDate, @Pump, @Shift, @ProductID, @Pints
                        END
                    END
                    ELSE IF @LiquidType = 1 -- Water
                    BEGIN
                        -- If this gives us a value, we can trust that some dispense already exists in WaterStack for this Pump+Shift
                        SELECT @MasterDate = [Date], @PreviousQuantity = [W].[Volume]
                        FROM [dbo].[MasterDates] AS [MD]
                        JOIN [dbo].[WaterStack] AS [W] ON [MD].[ID] = [W].[WaterID]
                        WHERE
                            [EDISID] = @EDISID
                        AND [Time] = @DispenseTime
                        AND [Line] = @Pump
                        AND [MD].[Date] = @DispenseDate

                        -- If dispense already exists, assume we must add our amount to the existing total. 
                        IF @MasterDate IS NOT NULL
                        BEGIN
                            -- Add to existing
                            SET @NewQuantity = @PreviousQuantity + @Pints

                            --PRINT 'UPDATE WaterStack' -- no existing update method, raw SQL below
                            
                            UPDATE [dbo].[WaterStack]
                            SET [WaterStack].[Volume] = @NewQuantity
                            FROM [dbo].[WaterStack] AS [WS]
                            JOIN [dbo].[MasterDates] AS [MD] ON [WS].[WaterID] = [MD].[ID]
                            WHERE [MD].[EDISID] = @EDISID
                            AND [MD].[Date] = @DispenseDate
                            AND [WS].[Line] = @Pump
                            AND [WS].[Time] = @DispenseTime

                        END
                        ELSE
                        BEGIN
                            -- Add new
                            --PRINT 'EXEC AddWaterStack @EDISID, @DispenseDate, @DispenseTime, @Pump, @Pints'
                            EXEC AddWaterStack @EDISID, @DispenseDate, @DispenseTime, @Pump, @Pints
                        END
                    END
                    ELSE IF @LiquidType = 3 -- Cleaner
                    BEGIN
                        -- If this gives us a value, we can trust that some dispense already exists in CleaningStack for this Pump+Shift
                        SELECT @MasterDate = [Date], @PreviousQuantity = [C].[Volume]
                        FROM [dbo].[MasterDates] AS [MD]
                        JOIN [dbo].[CleaningStack] AS [C] ON [MD].[ID] = [C].[CleaningID]
                        WHERE
                            [EDISID] = @EDISID
                        AND [Time] = @DispenseTime
                        AND [Line] = @Pump
                        AND [MD].[Date] = @DispenseDate

                        -- If dispense already exists, assume we must add our amount to the existing total. 
                        IF @MasterDate IS NOT NULL
                        BEGIN
                            -- Add to existing
                            SET @NewQuantity = @PreviousQuantity + @Pints

                            --PRINT 'UPDATE CleaningStack' -- no existing update method, raw SQL below

                            UPDATE [dbo].[CleaningStack]
                            SET [CleaningStack].[Volume] = @NewQuantity
                            FROM [dbo].[CleaningStack] AS [CS]
                            JOIN [dbo].[MasterDates] AS [MD] ON [CS].[CleaningID] = [MD].[ID]
                            WHERE [MD].[EDISID] = @EDISID
                            AND [MD].[Date] = @DispenseDate
                            AND [CS].[Line] = @Pump
                            AND [CS].[Time] = @DispenseTime

                        END
                        ELSE
                        BEGIN
                            -- Add new
                            --PRINT 'EXEC AddCleaningStack @EDISID, @DispenseDate, @DispenseTime, @Pump, @Pints'
                            EXEC AddCleaningStack @EDISID, @DispenseDate, @DispenseTime, @Pump, @Pints
                        END
                    END
                END
            END
        END
        ELSE
        BEGIN
            SET @Error = 'Prescalar cannot be found for EDISID ' + CAST(@EDISID AS VARCHAR) + ' Pump ' + CAST(@Pump AS VARCHAR) + ' Date ' + CAST(@StartDate AS VARCHAR)
            EXEC dbo.LogError 100, @Error, 'Data Import Service', 'AddDispenseConditionRaw'
        END
    END
    ELSE
    BEGIN
        SET @Error = 'Location cannot be found for EDISID ' + CAST(@EDISID AS VARCHAR) + ' Pump ' + CAST(@Pump AS VARCHAR) + ' Date ' + CAST(@StartDate AS VARCHAR)
        EXEC dbo.LogError 100, @Error, 'Data Import Service', 'AddDispenseConditionRaw'
    END
END
ELSE
BEGIN
    SET @Error = 'Pump cannot be found for EDISID ' + CAST(@EDISID AS VARCHAR) + ' FlowmeterAddress ' + CAST(@FlowmeterAddress AS VARCHAR) + ' Date ' + CAST(@StartDate AS VARCHAR)
    EXEC dbo.LogError 101, @Error, 'Data Import Service', 'AddDispenseConditionRaw'
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDispenseConditionRawWebCalibrator] TO PUBLIC
    AS [dbo];

