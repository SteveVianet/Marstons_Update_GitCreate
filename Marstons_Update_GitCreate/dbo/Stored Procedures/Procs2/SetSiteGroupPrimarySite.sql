---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetSiteGroupPrimarySite
(
	@EDISID		INT,
	@SiteGroupID	INT
)

AS

--Clear previous primary group site
UPDATE SiteGroupSites
SET IsPrimary = 0
WHERE SiteGroupID = @SiteGroupID

--Set new primary group site
UPDATE SiteGroupSites
SET IsPrimary = 1
WHERE SiteGroupID = @SiteGroupID
AND EDISID = @EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetSiteGroupPrimarySite] TO PUBLIC
    AS [dbo];

