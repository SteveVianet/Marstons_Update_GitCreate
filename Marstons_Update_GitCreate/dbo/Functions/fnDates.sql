---------------------------------------------------------------------------
--
--  Function Header
--
---------------------------------------------------------------------------
CREATE FUNCTION fnDates 
(
	@StartDate	DATETIME, 
	@EndDate	DATETIME
)

RETURNS @Dates TABLE 
			(
				[Date] DATETIME
			)

AS

BEGIN
	DECLARE @LocalDate	DATETIME
	
	SET @LocalDate = @StartDate
	
	WHILE @LocalDate < @EndDate
	BEGIN
		INSERT INTO @Dates	([Date])
		VALUES		(@LocalDate)
	
		SET @LocalDate = DATEADD(d, 7, @LocalDate)
	
	END

	RETURN 
END

