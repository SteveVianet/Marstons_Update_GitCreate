
CREATE PROCEDURE dbo.AddSiteVRSAuthorisedBuyingOut
(
	@EDISID					INT,
	@ProductID				INT,
	@AuthorisationDate		DATE,
	@QuantityGallons		FLOAT,
	@Filename				VARCHAR(500) = NULL
)
AS

SET NOCOUNT ON

INSERT INTO dbo.SiteVRSAuthorisedBuyingOut
(EDISID, ProductID, AuthorisationDate, QuantityGallons, [Filename], ImportedOn, ImportedBy)
VALUES
(@EDISID, @ProductID, @AuthorisationDate, @QuantityGallons, @Filename, GETDATE(), SUSER_NAME())

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteVRSAuthorisedBuyingOut] TO PUBLIC
    AS [dbo];

