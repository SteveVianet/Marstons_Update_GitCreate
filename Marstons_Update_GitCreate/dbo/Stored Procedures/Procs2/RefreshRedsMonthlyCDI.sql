CREATE PROCEDURE [dbo].[RefreshRedsMonthlyCDI]
(
	@ThisMonth		DATETIME = NULL,
	@ReturnMonthlyCDI BIT = 1
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

CREATE TABLE #Reds
(
	[DatabaseID] [int] NOT NULL,
	[Period] [varchar](10) NOT NULL,
	[EDISID] [int] NOT NULL,
	[CategoryID] [int] NULL,
	[ProductID] [int] NULL,
	[AreValuesStockAdjusted] [int] NULL,
	[FromWeek] [datetime] NULL,
	[AdjustedFromWeek] [datetime] NULL,
	[ToWeek] [datetime] NULL,
	[ReportWeeks] [int] NULL,
	[AdjustedReportWeeks] [int] NULL,
	[PeriodWeeks] [int] NULL,
	[PeriodDelivered] [float] NULL,
	[PeriodDispensed] [float] NULL,
	[PeriodVariance] [float] NULL,
	[LowDispensedThreshold] [float] NULL,
	[InsufficientData] [int] NULL,
	[MinimumCumulative] [float] NULL,
	[MinimumCumulativePre] [float] NULL,
	[CD] [float] NULL
)

CREATE TABLE #SitesToExclude(EDISID INT)

DECLARE @Date DATETIME

DECLARE @FirstOfThisMonth DATETIME
DECLARE @FirstMondayOfThisMonth DATETIME

DECLARE @FirstDayOfLastMonth DATETIME
DECLARE @LastDayOfLastMonth DATETIME
DECLARE @FirstMondayOfLastMonth DATETIME
DECLARE @LastMondayOfLastMonth DATETIME
DECLARE @MonthCount INT
DECLARE @WeekCount INT
DECLARE @CachedWeeks INT
DECLARE @UnauditedInMonth INT
DECLARE @CDI FLOAT
DECLARE @DatabaseID INT
DECLARE @ExcludeFromRedsPropertyID INT

SET @Date = CASE WHEN @ThisMonth IS NULL THEN GETDATE() ELSE @ThisMonth END

--First of this month
SET @FirstOfThisMonth = CAST(CAST(YEAR(@Date) AS VARCHAR(4)) + '/' + CAST(MONTH(@Date) AS VARCHAR(2)) + '/01' AS DATETIME)

--First Monday week of Month
SET @FirstMondayOfThisMonth = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, @FirstOfThisMonth) + 1, @FirstOfThisMonth)))

--Last day of last month
SET @LastDayOfLastMonth = DATEADD(DAY, -1, @FirstOfThisMonth)

SET @FirstDayOfLastMonth = CAST(CAST(YEAR(@LastDayOfLastMonth) AS VARCHAR(4)) + '/' + CAST(MONTH(@LastDayOfLastMonth) AS VARCHAR(2)) + '/01' AS DATETIME)

--First Monday week of Month
SET @FirstMondayOfLastMonth = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(dd, -DATEPART(dw, @FirstDayOfLastMonth) + 1, @FirstDayOfLastMonth)))

SET @LastMondayOfLastMonth = DATEADD(WEEK, -1, @FirstMondayOfThisMonth)

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'

SELECT @MonthCount = COUNT(*)
FROM RedsMonthlyCDI
WHERE FromMonday = @FirstMondayOfLastMonth
AND ToMonday = @LastMondayOfLastMonth
AND DatabaseID = @DatabaseID

INSERT INTO #SitesToExclude
SELECT EDISID
FROM dbo.SiteProperties
WHERE PropertyID = @ExcludeFromRedsPropertyID

IF @MonthCount = 0 OR @ReturnMonthlyCDI = 1
BEGIN
	SET @WeekCount = DATEDIFF(WEEK, @FirstMondayOfLastMonth, @LastMondayOfLastMonth) + 1
	
	SELECT @CachedWeeks = COUNT(DISTINCT WeekCommencing)
	FROM PeriodCacheVariance
	WHERE WeekCommencing BETWEEN @FirstMondayOfLastMonth AND @LastMondayOfLastMonth
	
	SELECT @UnauditedInMonth = SUM(CASE WHEN IsAudited = 0 THEN 1 ELSE 0 END)
	FROM PeriodCacheVariance
	WHERE WeekCommencing BETWEEN @FirstMondayOfLastMonth AND @LastMondayOfLastMonth

	IF @UnauditedInMonth = 0 AND @CachedWeeks = @WeekCount
	BEGIN
		DECLARE @MonthStartWeek DATETIME
		SET @MonthStartWeek = DATEADD(week, -19, @LastMondayOfLastMonth)
		
		INSERT INTO #Reds
		EXEC GetCalculatedDeficit @MonthStartWeek,  @LastMondayOfLastMonth,  @WeekCount,  0.10,  '',  0, 0,  0,  1,  1
		
		IF @ReturnMonthlyCDI = 0
		BEGIN

			SELECT @CDI = ROUND(ISNULL(SUM(Reds.CD), 0) / 36.0 / (CASE WHEN COUNT(Reds.EDISID) = 0 THEN 1 ELSE COUNT(Reds.EDISID) END) / @WeekCount, 2)
			FROM #Reds AS Reds
			WHERE InsufficientData = 0
			AND EDISID NOT IN (SELECT EDISID FROM #SitesToExclude)
			
			INSERT INTO dbo.RedsMonthlyCDI
			(DatabaseID, MonthNumber, [Month], [Year], FromMonday, ToMonday, CDI)
			SELECT	CAST(PropertyValue AS INTEGER),
					MONTH(@LastDayOfLastMonth),
					CASE MONTH(@LastDayOfLastMonth)	WHEN 1 THEN 'January'
													WHEN 2 THEN 'February'
													WHEN 3 THEN 'March'
													WHEN 4 THEN 'April'
													WHEN 5 THEN 'May'
													WHEN 6 THEN 'June'
													WHEN 7 THEN 'July'
													WHEN 8 THEN 'August'
													WHEN 9 THEN 'September'
													WHEN 10 THEN 'October'
													WHEN 11 THEN 'November'
													WHEN 12 THEN 'December' END,
					YEAR(@LastDayOfLastMonth),
					@FirstMondayOfLastMonth,
					@LastMondayOfLastMonth,
					@CDI
			FROM Configuration
			WHERE PropertyName = 'Service Owner ID'
			
		END
	END
END

IF @ReturnMonthlyCDI = 1
BEGIN
	SELECT	DatabaseID,
			Period,
			EDISID,
			CategoryID,
			ProductID,
			AreValuesStockAdjusted,
			FromWeek,
			AdjustedFromWeek,
			ToWeek,
			ReportWeeks,
			AdjustedReportWeeks,
			PeriodWeeks,
			PeriodDelivered,
			PeriodDispensed,
			PeriodVariance,
			LowDispensedThreshold,
			InsufficientData,
			MinimumCumulative,
			MinimumCumulativePre,
			CD
	FROM #Reds
	WHERE EDISID NOT IN (SELECT EDISID FROM #SitesToExclude)
	
END

DROP TABLE #SitesToExclude
DROP TABLE #Reds

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshRedsMonthlyCDI] TO PUBLIC
    AS [dbo];

