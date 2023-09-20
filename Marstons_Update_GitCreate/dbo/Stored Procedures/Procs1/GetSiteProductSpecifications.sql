CREATE PROCEDURE [dbo].[GetSiteProductSpecifications] 
(
	@EDISID 	INT = NULL,
	@ProductID INT = NULL
)

AS

SELECT	SiteProductSpecifications.EDISID,
	SiteProductSpecifications.ProductID,
	SiteProductSpecifications.TempSpec,
	SiteProductSpecifications.TempTolerance,
	SiteProductSpecifications.FlowSpec,
	SiteProductSpecifications.FlowTolerance,
	SiteProductSpecifications.CleanDaysBeforeAmber,
	SiteProductSpecifications.CleanDaysBeforeRed
FROM dbo.SiteProductSpecifications
JOIN dbo.Products ON Products.[ID] = SiteProductSpecifications.ProductID
WHERE (EDISID = @EDISID OR @EDISID IS NULL)
AND (ProductID = @ProductID OR @ProductID IS NULL)
ORDER BY Products.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProductSpecifications] TO PUBLIC
    AS [dbo];

