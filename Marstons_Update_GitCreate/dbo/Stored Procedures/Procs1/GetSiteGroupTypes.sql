---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteGroupTypes

AS

SELECT	[ID],
	[Description],
	HasPrimary
FROM dbo.SiteGroupTypes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroupTypes] TO PUBLIC
    AS [dbo];

