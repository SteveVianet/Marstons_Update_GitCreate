---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddSiteProductCategoryTie
(
	@EDISID 		INT,
	@ProductCategoryID	INT,
	@Tied			BIT
)

AS

INSERT INTO SiteProductCategoryTies
(EDISID, ProductCategoryID, Tied)
VALUES
(@EDISID, @ProductCategoryID, @Tied)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteProductCategoryTie] TO PUBLIC
    AS [dbo];

