CREATE PROCEDURE [dbo].[GetLatestFont]
(
	@EDISID		                INTEGER,
	@Pump		                INTEGER = NULL,
	@Date		                DATETIME,
	@ShowNotInUse		        BIT = 1
)

AS

/*
DECLARE	@EDISID		                INTEGER = 418
DECLARE	@Pump		                INTEGER = NULL --NULL (default)
DECLARE	@Date		                DATETIME = '2017-11-16'
DECLARE	@ShowNotInUse		        BIT = 1
*/

--EXEC [GetFlowmeterProperties] @EDISID, @Date -- Provides a value for every Pump that ever existed on the Site
--EXEC [GetLatestFont] @EDISID, @Pump, @Date, @ShowNotInUse

SET NOCOUNT ON

DECLARE @maxID INT

-- Latest NewCalibrationValues
DECLARE @NewRelevantPFS TABLE ([FontNumber] INT, [PFSID] INT) -- Use for New Cal Values
DECLARE @OrigRelevantPFS TABLE ([FontNumber] INT, [PFSID] INT) -- Use for Orig Cal Values
DECLARE @LatestPFS INT -- Use for Flowmeter Addresses

SELECT @LatestPFS = MAX([ID])
FROM [dbo].[ProposedFontSetups]
JOIN [dbo].[ProposedFontSetupItems] ON [ProposedFontSetups].[ID] = [ProposedFontSetupItems].[ProposedFontSetupID]
WHERE
    [ProposedFontSetups].[EDISID] = @EDISID
AND [ProposedFontSetupItems].[ProposedFontSetupID] IS NOT NULL

INSERT INTO @NewRelevantPFS ([FontNumber], [PFSID])
SELECT
    [ProposedFontSetupItems].[FontNumber],
    MAX([ProposedFontSetupItems].[ProposedFontSetupID]) AS [LatestID]
    --[ProposedFontSetupItems].[OriginalCalibrationValue],
    --[ProposedFontSetupItems].[NewCalibrationValue],
    --*
FROM [dbo].[ProposedFontSetupItems]
INNER JOIN [dbo].[ProposedFontSetups]
    ON [ProposedFontSetupItems].[ProposedFontSetupID] = [ProposedFontSetups].[ID]
WHERE
    [ProposedFontSetups].[EDISID] = @EDISID
AND ([NewCalibrationValue] IS NOT NULL AND [NewCalibrationValue] <> 0)
GROUP BY
    [ProposedFontSetupItems].[FontNumber]

INSERT INTO @OrigRelevantPFS ([FontNumber], [PFSID])
SELECT
    [ProposedFontSetupItems].[FontNumber],
    MAX([ProposedFontSetupItems].[ProposedFontSetupID]) AS [LatestID]
    --[ProposedFontSetupItems].[OriginalCalibrationValue],
    --[ProposedFontSetupItems].[NewCalibrationValue],
    --*
FROM [dbo].[ProposedFontSetupItems]
INNER JOIN [dbo].[ProposedFontSetups]
    ON [ProposedFontSetupItems].[ProposedFontSetupID] = [ProposedFontSetups].[ID]
WHERE
    [ProposedFontSetups].[EDISID] = @EDISID
AND ([OriginalCalibrationValue] IS NOT NULL AND [OriginalCalibrationValue] <> 0)
GROUP BY
    [ProposedFontSetupItems].[FontNumber]
    /*
    The new and original scalar values needs to come from the last occurrance
    The flowmeter address needs to come from the 'real' datetime
    */

/*
SELECT @LatestPFS
SELECT * FROM @NewRelevantPFS
SELECT * FROM @OrigRelevantPFS
*/
/*
SELECT *
FROM PumpSetup
WHERE EDISID = @EDISID
*/

SELECT
    [PumpSetup].[Pump],
    [PumpSetup].[ProductID],
    [PumpSetup].[LocationID],
    [PumpSetup].[InUse],
    [PumpSetup].[BarPosition],
    [PumpSetup].[ValidFrom],
    [PumpSetup].[ValidTo],
    [Products].[Description],
    CASE WHEN [ProposedFontSetupItems].[PhysicalAddress] IS NOT NULL
         THEN [ProposedFontSetupItems].[PhysicalAddress]
         ELSE [ProposedFontSetupItems].[FontNumber]
         END AS [IFMAddress],
    CASE WHEN [NewScalarPFS].[NewCalibrationValue] IS NOT NULL OR [NewScalarPFS].[NewCalibrationValue] <> 0  
         THEN [NewScalarPFS].[NewCalibrationValue]
         ELSE [OrigScalarPFS].[OriginalCalibrationValue]
         END AS [PreviousScalar] -- needs to fall back on other values
FROM [dbo].[PumpSetup]
JOIN [dbo].[Products] ON [PumpSetup].[ProductID] = [Products].[ID]
JOIN [dbo].[ProposedFontSetupItems] ON [PumpSetup].[Pump] = [ProposedFontSetupItems].[FontNumber] AND [ProposedFontSetupItems].[ProposedFontSetupID] = @LatestPFS
LEFT JOIN @NewRelevantPFS AS [NewRelevant] ON [PumpSetup].[Pump] = [NewRelevant].[FontNumber]
LEFT JOIN [dbo].[ProposedFontSetupItems] AS [NewScalarPFS] ON [PumpSetup].[Pump] = [NewScalarPFS].[FontNumber] AND [NewRelevant].[PFSID] = [NewScalarPFS].[ProposedFontSetupID]
LEFT JOIN @OrigRelevantPFS AS [OrigRelevant] ON [PumpSetup].[Pump] = [OrigRelevant].[FontNumber]
LEFT JOIN [dbo].[ProposedFontSetupItems] AS [OrigScalarPFS] ON [PumpSetup].[Pump] = [OrigScalarPFS].[FontNumber] AND [OrigRelevant].[PFSID] = [OrigScalarPFS].[ProposedFontSetupID]
WHERE 
    (@Pump IS NULL OR [PumpSetup].[Pump] = @Pump)
AND [PumpSetup].[EDISID] = @EDISID
AND [PumpSetup].[ValidFrom] <= @Date
AND ([PumpSetup].[ValidTo] >= @Date OR [PumpSetup].[ValidTo] IS NULL)
AND ([PumpSetup].[InUse] = 1 OR @ShowNotInUse = 1)

/* -- Latest PFS Detail
SELECT *
FROM [dbo].[ProposedFontSetupItems]
INNER JOIN [dbo].[ProposedFontSetups]
    ON [ProposedFontSetupItems].[ProposedFontSetupID] = [ProposedFontSetups].[ID]
WHERE
    [ProposedFontSetups].[EDISID] = @EDISID
AND [ProposedFontSetups].[ID] = @LatestPFS
*/

/* -- PFS Pump History
SELECT *
FROM [dbo].[ProposedFontSetupItems]
INNER JOIN [dbo].[ProposedFontSetups]
    ON [ProposedFontSetupItems].[ProposedFontSetupID] = [ProposedFontSetups].[ID]
WHERE
    [ProposedFontSetups].[EDISID] = @EDISID
AND [FontNumber] = 10
ORDER BY [FontNumber], [ProposedFontSetupID]
*/

/*
DELETE FROM ProposedFontSetupCalibrationValues WHERE ProposedFontSetupID = 29626
DELETE FROM ProposedFontSetupItems WHERE ProposedFontSetupID = 29626
DELETE FROM ProposedFontSetups WHERe ID = 29626
*/
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLatestFont] TO PUBLIC
    AS [dbo];

