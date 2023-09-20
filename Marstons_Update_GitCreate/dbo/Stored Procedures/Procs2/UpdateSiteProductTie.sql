CREATE PROCEDURE [dbo].[UpdateSiteProductTie]
(
	@EDISID 	INT,
	@ProductID	INT,
	@Tied		BIT
)

AS

SET NOCOUNT ON

Update dbo.SiteProductTies
SET Tied = @Tied
where EDISID = @EDISID and ProductID = @ProductID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteProductTie] TO PUBLIC
    AS [dbo];

