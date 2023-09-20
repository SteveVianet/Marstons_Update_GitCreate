---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteStockistCategories
(
	@EDISID	INT
)

AS

SELECT	EDISID,
	CategoryID,
	IsTied,
	IsStockist
FROM SiteStockistCategories
WHERE EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteStockistCategories] TO PUBLIC
    AS [dbo];

