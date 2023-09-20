CREATE PROCEDURE [dbo].[ExceptionServiceCallOnHold]
(
	@EDISID INT = NULL,
	@Auditor VARCHAR(255) = NULL
)
AS

DECLARE @DisableComments BIT = 0
DECLARE @DebugSites BIT = 0
DECLARE @DebugComments BIT = 0

/* For Testing */
--DECLARE @Auditor VARCHAR(50) = NULL
--DECLARE @EDISID INT = NULL --30
--DECLARE @SiteID VARCHAR (15) = NULL --'201865'
--IF @SiteID IS NOT NULL
--    SELECT @EDISID = [EDISID] FROM [dbo].[Sites] WHERE [SiteID] = @SiteID

--SET @DisableComments = 1
--SET @DebugSites = 1
--SET @DebugComments = 1

SET NOCOUNT ON;
SET DATEFIRST 1;

DECLARE @CurrentWeek	DATETIME = GETDATE()
SET @CurrentWeek = DATEADD(dd, 1-DATEPART(dw, @CurrentWeek), @CurrentWeek)

DECLARE @CurrentWeekFrom		DATETIME
DECLARE @To						DATETIME
DECLARE @Today					DATETIME

SET @CurrentWeekFrom = @CurrentWeek
SET @To = DATEADD(day, 6, @CurrentWeekFrom)

CREATE TABLE #Sites(EDISID INT, [Hidden] BIT, [Email] VARCHAR(200))

DECLARE @MultiAuditor BIT
DECLARE @DatabaseID INT


BEGIN
    SELECT @DatabaseID = [ID] FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases] WHERE [Name] = DB_NAME()
    DECLARE @NotificationTypeID INT
    SELECT @NotificationTypeID = [NotificationTypeID] FROM [SQL1\SQL1].[Auditing].[dbo].[NotificationType] WHERE [StoredProcedure] = OBJECT_NAME(@@PROCID)
    IF @NotificationTypeID IS NOT NULL
    BEGIN
        EXEC [SQL1\SQL1].[Auditing].[dbo].[AddNotificationTypeGenerationLog] @NotificationTypeID, @DatabaseID, @EDISID, @CurrentWeekFrom, @To
    END
END

SELECT @MultiAuditor = [MultipleAuditors] 
FROM [SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases]
WHERE [ID] = @DatabaseID

IF @MultiAuditor = 1
BEGIN -- Database Supports per-Site Auditor assignments
    INSERT INTO #Sites ([EDISID], [Hidden], [Email])
    SELECT 
        [S].[EDISID], 
        [S].[Hidden],
        CASE WHEN RTRIM(LTRIM([S].[SiteUser])) = '' THEN [Auditor].[PropertyValue] ELSE REPLACE(LOWER([S].[SiteUser]), 'maingroup\', '') + '@vianetplc.com' END AS [Auditor]
    FROM [dbo].[Sites] AS [S]
    CROSS APPLY (
        SELECT [PropertyValue]
        FROM [dbo].[Configuration]
        WHERE [PropertyName] = 'AuditorEMail'
    ) AS [Auditor] -- Used as a fallback when no one is assigned to the Site
    WHERE [S].[Hidden] = 0
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
	AND (@Auditor IS NULL OR LOWER(SiteUser) = LOWER(@Auditor))
    AND [S].[SiteOnline] <= @To
    AND [S].[Status] IN (1,3,8,10) -- Active, FOT, Legals, System to be Refit
END
ELSE
BEGIN -- Database Supports only one estate-level Auditor
    INSERT INTO #Sites ([EDISID], [Hidden], [Email])
    SELECT 
        [S].[EDISID], 
        [S].[Hidden],
        [Auditor].[PropertyValue]
    FROM [dbo].[Sites] AS [S]
    CROSS APPLY (
        SELECT [PropertyValue]
        FROM [dbo].[Configuration]
        WHERE [PropertyName] = 'AuditorEMail'
    ) AS [Auditor]
    WHERE [S].[Hidden] = 0
    AND (@EDISID IS NULL OR [S].[EDISID] = @EDISID)
    AND [S].[SiteOnline] <= @To
    AND [S].[Status] IN (1,3,8,10) -- Active, FOT, Legals, System to be Refit
END

IF @DebugSites = 1
BEGIN
    SELECT * 
    FROM #Sites AS [S]
    JOIN [dbo].[Sites] AS [Si] ON [S].EDISID = [Si].[EDISID]
END

/*
-- LEGACY LOGGER
DECLARE @CommentType INT = 1
DECLARE @CommentHeadingType INT = 3015
DECLARE @CommentTemplate VARCHAR(1000) = '{CallRef}: On-Hold for {Days} Days - Contact {AdvisorEmail}'

DECLARE @OnHoldStatus INT = 2

CREATE TABLE #Comments ([EDISID] INT NOT NULL PRIMARY KEY, [CallRef] VARCHAR(16)NOT NULL, [LatestChangeDate] DATETIME NOT NULL, [Comment] VARCHAR(1000) NOT NULL, [Detail] VARCHAR(1000) NOT NULL)
INSERT INTO #Comments ([EDISID], [CallRef], [LatestChangeDate], [Comment], [Detail])
SELECT DISTINCT 
    [C].[EDISID],
    [LatestCallChanges].[CallRef],
    [LatestChangeDate],
    REPLACE(REPLACE(REPLACE(@CommentTemplate, '{CallRef}', [LatestCallChanges].[CallRef]), '{Days}', CAST(DATEDIFF(DAY, [LatestChangeDate], GETDATE()) AS VARCHAR(10))), '{AdvisorEmail}', [S].[Email]) AS [Comment],
    [LatestCallChanges].[CallRef] + '|' + CAST(DATEDIFF(DAY, [LatestChangeDate], GETDATE()) AS VARCHAR(10)) + ' Days' AS [Detail]
FROM [dbo].[CallStatusHistory] AS [CSH]
INNER JOIN (
    SELECT 
        [CallID], 
        [dbo].[GetCallReference]([CallID]) AS [CallRef],
        MAX([ChangedOn]) AS [LatestChangeDate]
    FROM [dbo].[CallStatusHistory]
    GROUP BY [CallID]
    ) AS [LatestCallChanges] ON [LatestCallChanges].CallID = [CSH].[CallID]
INNER JOIN [dbo].[Calls] AS [C] 
    ON [C].[ID] = [CSH].[CallID]
    AND [LatestCallChanges].[LatestChangeDate] = [CSH].[ChangedOn]
INNER JOIN #Sites AS [S]
    ON [S].[EDISID] = [C].[EDISID]
WHERE [CSH].[StatusID] = @OnHoldStatus
*/

-- JOB WATCH
DECLARE @CommentType INT = 1
DECLARE @CommentHeadingType INT = 3015
DECLARE @CommentTemplate VARCHAR(1000) = '{CallRef}: On-Hold for {Days} Days - Contact {AdvisorEmail}'

DECLARE @OnHoldStatus INT = 11 -- Suspended

CREATE TABLE #Comments ([EDISID] INT NOT NULL PRIMARY KEY, [CallRef] VARCHAR(16)NOT NULL, [LatestChangeDate] DATETIME NOT NULL, [Comment] VARCHAR(1000) NOT NULL, [Detail] VARCHAR(1000) NOT NULL)
INSERT INTO #Comments ([EDISID], [CallRef], [LatestChangeDate], [Comment], [Detail])
SELECT 
    [JobWatchCalls].[EdisID],
    [JobWatchCalls].[JobReference],
    [JobWatchCalls].[StatusLastChanged],
    REPLACE(REPLACE(REPLACE(@CommentTemplate, '{CallRef}', [JobWatchCalls].[JobReference]), '{Days}', CAST(DATEDIFF(DAY, [JobWatchCalls].[StatusLastChanged], GETDATE()) AS VARCHAR(10))), '{AdvisorEmail}', [S].[Email]) AS [Comment],
    [JobWatchCalls].[JobReference] + '|' + CAST(DATEDIFF(DAY, [JobWatchCalls].[StatusLastChanged], GETDATE()) AS VARCHAR(10)) + ' Days' AS [Detail]
FROM [dbo].[JobWatchCalls]
JOIN #Sites AS [S]
    ON [S].[EDISID] = [JobWatchCalls].[EdisID]
WHERE [JobWatchCalls].[StatusId] = @OnHoldStatus

IF @DebugComments = 1
BEGIN
    SELECT * FROM #Comments
END

DECLARE @CurrentEDISID INT 
DECLARE @CurrentCallRef VARCHAR(16)
DECLARE @CurrentLatestChangeDate DATETIME
DECLARE @CurrentComment VARCHAR(1000)

DECLARE @MatchedCommentID INT
DECLARE @NewCommentID INT
DECLARE @Now DATETIME = GETDATE()

DECLARE OnHoldCalls CURSOR FAST_FORWARD FOR
SELECT
    [EDISID],
    [CallRef],
    [LatestChangeDate],
    [Comment]
FROM #Comments

OPEN OnHoldCalls
FETCH NEXT FROM OnHoldCalls INTO @CurrentEDISID, @CurrentCallRef, @CurrentLatestChangeDate, @CurrentComment

WHILE @@FETCH_STATUS = 0
BEGIN
    --Find existing On-Hold Comment
    SET @MatchedCommentID = NULL

    SELECT @MatchedCommentID = [SC].[ID]
    FROM [dbo].[SiteComments] [SC]
    WHERE 
        [SC].[Type] = @CommentType
    AND [SC].[HeadingType] = @CommentHeadingType
    AND [SC].[EDISID] = @CurrentEDISID
    AND [SC].[Text] LIKE '%: On-Hold for % Days%'
    --AND [SC].[AddedOn] >= @CurrentLatestChangeDate

    IF @DisableComments = 0
    BEGIN
        IF @MatchedCommentID IS NOT NULL
        BEGIN
            -- Update Commment
            --PRINT 'Update Comment for ' + CAST(@CurrentEDISID AS VARCHAR(10)) + ' "' + @CurrentComment + '"'
            EXEC UpdateSiteComment2 @MatchedCommentID, @Now, @CommentHeadingType, @CurrentComment, NULL
        END
        ELSE
        BEGIN
            -- Add Comment
            --PRINT 'Add Comment for ' + CAST(@CurrentEDISID AS VARCHAR(10)) + ' "' + @CurrentComment + '"'
            EXEC AddSiteComment @CurrentEDISID, @CommentType, @Now, @CommentHeadingType, @CurrentComment, @NewCommentID, NULL
        END
    END
    ELSE
    BEGIN
        IF @MatchedCommentID IS NOT NULL
        BEGIN
            PRINT 'Update Comment for ' + CAST(@CurrentEDISID AS VARCHAR(10)) + ' "' + @CurrentComment + '"'
        END
        ELSE
        BEGIN
            PRINT 'Add Comment for ' + CAST(@CurrentEDISID AS VARCHAR(10)) + ' "' + @CurrentComment + '"'
        END
    END
    FETCH NEXT FROM OnHoldCalls INTO @CurrentEDISID, @CurrentCallRef, @CurrentLatestChangeDate, @CurrentComment
END

CLOSE OnHoldCalls
DEALLOCATE OnHoldCalls

SELECT
    [C].[EDISID],
    /* For Testing */
    --[S].[SiteID],
    [C].[Detail]
FROM #Comments AS [C]
/* For Testing */
--JOIN [dbo].[Sites] AS [S] ON [C].[EDISID] = [S].[EDISID]

DROP TABLE #Comments
DROP TABLE #Sites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ExceptionServiceCallOnHold] TO PUBLIC
    AS [dbo];

