CREATE PROCEDURE [dbo].[ExceptionIFMStoppedIssue]
(
	@EDISID INT = NULL,
	@Auditor varchar(255) = NULL
)
AS

/* For Testing */ 
--DECLARE @EDISID INT = NULL
--DECLARE @Auditor VARCHAR(255)

SET NOCOUNT ON;

DECLARE @From DATETIME = DATEADD(DAY, -1, GETDATE())

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = 'ExceptionIFMStoppedIssue' -- Do we have permission to access this?
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @From, NULL
END

-- Get the IFM addresses for the date in question
-- Stolen from [dbo].[GetPumpAddressesForDay]
DECLARE @IFMs TABLE (EDISID INT NOT NULL, CreateDate DATE NOT NULL, CurrentDate DATE NOT NULL, Pump INT NOT NULL, IFM INT NOT nULL)

INSERT INTO @IFMs (EDISID, CreateDate, CurrentDate, Pump, IFM)
SELECT
    PFS.EDISID,
    CAST(PFS.CreateDate AS DATE) AS CreateDate,
    CAST(@From AS DATE) AS CurrentDate,
    PFSI.FontNumber,
    PFSI.PhysicalAddress
FROM ProposedFontSetups AS PFS
JOIN (
    SELECT 
        EDISID,
        MAX(PFS.ID) AS [RelevantPFS]
    FROM dbo.ProposedFontSetups AS PFS
    WHERE 
        (@EDISID IS NULL OR PFS.EDISID = @EDISID)
    AND CAST(CreateDate AS DATE) <= @From
    GROUP BY [EDISID]
    ) AS [RelevantPFS] ON [PFS].[ID] = [RelevantPFS].[RelevantPFS] AND [PFS].[EDISID] = [RelevantPFS].[EDISID]
LEFT JOIN ProposedFontSetupItems AS PFSI ON PFS.ID = PFSI.ProposedFontSetupID
Join Sites on Sites.EDISID = PFS.EDISID
WHERE 
    (@EDISID IS NULL OR PFS.EDISID = @EDISID)
AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND PFSI.PhysicalAddress > 400 -- Only IFMs

/*
-- LEGACY LOGGER
-- Get all non-closed Calls which involve IFMs
-- Stolen from [dbo].[GetCalls]
CREATE TABLE #IFMCalls (CallID INT NOT NULL, EDISID INT NOT NULL, IFMAddress INT NOT NULL, Pump INT NOT NULL)
INSERT INTO #IFMCalls (CallID, EDISID, IFMAddress, Pump)
SELECT
    Calls.[ID],
	Calls.EDISID,
    IFMs.IFM,
    SIQ.RealPumpID
FROM dbo.CallsSLA AS Calls WITH (NOLOCK)
JOIN dbo.CallStatusHistory WITH (NOLOCK) ON CallStatusHistory.CallID = Calls.[ID]
LEFT JOIN dbo.SupplementaryCallStatusItems ON SupplementaryCallStatusItems.CallID = Calls.[ID]
LEFT JOIN dbo.CallStatusHistory AS InProgressStatus 
	ON InProgressStatus.CallID = Calls.[ID]
	AND InProgressStatus.StatusID <> 1
	AND InProgressStatus.[ID] =	(SELECT MIN(CallStatusHistory.[ID])
					FROM dbo.CallStatusHistory
					WHERE CallID = Calls.[ID]
					AND CallStatusHistory.StatusID <> 1)
LEFT JOIN dbo.CallStatusHistory AS MostRecentOnHoldStatus
	ON MostRecentOnHoldStatus.CallID = Calls.[ID]
	AND MostRecentOnHoldStatus.StatusID = 2
	AND MostRecentOnHoldStatus.[ID] =	(SELECT MAX(CallStatusHistory.[ID])
						FROM dbo.CallStatusHistory
						WHERE CallID = Calls.[ID]
						AND CallStatusHistory.StatusID = 2)
LEFT JOIN dbo.CallStatusHistory AS SubsequentOnHoldStatus
	ON SubsequentOnHoldStatus.CallID = Calls.[ID]
	AND SubsequentOnHoldStatus.StatusID <> 2
	AND SubsequentOnHoldStatus.[ID] =	(SELECT MIN(CallStatusHistory.[ID])
						FROM dbo.CallStatusHistory
						WHERE CallID = Calls.[ID]
						AND CallStatusHistory.[ID] > MostRecentOnHoldStatus.[ID])
LEFT JOIN dbo.CallStatusHistory AS PreviousCallStatus
	ON PreviousCallStatus.CallID = Calls.[ID]
	AND PreviousCallStatus.[ID] =	(SELECT MAX(InnerCallStatusHistory.[ID])
					FROM dbo.CallStatusHistory AS InnerCallStatusHistory
					WHERE CallID = Calls.[ID]
					AND InnerCallStatusHistory.[ID] <> CallStatusHistory.[ID])
LEFT JOIN dbo.ServiceIssuesQuality AS SIQ ON Calls.ID = SIQ.CallID AND Calls.EDISID = SIQ.EDISID
LEFT JOIN @IFMs AS IFMs ON SIQ.RealEDISID = IFMs.EDISID AND SIQ.RealPumpID = IFMs.Pump
WHERE 
    CallStatusHistory.[ID] = (
        SELECT MAX(CallStatusHistory.[ID])
		FROM dbo.CallStatusHistory
		WHERE CallID = Calls.[ID]
        )
AND (SupplementaryCallStatusItems.[ID] = (
        SELECT MAX(SupplementaryCallStatusItems.[ID])
		FROM dbo.SupplementaryCallStatusItems
		WHERE CallID = Calls.[ID]
        )
    OR SupplementaryCallStatusItems.[ID] IS NULL)
AND ((CallStatusHistory.StatusID = 1) -- Open
    OR (CallStatusHistory.StatusID = 2) -- On-Hold
    OR (CallStatusHistory.StatusID = 3) -- In-Progress
    OR (CallStatusHistory.StatusID = 6)) -- Pre-Raised
AND SIQ.RealPumpID IS NOT NULL
AND IFMs.IFM IS NOT NULL
*/

-- JOB WATCH
CREATE TABLE #IFMCalls (EDISID INT NOT NULL, IFMAddress INT NOT NULL, Pump INT NOT NULL)
INSERT INTO #IFMCalls (EDISID, IFMAddress, Pump)
SELECT
    [JobWatchCalls].[EdisID],
    [JobWatchCallsData].[IFMAddress],
    [JobWatchCallsData].[Pump]
FROM [dbo].[JobWatchCalls]
JOIN [dbo].[JobWatchCallsData] ON [JobWatchCalls].[JobId] = [JobWatchCallsData].[JobId]
WHERE [JobWatchCalls].[JobActive] = 1
AND [JobWatchCallsData].[Pump] IS NOT NULL
AND [JobWatchCallsData].[IFMAddress] IS NOT NULL

--SELECT * FROM #IFMCalls

CREATE TABLE #Exceptions ([EDISID] INT NOT NULL, [IFM] INT NOT NULL, [Pump] INT NOT NULL, [Product] VARCHAR(50) NOT NULL)
INSERT INTO #Exceptions ([EDISID], [IFM], [Pump], [Product])

SELECT 
    [S].[EDISID],
    [I].[IFM],
    [PS].[Pump],
    [P].[Description] AS [Product]
    --SUM(ISNULL([DA].[Pints], 0)) AS [Volume],
    --COUNT([IC].[CallID]) AS [ActiveCall]
FROM @IFMs AS [I]
JOIN [dbo].[Sites] AS [S] ON [I].[EDISID] = [S].[EDISID]
JOIN [dbo].[PumpSetup] AS [PS] ON [S].[EDISID] = [PS].[EDISID] AND [I].[Pump] = [PS].[Pump]
JOIN [dbo].[Products] AS [P] ON [PS].[ProductID] = [P].[ID]
LEFT JOIN [dbo].[DispenseActions] AS [DA] ON [S].[EDISID] = [DA].[EDISID] AND [DA].[Pump] = [I].Pump AND [DA].[StartTime] >= DATEADD(DAY, -1, [S].[LastDownload])
LEFT JOIN #IFMCalls AS [IC] ON [DA].[EDISID] = [IC].[EDISID] AND [DA].[Pump] = [IC].[Pump]
WHERE
    [S].[LastDownload] >= @From
AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
AND(@Auditor IS NULL OR SiteUser = @Auditor)
AND ([PS].[ValidTo] IS NULL AND [PS].[InUse] = 1) -- Only Include Pumps marked as being Active
GROUP BY
    [S].[EDISID],
    [I].[IFM],
    [PS].[Pump],
    [P].[Description]
HAVING 
    SUM(ISNULL([DA].[Pints], 0)) = 0 -- No dispense
--AND COUNT([IC].[CallID]) = 0 -- No Active Call
AND COUNT([IC].[EDISID]) = 0 -- No Active Call
ORDER BY
    [S].[EDISID],
    [PS].[Pump]

SELECT DISTINCT
    [E].[EDISID],
    'Red - ' +
    SUBSTRING(
        (   SELECT ';' + CAST([Pump] AS VARCHAR(10)) + '|' + [Product] + '|' + CAST([IFM] AS VARCHAR(10))
            FROM #Exceptions
            WHERE [EDISID] = [E].[EDISID]
            FOR XML PATH (''), TYPE).value('.','VARCHAR(4000)')
        ,2, 4000) AS [IFMList]
FROM #Exceptions AS [E]
    
DROP TABLE #IFMCalls
DROP TABLE #Exceptions

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionIFMStoppedIssue] TO PUBLIC
    AS [dbo];

