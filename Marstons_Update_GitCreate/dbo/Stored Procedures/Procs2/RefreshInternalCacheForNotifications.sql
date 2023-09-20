CREATE PROCEDURE [dbo].[RefreshInternalCacheForNotifications]
(
    @WeeksBehind INT = 8, -- This must not go past 11 (maybe 12) weeks otherwise Stock will calculate incorrectly (the overnight jobs handle this)
    @Auditor VARCHAR(255) = NULL,
    @EDISID INT = NULL
)
AS

SET DATEFIRST 1;

DECLARE @AuditWeeksBack INT = 1
SELECT @AuditWeeksBack = ISNULL(CAST([PropertyValue] AS INTEGER), 1) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditWeeksBehind'

--Get Audit Day for customer, the day in which the audit period will be classed as an extra week forward
DECLARE @AuditDay INT
SELECT @AuditDay = ISNULL(CAST([PropertyValue] AS INTEGER), NULL) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditDay'

DECLARE @BaseFrom DATETIME
DECLARE @BaseTo DATETIME

-- Calculate the latest week (used to generate proper date ranges later)
IF @AuditDay IS NOT NULL
BEGIN
       --Get Current Day
       DECLARE @CurrentDay INT
       SET @CurrentDay = DATEPART(dw,GETDATE())

       IF @CurrentDay >= @AuditDay
              BEGIN
            SET @BaseFrom = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
            SET @BaseTo = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 6))
                     --SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-2), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) --take back 1 and a half weeks
              END
       ELSE
              BEGIN 
            SET @BaseFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
            SET @BaseTo = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 6))
                     --SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0)) -- take back 2 weeks
              END
END
ELSE
BEGIN 
    SET @BaseFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
    SET @BaseTo = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 6))
       --SET @CurrentWeekFrom = DATEADD(WEEK, -(@AuditWeeksBack-1), DATEADD(WEEK, DATEDIFF(WEEK, 6, GETDATE()), 0))
END


DECLARE @EndDate DATE = @BaseTo
DECLARE @MaxData DATE = DATEADD(WEEK, -@WeeksBehind, @BaseFrom)

EXEC dbo.PeriodCacheVarianceInternalRebuildForNeo @MaxData, @EndDate, @Auditor, @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshInternalCacheForNotifications] TO PUBLIC
    AS [dbo];

