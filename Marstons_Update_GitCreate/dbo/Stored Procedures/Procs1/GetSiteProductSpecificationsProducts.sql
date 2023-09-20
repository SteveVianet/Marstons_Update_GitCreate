Create PROCEDURE [dbo].[GetSiteProductSpecificationsProducts] 
(
	@EDISID 	INT
)

AS

SELECT	
	SiteProductSpecifications.ProductID,
	Products.Description
FROM dbo.SiteProductSpecifications
JOIN dbo.Products ON Products.[ID] = SiteProductSpecifications.ProductID
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProductSpecificationsProducts] TO PUBLIC
    AS [dbo];

