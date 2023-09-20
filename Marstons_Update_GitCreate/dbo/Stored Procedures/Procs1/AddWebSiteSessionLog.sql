CREATE PROCEDURE AddWebSiteSessionLog
	@SessionID	INT,
	@DatabaseID	INT,
	@UserID		INT,
	@MethodName	VARCHAR(200) = '',
	@Parameters	VARCHAR(255) = '',
	@Cached	BIT,
	@Duration	INT,
	@EDISID	INT

AS

EXEC [SQL1\SQL1].[ServiceLogger].dbo.AddWebSiteSessionLog @SessionID, @DatabaseID, @UserID, @MethodName, @Parameters, @Cached, @Duration, @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddWebSiteSessionLog] TO PUBLIC
    AS [dbo];

