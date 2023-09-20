CREATE PROCEDURE [dbo].[AddWebSiteSessionSite]
	@SessionID			INT,
	@DatabaseID			INT,
	@EDISID				INT,
	@SiteID				VARCHAR(15),
	@Name				VARCHAR(60),
	@Street				VARCHAR(50),
	@Town				VARCHAR(50),
	@PostCode			VARCHAR(8),
	@IsIDraught			BIT

AS
BEGIN

	EXEC [SQL1\SQL1].ServiceLogger.dbo.AddWebSiteSessionSite @SessionID, @DatabaseID, @EDISID, @SiteID, @Name, @Street, @Town, @PostCode, @IsIDraught
	
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddWebSiteSessionSite] TO PUBLIC
    AS [dbo];

