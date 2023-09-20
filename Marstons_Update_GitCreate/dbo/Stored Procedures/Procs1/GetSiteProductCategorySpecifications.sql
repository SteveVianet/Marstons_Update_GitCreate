CREATE PROCEDURE [dbo].[GetSiteProductCategorySpecifications]
(
	@EDISID INT = NULL
)
AS

SELECT	EDISID,
		ProductCategoryID,
		p.Description,
		s.MinimumPouringYield,
		s.MaximumPouringYield,
		s.LowPouringYieldErrThreshold,
		s.HighPouringYieldErrThreshold		
			
FROM SiteProductCategorySpecifications as s
join ProductCategories as p on s.ProductCategoryID = p.ID
WHERE ((EDISID = @EDISID) OR (EDISID IS NULL))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProductCategorySpecifications] TO PUBLIC
    AS [dbo];

