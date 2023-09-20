
CREATE PROCEDURE dbo.UpdateSiteExceptionEmailID
(
	@ExceptionID		INT,
	@ExceptionEmailID	INT
)
AS

UPDATE SiteExceptions 
SET ExceptionEmailID = @ExceptionEmailID
WHERE ID = @ExceptionID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteExceptionEmailID] TO PUBLIC
    AS [dbo];

