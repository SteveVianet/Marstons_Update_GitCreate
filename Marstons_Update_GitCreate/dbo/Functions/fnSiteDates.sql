---------------------------------------------------------------------------
--
--  Function Header
--
---------------------------------------------------------------------------
CREATE FUNCTION fnSiteDates 
(
	@StartDate	DATETIME, 
	@EndDate	DATETIME,
	@ScheduleID	INT
)

RETURNS @SiteDates TABLE 
			(
				SiteID VARCHAR(50), 
				[Date] DATETIME
			)

AS

BEGIN
	DECLARE @LocalDate	DATETIME
	DECLARE @Dates 	TABLE([TheDate] DATETIME)
	
	SET @LocalDate = @StartDate
	
	WHILE @LocalDate < @EndDate
	BEGIN
		INSERT INTO @Dates	([TheDate])
		VALUES		(@LocalDate)
	
		SET @LocalDate = DATEADD(d, 7, @LocalDate)
	
	END

	INSERT @SiteDates
	SELECT Sites.SiteID, [TheDate]
	FROM ScheduleSites
	JOIN Sites
		ON Sites.EDISID = ScheduleSites.EDISID
	CROSS JOIN @Dates
	WHERE ScheduleID = @ScheduleID

	RETURN 
END

