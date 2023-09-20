
CREATE PROCEDURE [dbo].[GetEmailExceptionCountByDate]
	@EDISID			INTEGER,
	@From			DATETIME,
	@To				DATETIME
	
AS

SET NOCOUNT ON;

SELECT Calendar.CalendarDate AS TradingDate,
	   ISNULL(ExceptionCount, 0) AS ExceptionCount
FROM Calendar
LEFT JOIN
(
	SELECT COUNT(*) AS ExceptionCount, se.TradingDate
	FROM SiteExceptions se
	WHERE se.EDISID = @EDISID
	AND se.TradingDate BETWEEN @From AND @To
	AND se.ExceptionEmailID IS NOT NULL
	GROUP BY se.TradingDate
) AS AlertsSent ON AlertsSent.TradingDate = Calendar.CalendarDate
WHERE CalendarDate BETWEEN @From AND @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEmailExceptionCountByDate] TO PUBLIC
    AS [dbo];

