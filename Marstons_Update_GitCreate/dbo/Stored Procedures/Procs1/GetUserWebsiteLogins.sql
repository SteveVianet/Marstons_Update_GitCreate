CREATE PROCEDURE [dbo].[GetUserWebsiteLogins]
(
	@UserID		INT	= NULL,
	@DateFrom	DATETIME = NULL,
	@DateTo		DATETIME = NULL
)

AS

DECLARE @DatabaseName AS NVARCHAR(50)
SET @DatabaseName = db_name()

EXEC [EDISSQL1\SQL1].WebAdministration.dbo.GetUserLoginAttempts @DatabaseName, @UserID, @DateFrom, @DateTo

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserWebsiteLogins] TO PUBLIC
    AS [dbo];

