---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteGroups

AS

SELECT	[ID],
	[Description],
	TypeID
FROM dbo.SiteGroups
ORDER BY [Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroups] TO PUBLIC
    AS [dbo];

