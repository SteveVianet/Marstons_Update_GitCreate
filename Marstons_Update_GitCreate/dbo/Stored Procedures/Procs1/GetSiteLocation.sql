---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteLocation
(
	@EDISID	INT
)

AS

SELECT	LocationX,
	LocationY
FROM SiteLocations
WHERE EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLocation] TO PUBLIC
    AS [dbo];

