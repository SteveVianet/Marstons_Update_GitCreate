CREATE PROCEDURE [dbo].[RefreshReds]
(
	@OverridePeriod		VARCHAR(50) = NULL
)
AS

SET NOCOUNT ON

DECLARE @Period	VARCHAR(50)
DECLARE @DatabaseID INT
DECLARE @FromWC DATETIME
DECLARE @ToWC DATETIME
DECLARE @PeriodRedsCount INT
DECLARE @WeekCount INT
DECLARE @UnauditedCount INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

-- Get the last completed period for this customer
IF @OverridePeriod IS NULL
BEGIN
	SELECT TOP 1 @Period = Period, @FromWC = DATEADD(WEEK, -19, ToWC), @ToWC = DATEADD(DAY, 6, ToWC), @WeekCount = PeriodWeeks
	FROM PubcoCalendars
	WHERE DATEADD(DAY, 6, ToWC) < GETDATE()
	ORDER BY ToWC DESC

END
ELSE
BEGIN
	SELECT TOP 1 @Period = Period, @FromWC = DATEADD(WEEK, -19, ToWC), @ToWC = DATEADD(DAY, 6, ToWC), @WeekCount = PeriodWeeks
	FROM PubcoCalendars
	WHERE Period = @OverridePeriod

END

DECLARE @OriginalToWC DATETIME
SET @OriginalToWC = @ToWC

IF @OverridePeriod IS NULL
BEGIN
	-- Get the count of CD values for the previous period already processed
	SELECT @PeriodRedsCount = COUNT(*)
	FROM dbo.Reds
	WHERE Period = @Period

END
ELSE
BEGIN
	DELETE
	FROM dbo.Reds
	WHERE Period = @Period

	SET @PeriodRedsCount = 0

END

-- Get a count of unaudited period cache data in the last complete period
SELECT @UnauditedCount = COUNT(*)
FROM dbo.PeriodCacheVariance
WHERE IsAudited = 0
AND WeekCommencing BETWEEN @FromWC AND @ToWC

-- If there are no unaudited weeks and we have no reds for the last period in the Reds table then refresh the reds
IF @UnauditedCount = 0 AND @PeriodRedsCount = 0
BEGIN
	DELETE FROM dbo.Reds WHERE DatabaseID = @DatabaseID and Period =  @Period
	-- Insert the last complete period
	INSERT INTO dbo.Reds([DatabaseID] ,[Period] ,[EDISID] ,[CategoryID] ,[ProductID] ,[AreValuesStockAdjusted] ,[FromWeek]  ,[AdjustedFromWeek]  ,[ToWeek]  ,[ReportWeeks]  ,[AdjustedReportWeeks]  ,[PeriodWeeks]  ,[PeriodDelivered]  ,[PeriodDispensed]  ,[PeriodVariance]  ,[LowDispensedThreshold] ,[InsufficientData] ,[MinimumCumulative] ,[MinimumCumulativePre]   ,[CD]	)
	EXEC GetCalculatedDeficit @FromWC, @ToWC,  @WeekCount,  0.10,  @Period,  0, 0,  0,  1,  1	

	UPDATE dbo.PubcoCalendars
	SET Processed = 1
	WHERE Period = @Period

	IF @OverridePeriod IS NULL
	BEGIN
		-- Get the period before last, so we can refresh those values too
		SELECT TOP 1 @Period = Period, @FromWC = DATEADD(WEEK, -19, ToWC), @ToWC = DATEADD(DAY, 6, ToWC), @WeekCount = PeriodWeeks
		FROM PubcoCalendars
		WHERE ToWC < GETDATE() 
		AND DatabaseID = @DatabaseID
		AND Period <> @Period
		ORDER BY ToWC DESC

	END
	ELSE
	BEGIN
		SELECT TOP 1 @Period = Period, @FromWC = DATEADD(WEEK, -19, ToWC), @ToWC = DATEADD(DAY, 6, ToWC), @WeekCount = PeriodWeeks
		FROM PubcoCalendars
		WHERE ToWC < @OriginalToWC 
		AND DatabaseID = @DatabaseID
		AND Period <> @Period
		ORDER BY ToWC DESC

	END
	
	-- Delete the period before last and re-process those Reds values too
	DELETE FROM dbo.Reds WHERE DatabaseID = @DatabaseID and Period =  @Period		
	INSERT INTO dbo.Reds([DatabaseID] ,[Period] ,[EDISID] ,[CategoryID] ,[ProductID] ,[AreValuesStockAdjusted] ,[FromWeek]  ,[AdjustedFromWeek]  ,[ToWeek]  ,[ReportWeeks]  ,[AdjustedReportWeeks]  ,[PeriodWeeks]  ,[PeriodDelivered]  ,[PeriodDispensed]  ,[PeriodVariance]  ,[LowDispensedThreshold] ,[InsufficientData] ,[MinimumCumulative] ,[MinimumCumulativePre]   ,[CD]	)
	EXEC GetCalculatedDeficit @FromWC,  @ToWC,  @WeekCount,  0.10,  @Period,  0, 0,  0,  1,  1	

	UPDATE dbo.PubcoCalendars
	SET Processed = 1
	WHERE Period = @Period

	IF @OverridePeriod IS NULL
	BEGIN
		-- Send e-mails to Users with ReceiveNewCDAlert column checked informing them of CD refresh
		EXEC GenerateAndSendCDEmailAlert
	
	END

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshReds] TO PUBLIC
    AS [dbo];

