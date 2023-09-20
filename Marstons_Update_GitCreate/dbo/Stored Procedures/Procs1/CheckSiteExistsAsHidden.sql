---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE CheckSiteExistsAsHidden
(
	@SiteID	VARCHAR(25)
)

AS

DECLARE @SiteCount	INT

SELECT @SiteCount = COUNT(SiteID)
FROM Sites
WHERE SiteID = @SiteID
AND Hidden = 1

IF @SiteCount <= 0
	RETURN 0
ELSE
	RETURN 1


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[CheckSiteExistsAsHidden] TO PUBLIC
    AS [dbo];

