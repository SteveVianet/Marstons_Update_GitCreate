
CREATE PROCEDURE UpdateSiteExceptions
	@ExceptionEmailID	INT,
	@SiteExceptionIDs	VARCHAR(255)
AS

SET NOCOUNT ON;

DECLARE @SQL VARCHAR(255)

SET @SQL = 'UPDATE SiteExceptions SET ExceptionEmailID = ''' + CAST(@ExceptionEmailID AS VARCHAR) + ''' WHERE ID IN (' + @SiteExceptionIDs + ')';

EXECUTE(@SQL)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteExceptions] TO PUBLIC
    AS [dbo];

