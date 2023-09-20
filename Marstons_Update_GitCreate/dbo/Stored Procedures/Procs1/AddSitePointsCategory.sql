---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddSitePointsCategory
(
	@EDISID		INT,
	@CategoryID	INT,
	@Points		INT
)

AS

INSERT INTO SitePointsCategories
(EDISID, CategoryID, Points)
VALUES
(@EDISID, @CategoryID, @Points)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSitePointsCategory] TO PUBLIC
    AS [dbo];

