---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UndeleteSite
(
	@SiteID	VARCHAR(25)
)

AS

UPDATE Sites
SET Hidden = 0
WHERE SiteID = @SiteID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UndeleteSite] TO PUBLIC
    AS [dbo];

