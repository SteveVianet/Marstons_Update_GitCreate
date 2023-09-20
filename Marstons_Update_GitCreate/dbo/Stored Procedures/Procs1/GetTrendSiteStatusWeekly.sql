CREATE PROCEDURE [dbo].[GetTrendSiteStatusWeekly]
(
    @EDISID         INT,
    @From           DATE,
    @To             DATE
)

AS

/* Values I used during testing */
--DECLARE @EDISID         INT = 2
--DECLARE @From           DATE = '2016-01-13'
--DECLARE @To             DATE = '2016-04-06'

-- Change the first day of the week to Monday (default is Sunday/7)
SET DATEFIRST 1

--Adjust Dates appropriately (Monday - Sunday)
SET @From = DATEADD(WEEK, DATEDIFF(WEEK, 0, @From), 0)
-- If To Date *IS NOT* a Sunday, select the previous Sunday
IF DATEPART(WEEKDAY, @To) <> 7
BEGIN
    SET @To = DATEADD(WEEK, DATEDIFF(WEEK,0, @To)-1, 6)
END

DECLARE @ExpandedFrom DATE = DATEADD(WEEK, -3, @From) -- Adjust the From date to pull back by 3 weeks for usage on the Trend report

DECLARE @SiteStatus TABLE (
    [WeekCommencing] DATE NOT NULL, 
    [ChangeOfTenancy] BIT NOT NULL DEFAULT(0),  -- Simplifies later checks for existence of COT
    [ChangeOfTenancyDate] DATE,
    [ChangeOfTenancyText] VARCHAR(1024),
    [ServiceCall] BIT NOT NULL DEFAULT(0),      -- Simplifies later checks for existence of Service Calls
    [ServiceCallDate] DATE,
    [ServiceCallStatus] VARCHAR(1024),
    [TrafficLight] INT DEFAULT(0)               -- ???!
    )

/* Calculate the Traffic Lights */
DECLARE @SiteRankingTemplate TABLE ([FirstDateOfWeek] DATE NOT NULL, [CalendarDate] DATE NOT NULL, [RankingTypeID] INT)
DECLARE @SiteRankings TABLE ([FirstDateOfWeek] DATE NOT NULL, [CalendarDate] DATE NOT NULL, [RankingTypeID] INT)

INSERT INTO @SiteRankingTemplate ([FirstDateOfWeek], [CalendarDate], [RankingTypeID])
SELECT 
    [Calendar].[FirstDateOfWeek],
    [Calendar].[CalendarDate],
    [SiteRankings].[RankingTypeID]
FROM [dbo].[Calendar]
LEFT JOIN [dbo].[SiteRankings] ON [Calendar].[CalendarDate] = [SiteRankings].[ValidFrom] AND [SiteRankings].[EDISID] = @EDISID AND [SiteRankings].[RankingCategoryID] = 1
LEFT JOIN [dbo].[SiteRankingTypes] ON [SiteRankings].[RankingTypeID] = [SiteRankingTypes].[ID]
WHERE [Calendar].[CalendarDate] BETWEEN @ExpandedFrom AND @To

/* If first Ranking is NULL, find the previous value */
DECLARE @FirstRank INT

SELECT TOP 1 @FirstRank = [RankingTypeID]
FROM @SiteRankingTemplate
ORDER BY [FirstDateOfWeek]

IF @FirstRank IS NULL
BEGIN
    SELECT TOP 1 @FirstRank = [RankingTypeID]
    FROM [SiteRankings]
    WHERE [SiteRankings].[ValidFrom] < (SELECT TOP 1 [CalendarDate] FROM @SiteRankingTemplate WHERE [RankingTypeID] IS NOT NULL ORDER BY [FirstDateOfWeek])
    AND [SiteRankings].[EDISID] = @EDISID
    ORDER BY [SiteRankings].[ValidFrom] DESC
    
    /* If we failed to get a value, attempt to get the latest existing value for the Site */
    IF @FirstRank IS NULL
    BEGIN
        SELECT TOP 1 @FirstRank = [RankingTypeID]
        FROM [SiteRankings]
        WHERE [SiteRankings].[ValidFrom] < GETDATE()
        AND [SiteRankings].[EDISID] = @EDISID
        AND [SiteRankings].[RankingCategoryID] = 1
        ORDER BY [SiteRankings].[ValidFrom] DESC
    END
    
    -- If we still have no value, default to Green
    IF @FirstRank IS NULL
    BEGIN
        SET @FirstRank = 3
    END
    
    UPDATE @SiteRankingTemplate
    SET [RankingTypeID] = ISNULL([RankingTypeID], @FirstRank)
    WHERE [CalendarDate] IN (SELECT MIN([CalendarDate]) FROM @SiteRankingTemplate)
END

INSERT INTO @SiteRankings ([FirstDateOfWeek], [CalendarDate], [RankingTypeID])
SELECT
    [SR1].[FirstDateOfWeek],
    [SR1].[CalendarDate],
    COALESCE([SR1].[RankingTypeID], [SR2].[RankingTypeID]) AS [RankingTypeID]
FROM @SiteRankingTemplate AS [SR1]
LEFT JOIN @SiteRankingTemplate AS [SR2] 
ON [SR2].[CalendarDate] = (
        SELECT MAX([CalendarDate])
        FROM @SiteRankingTemplate AS [SRMax]
        WHERE [SRMax].[CalendarDate] < [SR1].[CalendarDate] AND [SRMax].[RankingTypeID] IS NOT NULL)
ORDER BY [FirstDateOfWeek]

--SELECT [SR].[FirstDateOfWeek], [SR].[RankingTypeID]
--FROM @SiteRankings AS [SR]
--WHERE [SR].[FirstDateOfWeek] = DATEADD(DAY, -6, [SR].[CalendarDate])
/* ============================ */


INSERT INTO @SiteStatus ([WeekCommencing], [ChangeOfTenancy], [ChangeOfTenancyDate], [ChangeOfTenancyText], [ServiceCall], [ServiceCallDate], [ServiceCallStatus], [TrafficLight])
SELECT DISTINCT
    [Calendar].[FirstDateOfWeek] AS [WeekCommencing],
    CASE WHEN [SiteComments].[WeekCommencing] IS NOT NULL
         THEN 1
         ELSE 0
    END AS [ChangeOfTenancy],
    [SiteComments].[Date] AS [ChangeOfTenancyDate],
    [SiteComments].[Text] AS [ChangeOfTenancyText],
    CASE WHEN [Calls].[RaisedOn] IS NOT NULL
         THEN 1
         ELSE 0
    END AS [ServiceCall],
    [Calls].[RaisedOn] AS [ServiceCallDate],
    CASE WHEN [Calls].[RaisedOn] IS NOT NULL AND ([Calls].[AbortReasonID] <> 0)
         THEN 'Aborted Service Call'
         WHEN [Calls].[RaisedOn] IS NOT NULL AND ([Calls].[ClosedOn] IS NOT NULL AND [Calls].[AbortReasonID] = 0)
         THEN 'Completed Service Call'
         WHEN [Calls].[RaisedOn] IS NOT NULL AND ([Calls].[ClosedOn] IS NULL)
         THEN 'Outstanding Service Call'
         ELSE NULL
    END AS [ServiceCallText],
    [TrafficLights].[TrafficLightColour]
FROM [dbo].[Calendar]
LEFT JOIN ( SELECT
                [EDISID],
                CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [Date]), 0) AS DATE) AS [WeekCommencing],
                [Date],
                [Text]
            FROM [dbo].[SiteComments] 
            WHERE [SiteComments].[HeadingType] IN (3004) -- Change of Tenancy  (16 also exists, but doesn't appear to be used anymore?)

    ) AS [SiteComments] 
    ON [Calendar].[FirstDateOfWeek] = [SiteComments].[WeekCommencing]
    AND [SiteComments].[EDISID] = @EDISID
LEFT JOIN ( SELECT
                [ServiceCalls].[EDISID],
                CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, [ServiceCalls].[RaisedDate]), 0) AS DATE) AS [RaisedDate],
                [Calls].[AbortReasonID],
                [Calls].[ClosedOn],
                [Calls].[RaisedOn]
            FROM (  SELECT
                        [EDISID],
                        CAST([RaisedOn] AS DATE) AS [RaisedDate],
                        MAX([RaisedOn]) AS [RaisedOn]
                    FROM [dbo].[Calls]
                    WHERE [EDISID] = @EDISID
                    GROUP BY 
                        [EDISID],
                        CAST([RaisedOn] AS DATE)
                ) AS [ServiceCalls]
            JOIN [dbo].[Calls]
                ON [ServiceCalls].[RaisedOn] = [Calls].[RaisedOn]
                AND [ServiceCalls].[EDISID] = [Calls].[EDISID]
    ) AS [Calls]
    ON [Calendar].[FirstDateOfWeek] = [Calls].[RaisedDate]
    AND [Calls].[EDISID] = @EDISID
LEFT JOIN ( SELECT 
                [SR].[FirstDateOfWeek], 
                [SR].[RankingTypeID] AS [TrafficLightColour]
            FROM @SiteRankings AS [SR]
            WHERE [SR].[FirstDateOfWeek] = DATEADD(DAY, -6, [SR].[CalendarDate])
    ) AS [TrafficLights]
    ON [Calendar].[FirstDateOfWeek] = [TrafficLights].[FirstDateOfWeek]
WHERE [Calendar].[CalendarDate] BETWEEN @ExpandedFrom AND @To


SELECT
    [WeekCommencing],
    [ChangeOfTenancy],
    [ChangeOfTenancyDate],
    [ChangeOfTenancyText],
    [ServiceCall],
    [ServiceCallDate],
    [ServiceCallStatus],
    [TrafficLight]
FROM @SiteStatus
ORDER BY [WeekCommencing]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTrendSiteStatusWeekly] TO PUBLIC
    AS [dbo];

