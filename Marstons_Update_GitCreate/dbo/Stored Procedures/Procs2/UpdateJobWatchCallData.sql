CREATE PROCEDURE [dbo].[UpdateJobWatchCallData]
(
    @JobId INT,
    @Reason NVARCHAR(512),
    @ReasonInfo NVARCHAR(512)
)
AS


--DECLARE @JobId INT = 8105921
--DECLARE @Reason NVARCHAR(512) = N'Pulled all meters out from trunking. Stripped old clips and pipe off them. Soaked and checked meters only 4 retrievable due to short and damaged cables. Fitted 9 refurb fm. Refit mini panel has hanging loose. Once wired up could not connect. Found antenna cable severed just outside drop. Replaced antenna, connected and verified. Unable to calibrate today due to inconvenience behind bar. Also new product (carling black fruits) not being delivered till friday. Calibration and csd replacement scheduled on the 04/07/18Flowmeter not recording dispense'
--DECLARE @ReasonInfo NVARCHAR(512) = N'16: Water Line (CELLAR)'

--DECLARE @JobId INT = 6460330
--DECLARE @Reason NVARCHAR(512) = N'New Flowmeter required'
--DECLARE @ReasonInfo NVARCHAR(512) = N'hfkhkjhgvkyougl'

--EdisID    CallRef JobId   JobReference    JobType OriginalJobDescription
--1745  44-6459/CC  6174381 SRV3497 Service-28  Ambient temperature sensor fault;23456: test ambient (Ambient Temperature)~

--DECLARE @JobId INT = 6384131
--DECLARE @Reason NVARCHAR(512) = 'Flowmeter check required - recording dispense anomalies'
--DECLARE @ReasonInfo NVARCHAR(512) = '16: Strongbow Dark Fruit (Bar)'
--DECLARE @ReasonInfo NVARCHAR(512) = '4: Strongbow (Bar)'
--DECLARE @Reason NVARCHAR(512) = 'Flowmeter not recording dispense'
--DECLARE @ReasonInfo NVARCHAR(512) = '1: Guinness (Bar)'

-- 22
--DECLARE @Reason NVARCHAR(512) = 'Flowmeter not recording dispense'
--DECLARE @ReasonInfo NVARCHAR(512) = '16: Water Line (CELLAR) - Large blocks of line cleaning evident despite the water line not recording.'

-- 21
--DECLARE @Reason NVARCHAR(512) = 'New Flowmeter required'
--DECLARE @ReasonInfo NVARCHAR(512) = '19: San Miguel'

-- 24
--DECLARE @Reason NVARCHAR(512) = 'Product detection incorrect'
--DECLARE @ReasonInfo NVARCHAR(512) = '6: Cask Ale 2 (Bar) - 0x1B598 - recording as unknown, high temp and 0 conductiviy.'
--DECLARE @ReasonInfo NVARCHAR(512) = '1: Guinness (Bar) - recording as unknown with high temperature and 0 conductivity'

-- 28
--DECLARE @Reason NVARCHAR(512) = 'Ambient temperature sensor fault'
--DECLARE @ReasonInfo NVARCHAR(512) = '23456: test ambient (Ambient Temperature)'

--33
--DECLARE @Reason NVARCHAR(512) = 'Calibration request'
--DECLARE @ReasonInfo NVARCHAR(512) = '7: Brooklyn Pale Ale (Bar) 0x23A25 Heienken now on this line.'

DECLARE @ReasonID INT
DECLARE @HasEquipmentData BIT = 0
DECLARE @HasProductData BIT = 0

SELECT @ReasonID = [ID], @HasProductData = [ShowProducts], @HasEquipmentData = [ShowEquipment]
FROM [SQL1\SQL1].[ServiceLogger].[dbo].[CallReasonTypes]
WHERE [Description] = @Reason

--IF (@ReasonID IN (
--    21, -- New Product Keg\Syrup
--    22, -- Pulse Meter Stopped Keg, Water Line
--    23, -- Flowmeter Check Req. - Recording Dispense Anomalies (not currently required for exceptions)
--    24, -- IFM Stopped, IFM Temperature
--    25, -- IFM Stopped, IFM Temperature
--    29, -- System Not Answering
--    30, -- System Not Answering
--    33, -- Traffic Lights, Pouring Yield
--    38, -- Equipment Failed, Equipment Temperature
--    40, -- Equipment Failed, Equipment Temperature
--    59, -- New Product Keg\Syrup
--    63, -- Traffic Lights, Pouring Yield
--    64  -- New Product Keg\Syrup
--    ))
--IF @ReasonID IS NOT NULL
BEGIN
    /* If we have a Reason we need to know the detail for, split it by the type of data we can extract */
    DECLARE @Address INT
    DECLARE @Pump INT
    DECLARE @Product VARCHAR(255)
    DECLARE @ProductID INT

    DECLARE @CharIndex INT = CHARINDEX(':', @ReasonInfo, 0)

    
    IF ((@HasEquipmentData=1 OR @ReasonID IN (38, 40)) AND (@CharIndex > 0))
    BEGIN
        -- EquipmentAddress
        SELECT @Address = CAST(LEFT(@ReasonInfo, CHARINDEX(':', @ReasonInfo, 0)-1) AS INT)
        
        IF (@Address IS NOT NULL)
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM [JobWatchCallsData] WHERE [JobId] = @JobId AND [CallReasonTypeID] = @ReasonID AND [EquipmentAddress] = @Address)
            BEGIN
                INSERT INTO [dbo].[JobWatchCallsData] ([JobId], [CallReasonTypeID], [EquipmentAddress])
                VALUES (@JobId, @ReasonID, @Address)
            END
        END
    END
    ELSE IF (@ReasonID IN (24, 25) AND (@CharIndex > 0))
    BEGIN
        -- IFMAddress, Pump, Product (nice-to-have)
        -- May be difficult to isolate the IFMAddress (appears to be manually entered?)
        SELECT @Pump = CAST(LEFT(@ReasonInfo, CHARINDEX(':', @ReasonInfo, 0)-1) AS INT)
        
        SELECT @Product = SUBSTRING(@ReasonInfo, CHARINDEX(':', @ReasonInfo, 0)+2, 
            CASE WHEN CHARINDEX('(', @ReasonInfo, 0) = 0 THEN LEN(@ReasonInfo) ELSE CHARINDEX('(', @ReasonInfo, 0) - (CHARINDEX(':', @ReasonInfo, 0)+2) END)

        IF CHARINDEX('0x', @ReasonInfo, 0) > 0
        BEGIN TRY
            -- Best efforts to try and decode a hex address from the string
            DECLARE @SubString NVARCHAR(255) = SUBSTRING(@ReasonInfo, CHARINDEX('0x', @ReasonInfo, 0)+2, LEN(@ReasonInfo))
            SELECT @Address = CONVERT(INT, CONVERT(VARBINARY, RIGHT('00000000' + SUBSTRING(@SubString, 0, CHARINDEX(' ', @SubString, 0)), 8), 2))
        END TRY
        BEGIN CATCH
            -- We found something, but couldn't parse it successfully
            SET @Address = NULL
        END CATCH

        SELECT @ProductID = [ID]
        FROM [dbo].[Products]
        WHERE [Description] = @Product

        IF NOT EXISTS (SELECT 1 FROM [JobWatchCallsData] WHERE [JobId] = @JobId AND [CallReasonTypeID] = @ReasonID AND [ProductID] = @ProductID)
        BEGIN
            INSERT INTO [dbo].[JobWatchCallsData] ([JobId], [CallReasonTypeID], [ProductID])
            VALUES (@JobId, @ReasonID, @ProductID) -- ProductID may still be NULL if we couldn't get a match
        END
    END
    --ELSE IF (@ReasonID IN ()) -- (22 moved into the next section as we can likely extract the Product information too, or at least attempt to)
    --BEGIN
    --    -- Pump
    --    SELECT @Pump = CAST(LEFT(@ReasonInfo, CHARINDEX(':', @ReasonInfo, 0)-1) AS INT)

    --    IF (@Pump IS NOT NULL)
    --    BEGIN
    --        IF NOT EXISTS (SELECT 1 FROM [JobWatchCallsData] WHERE [JobId] = @JobId AND [CallReasonTypeID] = @ReasonID AND [Pump] = @Pump)
    --        BEGIN
    --            INSERT INTO [dbo].[JobWatchCallsData] ([JobId], [CallReasonTypeID], [Pump])
    --            VALUES (@JobId, @ReasonID, @Pump)
    --        END
    --    END
    --END
    ELSE IF ((@HasProductData=1 OR @ReasonID IN (21, 22, 23, 33, 59, 64)) AND (@CharIndex > 0))
    BEGIN
        -- Product (and Pump, not required for Exceptions)
        --SELECT CHARINDEX(':', @ReasonInfo, 0)

        SELECT @Pump = CAST(LEFT(@ReasonInfo, CHARINDEX(':', @ReasonInfo, 0)-1) AS INT)

        -- Best attempt to extract a Product Name
        SELECT @Product = SUBSTRING(@ReasonInfo, CHARINDEX(':', @ReasonInfo, 0)+2, 
            CASE WHEN CHARINDEX('(', @ReasonInfo, 0) = 0 THEN LEN(@ReasonInfo) ELSE CHARINDEX('(', @ReasonInfo, 0) - (CHARINDEX(':', @ReasonInfo, 0)+2) END)

        SELECT @ProductID = [ID]
        FROM [dbo].[Products]
        WHERE [Description] = @Product

        IF NOT EXISTS (SELECT 1 FROM [JobWatchCallsData] WHERE [JobId] = @JobId AND [CallReasonTypeID] = @ReasonID AND [ProductID] = @ProductID AND [Pump] = @Pump)
        BEGIN
            INSERT INTO [dbo].[JobWatchCallsData] ([JobId], [CallReasonTypeID], [ProductID], [Pump])
            VALUES (@JobId, @ReasonID, @ProductID, @Pump) -- ProductID may still be NULL if we couldn't get a match
        END
    END
    --ELSE IF (@ReasonID IN (29,30,63))
    ELSE
    BEGIN
        -- None (or we are missing a required character ':')
        IF NOT EXISTS (SELECT 1 FROM [JobWatchCallsData] WHERE [JobId] = @JobId AND [CallReasonTypeID] = @ReasonID)
        BEGIN
            INSERT INTO [dbo].[JobWatchCallsData] ([JobId], [CallReasonTypeID])
            VALUES (@JobId, @ReasonID)
        END
    END


    /* Taken from Logger */
    DECLARE @ExcludeFromQuality BIT
    DECLARE @ExcludeFromYield BIT
    DECLARE @ExcludeFromEquipment BIT
    DECLARE @ExcludeAllProducts	BIT

    SELECT	@ExcludeFromQuality = ExcludeFromQuality,
		    @ExcludeFromYield = ExcludeFromYield,
		    @ExcludeFromEquipment = ExcludeFromEquipment,
		    @ExcludeAllProducts = ExcludeAllProducts
    FROM [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes
    WHERE [ID] = @ReasonID

    DECLARE @AdditionalID INT = COALESCE(@Address, @Pump, 0)
    DECLARE @CallID INT
    DECLARE @StartDate DATE

    SELECT @StartDate = [CreatedOn], @CallID = [CallID]
    FROM [dbo].[JobWatchCalls] 
    WHERE [JobId] = @JobId

    --SELECT	@ExcludeFromQuality,
		  --  @ExcludeFromYield,
		  --  @ExcludeFromEquipment,
		  --  @ExcludeAllProducts

    SELECT @CallID, @AdditionalID, @ExcludeAllProducts, @StartDate, @ReasonID

    IF @ExcludeFromQuality = 1
    BEGIN
	    EXEC dbo.AddServiceIssueQuality @CallID, @AdditionalID, @ExcludeAllProducts, @StartDate, @ReasonID
    END

    IF @ExcludeFromYield = 1
    BEGIN
	    EXEC dbo.AddServiceIssueYield @CallID, @AdditionalID, @ExcludeAllProducts, @StartDate, @ReasonID
    END

    IF @ExcludeFromEquipment = 1
    BEGIN
	    EXEC dbo.AddServiceIssueEquipment @CallID, @AdditionalID, @ExcludeAllProducts, @StartDate, @ReasonID
    END
END

-- Patch to cover updating Jobs which are already Completed
BEGIN
    DECLARE @StatusId INT
    SELECT @StatusId = [StatusId]
    FROM [dbo].[JobWatchCalls]
    WHERE [JobId] = @JobId

    IF @StatusId IN (12,13) -- Completed, Completed (with Issues)
    BEGIN
        /* Check if we need to touch the Installation Date */
        IF EXISTS (SELECT TOP 1 1 FROM [dbo].[JobWatchCallsData] WHERE [JobId] = @JobId AND [CallReasonTypeID] IN (1,19,80)) -- Installation (new system), Replace panel only, Tech Refresh GW3
        BEGIN
            -- Installation (new system) or Replace panel only
            DECLARE @EdisID INT
            DECLARE @Completed DATE
            SELECT
                @EdisID = [EdisID],
                @Completed = [StatusLastChanged]
            FROM [dbo].[JobWatchCalls]
            WHERE 
                [JobId] = @JobId

            IF @EdisID IS NOT NULL
            BEGIN
                EXEC [dbo].[UpdateSiteInstallationDate] @EdisID, @Completed
            END
        END
    END
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateJobWatchCallData] TO PUBLIC
    AS [dbo];

