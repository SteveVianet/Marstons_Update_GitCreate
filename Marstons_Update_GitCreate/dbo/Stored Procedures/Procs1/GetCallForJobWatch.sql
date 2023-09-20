CREATE PROCEDURE [dbo].[GetCallForJobWatch]
(
    @CallID INT
)
AS

/* Based on MoveCallToJobWatch */

/* Debug */
--DECLARE @CallID INT = 6593 -- Independent
--DECLARE @CallID INT = 134248 -- Enterprise
--DECLARE @CallID INT = 6589 -- Independent
--DECLARE @CallID INT = 6452 -- Independent -- GW3 install
--DECLARE @CallID INT = 3588 -- Charles Wells -- Service 7
--DECLARE @CallID INT = 3625 -- Charles Wells

DECLARE @StatusID INT = 1
SELECT @StatusID = [StatusID]
FROM [dbo].[CallStatusHistory]
JOIN (SELECT MAX([ID]) AS [LatestStatusID] FROM CallStatusHistory WHERE [CallID] = @CallID)
    AS [CurrentStatus] ON [CallStatusHistory].[ID] = [CurrentStatus].[LatestStatusID]

/* Get iDraught Status, can affect Job Types */
DECLARE @IsIdraught BIT = 0
SELECT @IsIdraught = [Sites].[Quality]
FROM [dbo].[Sites] 
JOIN [dbo].[Calls] ON [Sites].[EDISID] = [Calls].[EDISID]
WHERE [Calls].[ID] = @CallID

/* Get the relevant Engineer */
DECLARE @EngineerName VARCHAR(255)
SELECT
    @EngineerName = [ContractorEngineers].[Name]
FROM [dbo].[Calls]
LEFT JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[ContractorEngineers] ON [Calls].[EngineerID] = [ContractorEngineers].[ID]
WHERE [Calls].[ID] = @CallID

/* Retrieve the Reasons that are tied to specific Job Types */
DECLARE @Mappings TABLE ([CallReasonTypeId] INT, [JobType] NVARCHAR(100), [ReasonDescription] VARCHAR(1000), [iDraught] BIT)
INSERT INTO @Mappings ([CallReasonTypeId], [JobType], [ReasonDescription], [iDraught])
EXEC [SQL1\SQL1].[ServiceLogger].[dbo].[GetJobWatchTypeMappings]

/* Calculate the correct JobType for each Reason */
DECLARE @ParsedReasons TABLE ([JobType] NVARCHAR(100), [ReasonTypeID] INT, [ReasonType] VARCHAR(1000), [ReasonInfo] VARCHAR(512))
INSERT INTO @ParsedReasons ([JobType], [ReasonTypeID], [ReasonType], [ReasonInfo])
SELECT 
	ISNULL(
		[MappedTypes].[JobType],	-- Use a direct mapping if available
		'Service-' +				-- Otherwise calculate a Service-? JobType based on the calculated SLA
		CAST(
			CASE WHEN [GlobalTypes].[CheckIsKeyTap] = 1 AND [SiteKeyTaps].[Pump] IS NOT NULL
				 THEN COALESCE([CallReasonTypes].[SLAForKeyTap], [GlobalTypes].[SLAForKeyTap], [GlobalTypes].[SLA])
				 ELSE COALESCE([CallReasonTypes].[SLA], [GlobalTypes].[SLA])
				 END
		AS VARCHAR(10))
		) AS [JobType],
	[GlobalTypes].[ID] AS [ReasonTypeID],
	[GlobalTypes].[Description] AS [ReasonType],
	[CallReasons].[AdditionalInfo] AS [ReasonInfo]
FROM [dbo].[CallReasons]
JOIN [dbo].[Calls] ON [CallReasons].[CallID] = [Calls].[ID]
JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[CallReasonTypes] AS [GlobalTypes] ON [CallReasons].[ReasonTypeID] = [GlobalTypes].[ID]
LEFT JOIN @Mappings AS [MappedTypes] ON [CallReasons].[ReasonTypeID] = [MappedTypes].[CallReasonTypeId] AND [MappedTypes].[iDraught] = @IsIdraught
-- The Site may not have a Contract(!)
LEFT JOIN [dbo].[SiteContracts] AS [Contract] ON [Calls].[EDISID] = [Contract].[EDISID]
LEFT JOIN [dbo].[CallReasonTypes] ON [CallReasons].[ReasonTypeID] = [CallReasonTypes].[CallReasonTypeID] AND [CallReasonTypes].[ContractID] = [Contract].[ContractID]
LEFT JOIN [dbo].[PumpSetup] ON [Calls].[EDISID] = [PumpSetup].[EDISID] 
	AND [GlobalTypes].[CheckIsKeyTap] = 1 -- TapType 1 = KEY
	AND [PumpSetup].[ValidTo] IS NULL
	AND (CHARINDEX(':', [CallReasons].[AdditionalInfo], 0) > 0
		AND [PumpSetup].[Pump] = 
			CAST(
				LEFT([CallReasons].[AdditionalInfo], 
					CASE WHEN CHARINDEX(':', [CallReasons].[AdditionalInfo], 0) <= 0 
						 THEN 0 
						 ELSE CHARINDEX(':', [CallReasons].[AdditionalInfo], 0) - 1
						 END) 
			AS INT))
LEFT JOIN [dbo].[SiteKeyTaps] ON [PumpSetup].[EDISID] = [SiteKeyTaps].EDISID AND [PumpSetup].[Pump] = [SiteKeyTaps].[Pump] AND [SiteKeyTaps].[Type] = 1 -- Major (aka Key Tap)
WHERE 
	[CallReasons].[CallID] = @CallID

/* Split Call Reasons by JobWatch JobTypes (abuse of XML PATH for string concatenation) */
DECLARE @SplitReasons TABLE ([JobType] NVARCHAR(100), [WorkDetail] VARCHAR(5000))
INSERT INTO @SplitReasons ([JobType], [WorkDetail])
SELECT
	--[Calls].[ID],
	[MasterReasons].[JobType],
	--[CallReasonTypes].[Description] + ';' +
	[MasterReasons].[ReasonType] + ';' +
	--@CompleteReasons = 
	STUFF( (SELECT '|' + [ReasonInfo]
			FROM @ParsedReasons AS [ParsedReasons]
			WHERE
				[ParsedReasons].[JobType] = [MasterReasons].[JobType]
			AND [ParsedReasons].[ReasonTypeID] = [MasterReasons].[ReasonTypeID]
			ORDER BY [ParsedReasons].[ReasonInfo] ASC--, [CallReasons].[AdditionalInfo] ASC
			FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)')
	,1,1,'') + '~'
FROM @ParsedReasons AS [MasterReasons]
GROUP BY [MasterReasons].[JobType], [MasterReasons].[ReasonType], [MasterReasons].[ReasonTypeID]

/* Combine by matching JobTypes (not done in a single step above to reduce query complexity for our abuse of non-standard XML PATH usage) */
DECLARE @CombinedReasons TABLE ([JobType] NVARCHAR(100), [WorkDetail] VARCHAR(5000))
INSERT INTO @CombinedReasons ([JobType], [WorkDetail])
SELECT 
	[SplitReasons].[JobType],
	(SELECT [CombineReasons].[WorkDetail]
	 FROM @SplitReasons AS [CombineReasons]
	 WHERE [CombineReasons].[JobType] = [SplitReasons].[JobType]
	 ORDER BY [CombineReasons].[WorkDetail] ASC
	 FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)')
FROM @SplitReasons AS [SplitReasons]
GROUP BY [SplitReasons].[JobType]

SELECT
	[Calls].[EDISID] AS [EdisID],
    @CallID AS [CallID],
	[Calls].[RaisedOn],
	[Sites].[SiteID],
    [Sites].[Name],
    [Sites].[PostCode],
	NULL AS [JobId],
    NULL AS [JobReference],
	[CombinedReasons].[JobType],
	[CombinedReasons].[WorkDetail] AS [OriginalJobDescription],
	NULL AS [CurrentJobDescription], -- JobWatch (Custom Field - Working Description)
    ISNULL(@EngineerName, '') AS [EngineerName],
    NULL AS [ResourceName], -- Jobwatch
    CAST(1 AS BIT) AS [JobActive], -- While 1 we need to poll JobWatch for updates on any changes
    CAST(CASE WHEN @StatusID = 6 THEN 1 ELSE 0 END AS BIT) AS [PreRelease],
    CAST(CASE WHEN [POStatusID] IN (1,4) THEN 0 ELSE 1 END AS BIT) AS [AwaitPO], -- 1 = Not Required, 2/3 = Needed, 4 = Obtained (not possible during raise?)
	CAST(CASE WHEN [CombinedReasons].[JobType] LIKE 'Service-%' AND [CombinedReasons].[JobType] NOT IN ('Service-7','Service-14','Service-28')
		 THEN 1
		 ELSE 0
		 END AS BIT) AS [Invalid],
    CAST(0 AS BIT) AS [Posted],
    '' AS [PostResults]
FROM [dbo].[Calls]
JOIN [dbo].[Sites] ON [Calls].[EDISID] = [Sites].[EDISID]
CROSS APPLY @CombinedReasons AS [CombinedReasons]
LEFT JOIN [dbo].[JobWatchCalls] ON [JobWatchCalls].[CallID] = @CallID
WHERE [Calls].[ID] = @CallID
AND [JobWatchCalls].[EdisID] IS NULL -- Call has not been previously processed (should be deleted once done)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallForJobWatch] TO PUBLIC
    AS [dbo];

