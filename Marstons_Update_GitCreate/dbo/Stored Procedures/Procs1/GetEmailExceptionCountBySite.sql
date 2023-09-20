
CREATE PROCEDURE GetEmailExceptionCountBySite
	@EDISID		INT,
	@From		DATETIME,
	@To			DATETIME
AS

SET NOCOUNT ON;

SELECT COUNT(*) AS 'SiteExceptions'
FROM SiteExceptions se
WHERE se.ExceptionEmailID IS NOT NULL
	AND se.EDISID = @EDISID
	AND se.TradingDate BETWEEN @From AND @To


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEmailExceptionCountBySite] TO PUBLIC
    AS [dbo];

