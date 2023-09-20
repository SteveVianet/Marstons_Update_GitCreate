CREATE FUNCTION [dbo].[fnGetWeekdayCount]
(@From DATETIME,
@To DATETIME)
RETURNS INT
AS
BEGIN

DECLARE @WeekdayCount INT

IF DATEPART(HOUR, @From) >= 12
	SET @From = DATEADD(DAY, 1, @From)

SET @WeekdayCount = 0

SET @From = CAST(@From AS DATE)
SET @To = CAST(@To AS DATE)

SELECT @WeekdayCount = COUNT(*)
FROM dbo.Calendar
WHERE CalendarDate BETWEEN @From AND @To
AND [Weekday] = 1

RETURN @WeekdayCount
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnGetWeekdayCount] TO PUBLIC
    AS [dbo];

