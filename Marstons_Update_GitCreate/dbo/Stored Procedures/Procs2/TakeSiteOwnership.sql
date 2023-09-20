CREATE PROCEDURE dbo.TakeSiteOwnership
(
	@EDISID		INT,
	@UserName		VARCHAR(255) = NULL
)

AS

IF @UserName IS NULL
BEGIN
	SET @UserName = SUSER_SNAME()
END

UPDATE dbo.Sites
SET SiteUser = @UserName
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[TakeSiteOwnership] TO PUBLIC
    AS [dbo];

