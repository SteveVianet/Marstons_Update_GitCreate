
CREATE PROCEDURE dbo.DeleteOutstandingSiteExceptions
(
	@EDISID		INT = NULL
)
AS

DELETE
FROM dbo.SiteExceptions
WHERE (EDISID = @EDISID OR @EDISID IS NULL)
AND ExceptionEmailID IS NULL

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteOutstandingSiteExceptions] TO PUBLIC
    AS [dbo];

