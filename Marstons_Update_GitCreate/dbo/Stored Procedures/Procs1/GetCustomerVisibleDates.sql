CREATE PROCEDURE [dbo].[GetCustomerVisibleDates]
(
    @VisibleStart DATE OUTPUT,
    @VisibleEnd DATE OUTPUT
)
AS

SET NOCOUNT ON;
SET DATEFIRST 1;

--DEBUG
/*
DECLARE @VisibleStart DATE
DECLARE @VisibleEnd DATE
*/
--DEBUG

DECLARE @WebAuditDate DATE
DECLARE @WebAuditToDate DATE
SELECT 
    @WebAuditDate = CAST([PropertyValue] AS DATE),
    @WebAuditToDate = DATEADD(Day, 6, CAST([PropertyValue] AS DATE)) 
FROM [dbo].[Configuration]
WHERE [PropertyName] = 'AuditDate'

DECLARE @AuditWeeksBack INT = 1
SELECT @AuditWeeksBack = ISNULL(CAST([PropertyValue] AS INTEGER), 1) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditWeeksBehind'

--Get Audit Day for customer, the day in which the audit period will be classed as an extra week forward
DECLARE @AuditDay INT
SELECT @AuditDay = ISNULL(CAST([PropertyValue] AS INTEGER), NULL) FROM [dbo].[Configuration] WHERE [PropertyName] = 'AuditDay'

-- Debug
/*
SELECT @AuditWeeksBack [WeeksBack], @AuditDay [Day], DB_NAME() [Database]
SELECT @WebAuditDate [AuditWeekStart], @WebAuditToDate [AuditWeekEnd]
*/

--DECLARE @BaseFrom DATETIME
--DECLARE @BaseTo DATETIME

-- Calculate the latest week (used to generate proper date ranges later)
IF @AuditDay IS NOT NULL
BEGIN
	--Get Current Day
	--DECLARE @CurrentDay INT
	--SET @CurrentDay = DATEPART(WEEKDAY,GETDATE())
    
	--DEBUG
	--SELECT @CurrentDay [Current]
	--SELECT [CalendarDate] AS [Today], [DayOfWeek], [DayOfWeekName] FROM [dbo].[Calendar] WHERE [CalendarDate] = @WebAuditDate
	--DEBUG

    SELECT
        @VisibleStart = [Before].[CalendarDate]
    FROM ( SELECT [CalendarDate], [DayOfWeek] FROM [dbo].[Calendar] WHERE [CalendarDate] = @WebAuditDate ) 
        AS [Today] 
    JOIN [dbo].[Calendar] AS [Before]
        ON [Today].[CalendarDate] > [Before].[CalendarDate]
        AND DATEADD(DAY, -7, [Today].[CalendarDate]) <= [Before].[CalendarDate]
        AND [Before].[DayOfWeek] = @AuditDay
    
    SELECT
        @VisibleEnd = [After].[CalendarDate]
    FROM ( SELECT [CalendarDate], [DayOfWeek] FROM [dbo].[Calendar] WHERE [CalendarDate] = CAST(@WebAuditDate AS DATE) ) 
        AS [Today] 
    JOIN [dbo].[Calendar] AS [After]
        ON [Today].[CalendarDate] < [After].[CalendarDate]
        AND DATEADD(DAY, 7, [Today].[CalendarDate]) >= [After].[CalendarDate]
        AND [After].[DayOfWeek] = CASE WHEN @AuditDay = 1 THEN 7 ELSE @AuditDay - 1 END

    SET @VisibleStart = DATEADD(WEEK, @AuditWeeksBack, @VisibleStart)
    SET @VisibleEnd = DATEADD(WEEK, @AuditWeeksBack, @VisibleEnd)
END
ELSE
BEGIN 
    SET @VisibleEnd = DATEADD(WEEK, @AuditWeeksBack, @WebAuditToDate)
    SET @VisibleStart = DATEADD(DAY, -6, @VisibleEnd)
END

--DEBUG
--SELECT @VisibleStart AS [VisibleStart], @VisibleEnd AS [VisibleEnd]
--DEBUG

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCustomerVisibleDates] TO PUBLIC
    AS [dbo];

