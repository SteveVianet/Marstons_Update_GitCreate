
CREATE PROCEDURE [dbo].[GetExceptionsForSite]
	@EDISID		INT
AS

SET NOCOUNT ON;

SELECT se.EDISID, se.ID, se.[Type], se.TradingDate, se.Value, CAST(se.LowThreshold AS VARCHAR) AS 'LowThreshold', CAST(se.HighThreshold AS VARCHAR) AS 'HighThreshold', se.SiteDescription, se.[DateFormat], se.EmailReplyTo
FROM SiteExceptions se
JOIN SiteExceptionTypes AS setypes ON setypes.[Description] = se.[Type]
WHERE EDISID = @EDISID
	AND se.ExceptionEmailID IS NULL
	AND se.TradingDate >= DATEADD(day, -3, GETDATE())
ORDER BY se.TradingDate ASC, setypes.[Rank] ASC, se.ID ASC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetExceptionsForSite] TO PUBLIC
    AS [dbo];

