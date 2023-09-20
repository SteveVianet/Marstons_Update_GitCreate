
CREATE PROCEDURE [dbo].[GetExceptionEmail]
	@SiteExceptionIDs	VARCHAR(255)
AS

SET NOCOUNT ON;

DECLARE @SQL VARCHAR(512)

SET @SQL = 'SELECT se.ExceptionEmailID, se.ExceptionHTML, se.TradingDate, se.SiteDescription, se.DateFormat, se.EmailReplyTo FROM SiteExceptions se JOIN SiteExceptionTypes AS setypes ON setypes.Description = se.Type WHERE se.ID IN (' + @SiteExceptionIDs + ') ORDER BY se.TradingDate ASC, setypes.Rank ASC'

EXECUTE(@SQL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetExceptionEmail] TO PUBLIC
    AS [dbo];

