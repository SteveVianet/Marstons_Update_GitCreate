---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSiteGroup
(
	@ID		INT
)

AS

--Delete members
DELETE FROM dbo.SiteGroupSites
WHERE SiteGroupID = @ID

--Delete group
DELETE FROM dbo.SiteGroups
WHERE [ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteGroup] TO PUBLIC
    AS [dbo];

