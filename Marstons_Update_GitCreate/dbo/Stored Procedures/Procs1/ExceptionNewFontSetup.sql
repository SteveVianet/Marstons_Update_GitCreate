CREATE PROCEDURE [dbo].[ExceptionNewFontSetup]
(
	@EDISID int = NULL,
	@Auditor varchar(255) = NULL
)
AS

/* For Testing */
--DECLARE @EDISID INT = NULL

SET DATEFIRST 1;

DECLARE @Today DATE = GETDATE()
DECLARE @CurrentWeek DATE
SET @CurrentWeek = DATEADD(DAY, 1-DATEPART(WEEKDAY, @Today), @Today)

DECLARE @CurrentWeekFrom		DATE
DECLARE @To						DATE

SET @CurrentWeekFrom = @CurrentWeek
SET @To = DATEADD(day, 6, @CurrentWeekFrom)

DECLARE @DatabaseID INT
SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
DECLARE @NotificationTypeID INT
SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
IF @NotificationTypeID IS NOT NULL
BEGIN
    EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, NULL, @Today
END

CREATE TABLE #Sites([EDISID] INT NOT NULL, [Hidden] BIT NOT NULL)

INSERT INTO #Sites ([EDISID], [Hidden])
SELECT 
    [EDISID], 
    [Hidden]
FROM [dbo].[Sites]
WHERE 
    [Hidden] = 0
AND (@EDISID IS NULL OR [EDISID] = @EDISID)
AND(@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
AND [SiteOnline] <= @To

SELECT
    [S].[EDISID]
    --* -- For Testing
FROM #Sites AS [S]
--JOIN [dbo].[Sites] ON [S].[EDISID] = [Sites].[EDISID] -- For Testing
INNER JOIN [dbo].[ProposedFontSetups] 
    AS [PFS] ON [S].[EDISID] = [PFS].[EDISID]
LEFT JOIN [dbo].[Calls]
    AS [C] ON [PFS].[CallID] = [C].[ID]
WHERE 
    [PFS].[Completed] = 0
AND [PFS].[CreateDate] > DATEADD(DAY, -1, @Today)
AND [PFS].[Available] = 1
AND ([C].[AbortReasonID] IS NULL OR [C].[AbortReasonID] = 0) -- Changed to allow Font Setups which are not associated with a Service Call
--AND [C].[CallTypeID] = 2  -- Disabled to show any unactioned Font Setup whether for a new Site (Installation) or existing Site (Service)
GROUP BY [S].[EDISID]

DROP TABLE #Sites
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionNewFontSetup] TO PUBLIC
    AS [dbo];

