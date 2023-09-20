---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddSiteStockistCategory
(
	@EDISID		INT,
	@CategoryID	INT,
	@IsTied		BIT,
	@IsStockist	BIT
)

AS

INSERT INTO SiteStockistCategories
(EDISID, CategoryID, IsTied, IsStockist)
VALUES
(@EDISID, @CategoryID, @IsTied, @IsStockist)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteStockistCategory] TO PUBLIC
    AS [dbo];

